import AppKit

/// Controles de mídia de um app específico. O macOS não tem API pública para isso (o
/// MediaRemote é privado), então fala direto, por AppleScript, com os players que aceitam:
/// Spotify e Música. Na primeira vez o macOS pergunta se o Sound Tune Key pode controlá-los.
@MainActor
enum MediaPlayer {
    enum Command { case playPause, next, previous, restart }

    struct Status: Equatable {
        let isPlaying: Bool
        /// Segundos.
        let position: Double
        let duration: Double
    }

    private struct Player {
        let bundleID: String
        /// O Spotify informa a duração em milissegundos; o Música, em segundos.
        let durationScale: Double
    }

    private static let players = [
        Player(bundleID: "com.spotify.client", durationScale: 1000),
        Player(bundleID: "com.apple.Music", durationScale: 1),
    ]

    static func supports(_ bundleID: String) -> Bool {
        players.contains { $0.bundleID == bundleID }
    }

    /// Tempo da música atual, ou nil se o app não é suportado, está fechado ou sem música.
    static func status(of bundleID: String) throws -> Status? {
        guard let player = player(bundleID) else { return nil }
        let result = try run("""
            tell application id "\(bundleID)"
                if player state is stopped then return {"stopped", 0, 0}
                return {player state as string, player position, duration of current track}
            end tell
            """)
        guard result.numberOfItems == 3, let state = result.atIndex(1)?.stringValue, state != "stopped",
              let position = result.atIndex(2)?.doubleValue, let duration = result.atIndex(3)?.doubleValue
        else { return nil }
        return Status(isPlaying: state == "playing", position: position, duration: duration / player.durationScale)
    }

    static func send(_ command: Command, to bundleID: String) throws {
        guard player(bundleID) != nil else { return }
        let action = switch command {
        case .playPause: "playpause"
        case .next: "next track"
        case .previous: "previous track"
        case .restart: "set player position to 0"
        }
        try run("tell application id \"\(bundleID)\" to \(action)")
    }

    static func seek(_ bundleID: String, to seconds: Double) throws {
        guard player(bundleID) != nil else { return }
        try run("tell application id \"\(bundleID)\" to set player position to \(Int(seconds.rounded()))")
    }

    /// Só fala com o player se ele já estiver aberto: o AppleScript abriria o app.
    private static func player(_ bundleID: String) -> Player? {
        guard let player = players.first(where: { $0.bundleID == bundleID }),
              !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty else { return nil }
        return player
    }

    // Os scripts são compilados uma vez só: o tempo é lido duas vezes por segundo.
    private static var compiled: [String: NSAppleScript] = [:]

    @discardableResult
    private static func run(_ source: String) throws -> NSAppleEventDescriptor {
        let script = compiled[source] ?? {
            let script = NSAppleScript(source: source)!
            compiled[source] = script
            return script
        }()
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            throw MediaError(code: error[NSAppleScript.errorNumber] as? Int ?? 0)
        }
        return result
    }
}

struct MediaError: LocalizedError {
    let code: Int

    var errorDescription: String? {
        // -1743: o usuário não deixou (ou ainda não respondeu) o controle do app
        code == -1743
            ? "Libere o controle em Ajustes do Sistema → Privacidade e Segurança → Automação."
            : "O player não respondeu (erro \(code))."
    }
}
