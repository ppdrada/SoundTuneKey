import AppKit

/// Controles de mídia de um app específico. O macOS não tem API pública para isso (o
/// MediaRemote é privado), então fala direto, por AppleScript, com quem aceita: Spotify,
/// Música e VLC pelos comandos de player, e o Chrome executando JavaScript no vídeo da aba (veja
/// `ChromeMedia`). Na primeira vez o macOS pergunta se o Sound Tune Key pode controlá-los.
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
        /// O Spotify informa a duração em milissegundos; o Música e o VLC, em segundos.
        var durationScale: Double = 1
        /// Devolve {estado, posição, duração}, com o estado "stopped" quando não há nada tocando.
        var statusScript = """
            if player state is stopped then return {"stopped", 0, 0}
            return {player state as string, player position, duration of current track}
            """
        var playPause = "playpause"
        var next = "next track"
        var previous = "previous track"
        var position = "player position"
    }

    private static let players = [
        Player(bundleID: "com.spotify.client", durationScale: 1000),
        Player(bundleID: "com.apple.Music"),
        // o VLC tem outros nomes: "play" alterna, "current time" é a posição, e a duração dá
        // erro (ou -1) sem vídeo aberto
        Player(bundleID: "org.videolan.vlc",
               statusScript: """
                   try
                       set d to duration of current item
                   on error
                       return {"stopped", 0, 0}
                   end try
                   if d ≤ 0 then return {"stopped", 0, 0}
                   if playing then return {"playing", current time, d}
                   return {"paused", current time, d}
                   """,
               playPause: "play", next: "next", previous: "previous", position: "current time"),
    ]

    static func supports(_ bundleID: String) -> Bool {
        players.contains { $0.bundleID == bundleID } || bundleID == ChromeMedia.bundleID
    }

    /// Tempo da música atual, ou nil se o app não é suportado, está fechado ou sem música.
    static func status(of bundleID: String) throws -> Status? {
        if bundleID == ChromeMedia.bundleID { return isRunning(bundleID) ? try ChromeMedia.status() : nil }
        guard let player = player(bundleID) else { return nil }
        let result = try run("tell application id \"\(bundleID)\"\n\(player.statusScript)\nend tell")
        guard result.numberOfItems == 3, let state = result.atIndex(1)?.stringValue, state != "stopped",
              let position = result.atIndex(2)?.doubleValue, let duration = result.atIndex(3)?.doubleValue
        else { return nil }
        return Status(isPlaying: state == "playing", position: position, duration: duration / player.durationScale)
    }

    static func send(_ command: Command, to bundleID: String) throws {
        if bundleID == ChromeMedia.bundleID {
            if isRunning(bundleID) { try ChromeMedia.send(command) }
            return
        }
        guard let player = player(bundleID) else { return }
        let action = switch command {
        case .playPause: player.playPause
        case .next: player.next
        case .previous: player.previous
        case .restart: "set \(player.position) to 0"
        }
        try run("tell application id \"\(bundleID)\" to \(action)")
    }

    static func seek(_ bundleID: String, to seconds: Double) throws {
        if bundleID == ChromeMedia.bundleID {
            if isRunning(bundleID) { try ChromeMedia.seek(to: seconds) }
            return
        }
        guard let player = player(bundleID) else { return }
        try run("tell application id \"\(bundleID)\" to set \(player.position) to \(Int(seconds.rounded()))")
    }

    /// Só fala com o app se ele já estiver aberto: o AppleScript abriria o app.
    private static func isRunning(_ bundleID: String) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    private static func player(_ bundleID: String) -> Player? {
        guard let player = players.first(where: { $0.bundleID == bundleID }), isRunning(bundleID) else { return nil }
        return player
    }

    // Os scripts são compilados uma vez só: o tempo é lido duas vezes por segundo.
    private static var compiled: [String: NSAppleScript] = [:]

    @discardableResult
    static func run(_ source: String) throws -> NSAppleEventDescriptor {
        let script = compiled[source] ?? {
            let script = NSAppleScript(source: source)!
            compiled[source] = script
            return script
        }()
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            throw MediaError(code: error[NSAppleScript.errorNumber] as? Int ?? 0,
                             message: error[NSAppleScript.errorMessage] as? String ?? "")
        }
        return result
    }
}

struct MediaError: LocalizedError {
    let code: Int
    var message = ""

    /// Erros que o usuário resolve num ajuste: vale mostrar mesmo sem ele ter clicado em nada.
    var needsUserAction: Bool { code == -1743 || isChromeJavaScriptOff }

    /// O Chrome recusa JavaScript vindo do AppleScript até o usuário ligar a opção.
    var isChromeJavaScriptOff: Bool { message.contains("JavaScript") }

    // nomes exatos do menu do Chrome em cada idioma
    static var chromeJavaScriptOffMessage: String {
        T("No Chrome, na barra de menus do Mac: Ver → Desenvolvedor → Permitir o JavaScript do Eventos da Apple.",
          "In Chrome, on the Mac menu bar: View → Developer → Allow JavaScript from Apple Events.")
    }

    var errorDescription: String? {
        if isChromeJavaScriptOff { return Self.chromeJavaScriptOffMessage }
        // -1743: o usuário não deixou (ou ainda não respondeu) o controle do app
        return code == -1743
            ? T("Libere o controle em Ajustes do Sistema → Privacidade e Segurança → Automação.",
                "Allow control in System Settings → Privacy & Security → Automation.")
            : T("O player não respondeu (erro \(code)).", "The player didn't respond (error \(code)).")
    }
}
