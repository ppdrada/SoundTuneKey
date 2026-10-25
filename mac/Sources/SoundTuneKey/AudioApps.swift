import AppKit
import CoreAudio

/// Um app que tem pelo menos um processo de áudio no Core Audio.
struct AudioApp: Identifiable, Equatable {
    let bundleID: String
    let displayName: String
    let icon: NSImage?
    let isPlaying: Bool
    /// Processos de áudio do Core Audio que pertencem ao app (o principal e os auxiliares).
    let processes: [AudioObjectID]

    var id: String { bundleID }

    static func == (a: AudioApp, b: AudioApp) -> Bool {
        a.bundleID == b.bundleID && a.displayName == b.displayName && a.isPlaying == b.isPlaying
            && a.processes == b.processes
    }
}

enum AudioApps {
    /// Terminais aparecem por causa do bipe, mas não faz sentido controlá-los.
    private static let ignored: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "com.mitchellh.ghostty",
        "net.kovidgoyal.kitty",
        "org.alacritty",
        "com.github.wez.wezterm",
        "co.zeit.hyper",
    ]

    /// Lista os apps com processo de áudio. Processos auxiliares (ex.: "Google Chrome Helper")
    /// são juntados ao app principal, então cada app vira uma linha só.
    static func list() -> [AudioApp] {
        let regularApps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }

        var apps: [String: (app: NSRunningApplication, playing: Bool, processes: [AudioObjectID])] = [:]
        for object in processObjects() {
            guard let pid = processPID(object), let owner = owningApp(pid: pid, regularApps: regularApps),
                  let bundleID = owner.bundleIdentifier, owner.processIdentifier != getpid(),
                  !ignored.contains(bundleID) else { continue }

            let playing = isRunningOutput(object)
            apps[bundleID] = (owner, (apps[bundleID]?.playing ?? false) || playing,
                              (apps[bundleID]?.processes ?? []) + [object])
        }

        return apps.map { bundleID, entry in
            AudioApp(bundleID: bundleID,
                     displayName: entry.app.localizedName ?? bundleID,
                     icon: entry.app.icon,
                     isPlaying: entry.playing,
                     processes: entry.processes.sorted())
        }
        .sorted {
            if $0.isPlaying != $1.isPlaying { return $0.isPlaying }
            return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    // MARK: - App dono do processo

    /// Acha o app "de verdade" (com janela e ícone no Dock) dono de um processo de áudio:
    /// o próprio processo, um processo pai, ou um app cujo bundle ID é o começo do bundle ID do processo.
    private static func owningApp(pid: pid_t, regularApps: [NSRunningApplication]) -> NSRunningApplication? {
        var current = pid
        for _ in 0..<8 {
            if let app = regularApps.first(where: { $0.processIdentifier == current }) { return app }
            guard let parent = parentPID(of: current), parent > 1 else { break }
            current = parent
        }

        guard let helperID = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier else { return nil }
        return regularApps
            .filter { app in app.bundleIdentifier.map { helperID.hasPrefix($0 + ".") } ?? false }
            .max { ($0.bundleIdentifier?.count ?? 0) < ($1.bundleIdentifier?.count ?? 0) }
    }

    private static func parentPID(of pid: pid_t) -> pid_t? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return nil }
        return info.kp_eproc.e_ppid
    }

    // MARK: - Core Audio

    private static func processObjects() -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyProcessObjectList,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr, size > 0 else { return [] }

        var objects = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &objects) == noErr else { return [] }
        return objects
    }

    private static func processPID(_ object: AudioObjectID) -> pid_t? {
        var pid: pid_t = -1
        return read(object, kAudioProcessPropertyPID, into: &pid) ? pid : nil
    }

    private static func isRunningOutput(_ object: AudioObjectID) -> Bool {
        var running: UInt32 = 0
        return read(object, kAudioProcessPropertyIsRunningOutput, into: &running) && running != 0
    }

    private static func read<T: BitwiseCopyable>(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector, into value: inout T) -> Bool {
        var address = AudioObjectPropertyAddress(mSelector: selector,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var size = UInt32(MemoryLayout<T>.size)
        return AudioObjectGetPropertyData(object, &address, 0, nil, &size, &value) == noErr
    }
}
