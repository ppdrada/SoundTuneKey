import AppKit

/// Mídia do Chrome: o Chrome não tem comandos de player no AppleScript, mas executa JavaScript
/// nas abas (com "Permitir JavaScript de Eventos da Apple" ligado em Visualizar → Desenvolvedor).
/// O Sound Tune Key procura a aba com vídeo ou áudio (de preferência tocando) e controla o
/// elemento <video>/<audio> dela. Vídeos dentro de iframes de outro site não aparecem.
@MainActor
enum ChromeMedia {
    static let bundleID = "com.google.Chrome"

    /// A aba encontrada: as próximas leituras vão direto nela, sem passar por todas as abas.
    private static var tab: (window: Int, tab: Int)?
    private static var lastSearch = Date.distantPast

    // Escolhe o vídeo/áudio da página: o que está tocando, senão o primeiro com duração.
    // Só aspas simples no JavaScript, porque ele vai dentro de uma string do AppleScript.
    private static let pick = "var a=Array.from(document.querySelectorAll('video,audio')).filter(function(e){return e.duration>0});var m=a.find(function(e){return !e.paused})||a[0];"
    private static let readJS = "(function(){\(pick)if(!m)return '';return (m.paused?'0':'1')+'|'+m.currentTime+'|'+m.duration})()"

    static func status() throws -> MediaPlayer.Status? {
        if let tab, let status = try? read(tab) {
            // pausado: de vez em quando procura se outra aba começou a tocar
            if status.isPlaying || Date().timeIntervalSince(lastSearch) < 2 { return status }
        }
        // procurar passa por todas as abas: no máximo a cada 2 s
        guard Date().timeIntervalSince(lastSearch) >= 2 else { return nil }
        lastSearch = Date()
        tab = try search()
        return try tab.flatMap { try read($0) }
    }

    static func send(_ command: MediaPlayer.Command) throws {
        let action = switch command {
        case .playPause: "if(m.paused){m.play()}else{m.pause()}"
        case .restart: "m.currentTime=0"
        // no YouTube, os botões do player trocam de vídeo; em outros sites não há próximo
        case .next: "var b=document.querySelector('.ytp-next-button');if(b){b.click()}"
        case .previous: "var b=document.querySelector('.ytp-prev-button');if(b&&b.offsetParent){b.click()}else{m.currentTime=0}"
        }
        try execute(action)
    }

    static func seek(to seconds: Double) throws {
        try execute("m.currentTime=\(Int(seconds.rounded()))")
    }

    private static func execute(_ action: String) throws {
        if tab == nil {
            lastSearch = Date()
            tab = try search()
        }
        guard let tab else { return }
        let js = "(function(){\(pick)if(!m)return '';\(action);return 'ok'})()"
        try MediaPlayer.run(script(js, in: tab))
    }

    private static func read(_ tab: (window: Int, tab: Int)) throws -> MediaPlayer.Status? {
        let result = try MediaPlayer.run(script(readJS, in: tab)).stringValue ?? ""
        return parse(result)
    }

    /// Passa pelas abas e devolve a primeira que está tocando, senão a primeira com mídia.
    private static func search() throws -> (window: Int, tab: Int)? {
        let result = try MediaPlayer.run("""
            tell application id "\(bundleID)"
                set best to {}
                set failure to missing value
                repeat with w in windows
                    repeat with t in tabs of w
                        -- uma aba com erro (ex.: perfil com a opção desligada) não para a busca
                        try
                            set r to execute t javascript "\(readJS)"
                            if r is not missing value and r is not "" then
                                if r starts with "1" then return {id of w, id of t}
                                if best is {} then set best to {id of w, id of t}
                            end if
                        on error message number code
                            set failure to {message, code}
                        end try
                    end repeat
                end repeat
                -- nada encontrado e alguma aba recusou: mostra o motivo (a opção desligada)
                if best is {} and failure is not missing value then error (item 1 of failure) number (item 2 of failure)
                return best
            end tell
            """)
        guard result.numberOfItems == 2, let window = result.atIndex(1)?.int32Value, let tab = result.atIndex(2)?.int32Value
        else { return nil }
        return (Int(window), Int(tab))
    }

    private static func script(_ js: String, in tab: (window: Int, tab: Int)) -> String {
        "tell application id \"\(bundleID)\" to execute tab id \(tab.tab) of window id \(tab.window) javascript \"\(js)\""
    }

    /// "1|83.2|225" → tocando, posição, duração. Transmissão ao vivo (duração infinita) não tem tempo.
    private static func parse(_ text: String) -> MediaPlayer.Status? {
        let parts = text.split(separator: "|")
        guard parts.count == 3, let position = Double(parts[1]), let duration = Double(parts[2]), duration.isFinite
        else { return nil }
        return MediaPlayer.Status(isPlaying: parts[0] == "1", position: position, duration: duration)
    }

    /// O botão "Como ligar": o Chrome não deixa um app ligar a opção nem pedir, como o macOS
    /// pede as permissões dele. Então mostra os passos e traz o Chrome para a frente, para o
    /// menu "Ver" dele já aparecer na barra de menus. O aviso some sozinho quando passa a funcionar.
    static func showSetup() {
        let alert = NSAlert()
        alert.messageText = T("Controlar vídeos do Chrome", "Control Chrome videos", "Controlar videos de Chrome")
        alert.informativeText = T("""
            O Chrome só deixa o Sound Tune Key ver o tempo, pausar e pular vídeos com esta opção ligada:

            1. Com o Chrome na frente, clique em Ver, na barra de menus lá em cima.
            2. Vá em Desenvolvedor.
            3. Clique em Permitir o JavaScript do Eventos da Apple.

            Se você usa mais de um perfil no Chrome, ligue em cada um. O volume funciona mesmo sem isso.
            """, """
            Chrome only lets Sound Tune Key see the time, pause and skip videos with this option on:

            1. With Chrome in front, click View on the menu bar at the top.
            2. Go to Developer.
            3. Click Allow JavaScript from Apple Events.

            If you use more than one Chrome profile, turn it on in each one. The volume works even without it.
            """, """
            Chrome solo deja que Sound Tune Key vea el tiempo, pause y salte videos con esta opción activada:

            1. Con Chrome al frente, haz clic en Ver, en la barra de menús de arriba.
            2. Ve a Desarrollador.
            3. Haz clic en Permitir JavaScript de Apple Events.

            Si usas más de un perfil en Chrome, actívala en cada uno. El volumen funciona incluso sin esto.
            """)
        alert.icon = NSApp.applicationIconImage
        alert.addButton(withTitle: T("Abrir o Chrome", "Open Chrome", "Abrir Chrome"))
        alert.addButton(withTitle: T("Cancelar", "Cancel", "Cancelar"))
        NSApp.activate()
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first?.activate()
    }
}
