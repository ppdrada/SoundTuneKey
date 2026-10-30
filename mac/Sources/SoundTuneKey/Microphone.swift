import CoreAudio

/// Mudo do microfone do Mac inteiro (⌃⌥V): o mudo do dispositivo de entrada padrão pelo
/// Core Audio, então vale para o Discord, o jogo e tudo mais (como no Windows).
enum Microphone {
    /// nil quando não há microfone, ou ele não tem controle de mudo.
    static func isMuted() -> Bool? {
        guard let (device, control) = muteControl() else { return nil }
        var address = control
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr else { return nil }
        return value != 0
    }

    @discardableResult
    static func setMuted(_ muted: Bool) -> Bool {
        guard let (device, control) = muteControl() else { return false }
        var address = control
        var value: UInt32 = muted ? 1 : 0
        return AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &value) == noErr
    }

    /// O mudo do microfone padrão: no canal principal ou, em alguns microfones USB, no canal 1.
    /// shortcut: microfone sem nenhum controle de mudo fica sem o atalho; se aparecer um, baixar o volume de entrada a 0.
    private static func muteControl() -> (AudioObjectID, AudioObjectPropertyAddress)? {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var device = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device) == noErr,
              device != kAudioObjectUnknown else { return nil }

        for element in [kAudioObjectPropertyElementMain, 1] {
            var mute = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyMute,
                                                  mScope: kAudioDevicePropertyScopeInput, mElement: element)
            var settable: DarwinBoolean = false
            if AudioObjectHasProperty(device, &mute), AudioObjectIsPropertySettable(device, &mute, &settable) == noErr, settable.boolValue {
                return (device, mute)
            }
        }
        return nil
    }
}
