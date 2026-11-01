import CoreAudio
import Foundation

/// Muda o volume de um app sem mexer no volume do Mac.
///
/// O macOS não tem volume por app. Então o som dos processos do app é capturado na origem
/// (um "process tap", que silencia o app enquanto existe), multiplicado pelo volume e tocado
/// na saída padrão por um dispositivo agregado privado, visível só para o Sound Tune Key.
/// Se o Sound Tune Key fechar, o macOS desfaz tudo e o app volta a tocar normalmente.
final class AppVolumeTap {
    let processes: [AudioObjectID]
    let outputUID: String

    /// Lido na thread de áudio; Float de 32 bits é escrito e lido de uma vez só.
    private var gain: Float
    private var tapID = AudioObjectID(kAudioObjectUnknown)
    private var aggregateID = AudioObjectID(kAudioObjectUnknown)
    private var ioProcID: AudioDeviceIOProcID?

    init(processes: [AudioObjectID], outputUID: String, volume: Float) throws {
        self.processes = processes
        self.outputUID = outputUID
        self.gain = volume
        do {
            try start()
        } catch {
            stop()
            throw error
        }
    }

    deinit { stop() }

    func setVolume(_ volume: Float) { gain = volume }

    private func start() throws {
        let description = CATapDescription(stereoMixdownOfProcesses: processes)
        description.uuid = UUID()
        description.name = "Sound Tune Key"
        description.isPrivate = true
        description.muteBehavior = .mutedWhenTapped
        try check(AudioHardwareCreateProcessTap(description, &tapID), T("criar a captura", "create the capture", "crear la captura"))

        let aggregate: [String: Any] = [
            kAudioAggregateDeviceNameKey: "Sound Tune Key",
            kAudioAggregateDeviceUIDKey: UUID().uuidString,
            kAudioAggregateDeviceMainSubDeviceKey: outputUID,
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceIsStackedKey: false,
            kAudioAggregateDeviceSubDeviceListKey: [[kAudioSubDeviceUIDKey: outputUID]],
            kAudioAggregateDeviceTapListKey: [[
                kAudioSubTapUIDKey: description.uuid.uuidString,
                kAudioSubTapDriftCompensationKey: true,
            ]],
        ]
        try check(AudioHardwareCreateAggregateDevice(aggregate as CFDictionary, &aggregateID), T("criar o dispositivo", "create the device", "crear el dispositivo"))

        try check(AudioDeviceCreateIOProcIDWithBlock(&ioProcID, aggregateID, nil) { [unowned self] _, input, _, output, _ in
            Self.copy(input, to: output, gain: self.gain)
        }, T("criar o processamento", "create the processing", "crear el procesamiento"))
        try check(AudioDeviceStart(aggregateID, ioProcID), T("começar a tocar", "start playing", "empezar a reproducir"))
    }

    func stop() {
        if aggregateID != kAudioObjectUnknown {
            if let ioProcID {
                AudioDeviceStop(aggregateID, ioProcID)
                AudioDeviceDestroyIOProcID(aggregateID, ioProcID)
            }
            AudioHardwareDestroyAggregateDevice(aggregateID)
        }
        if tapID != kAudioObjectUnknown {
            AudioHardwareDestroyProcessTap(tapID)
        }
        ioProcID = nil
        aggregateID = AudioObjectID(kAudioObjectUnknown)
        tapID = AudioObjectID(kAudioObjectUnknown)
    }

    /// Copia o som capturado (Float32) para a saída, multiplicado pelo volume. Se a saída tiver
    /// mais canais que a captura (estéreo), os canais da captura se repetem.
    private static func copy(_ input: UnsafePointer<AudioBufferList>, to output: UnsafeMutablePointer<AudioBufferList>, gain: Float) {
        let inBuffers = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input))
        let outBuffers = UnsafeMutableAudioBufferListPointer(output)

        let inChannels = inBuffers.map { Int($0.mNumberChannels) }.reduce(0, +)
        guard inChannels > 0 else {
            for buffer in outBuffers { if let data = buffer.mData { memset(data, 0, Int(buffer.mDataByteSize)) } }
            return
        }

        // Canal n (contando todos os buffers) -> (buffer, posição dentro do quadro, canais no buffer).
        func locate(_ buffers: UnsafeMutableAudioBufferListPointer, _ channel: Int) -> (UnsafeMutablePointer<Float>?, Int, Int, Int) {
            var c = channel
            for buffer in buffers {
                let n = Int(buffer.mNumberChannels)
                if c < n {
                    let frames = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size / max(n, 1)
                    return (buffer.mData?.assumingMemoryBound(to: Float.self), c, n, frames)
                }
                c -= n
            }
            return (nil, 0, 1, 0)
        }

        let outChannels = outBuffers.map { Int($0.mNumberChannels) }.reduce(0, +)
        for channel in 0..<outChannels {
            let (dst, dstOffset, dstStride, dstFrames) = locate(outBuffers, channel)
            let (src, srcOffset, srcStride, srcFrames) = locate(inBuffers, channel % inChannels)
            guard let dst else { continue }
            let frames = min(dstFrames, srcFrames)
            for frame in 0..<dstFrames {
                dst[frame * dstStride + dstOffset] = frame < frames ? (src?[frame * srcStride + srcOffset] ?? 0) * gain : 0
            }
        }
    }
}

struct AudioError: LocalizedError {
    let step: String
    let status: OSStatus
    var errorDescription: String? { T("Não foi possível \(step) (erro \(status)).", "Couldn't \(step) (error \(status)).", "No se pudo \(step) (error \(status)).") }
}

private func check(_ status: OSStatus, _ step: String) throws {
    if status != noErr { throw AudioError(step: step, status: status) }
}

enum AudioOutput {
    /// UID da saída de som padrão (alto-falantes, fone...), ou nil se não houver.
    static func defaultUID() -> String? {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var device = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device) == noErr,
              device != kAudioObjectUnknown else { return nil }

        address.mSelector = kAudioDevicePropertyDeviceUID
        var uid: Unmanaged<CFString>?
        size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &uid) == noErr, let uid else { return nil }
        return uid.takeRetainedValue() as String
    }
}
