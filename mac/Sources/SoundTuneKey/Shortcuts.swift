import Carbon

/// Atalhos mostrados na janela e no item "Atalhos" do menu. Os de mídia controlam o app
/// escolhido (Spotify ou Música); as teclas de mídia do Mac (F7/F8/F9) continuam valendo
/// para o app que estiver tocando.
enum Shortcuts {
    static var list: [(keys: String, action: String)] {
        [
            ("⌘ ⌥ ↑", T("Aumenta o volume", "Volume up", "Sube el volumen")),
            ("⌘ ⌥ ↓", T("Diminui o volume", "Volume down", "Baja el volumen")),
            ("⌃ ⌥ P", T("Pausar / continuar", "Play / pause", "Reproducir / pausar")),
            ("⌃ ⌥ →", T("Próxima música", "Next track", "Siguiente canción")),
            ("⌃ ⌥ ←", T("Volta ao começo (2x rápido: música anterior)", "Back to start (twice quickly: previous track)", "Volver al inicio (2 veces rápido: canción anterior)")),
            ("⌃ ⌥ M", T("Mudo / volta o som", "Mute / unmute", "Silenciar / activar sonido")),
            ("⌃ ⌥ A", T("Troca o app controlado (o próximo da lista)", "Switch the controlled app (next in the list)", "Cambia la app controlada (la siguiente de la lista)")),
            ("⌃ ⌥ V", T("Liga / desliga o microfone (o padrão do Mac)", "Microphone on / off (the Mac's default one)", "Micrófono activado / desactivado (el predeterminado del Mac)")),
        ]
    }

    /// Nome legível de um atalho, para o aviso de "outro programa já usa".
    static func name(of hotkey: GlobalHotkeys.Hotkey) -> String {
        let modifiers = hotkey.modifiers == GlobalHotkeys.Hotkey.controlOption ? "⌃⌥" : "⌘⌥"
        let key: String
        switch Int(hotkey.keyCode) {
        case kVK_UpArrow: key = "↑"
        case kVK_DownArrow: key = "↓"
        case kVK_LeftArrow: key = "←"
        case kVK_RightArrow: key = "→"
        case kVK_ANSI_P: key = "P"
        case kVK_ANSI_M: key = "M"
        case kVK_ANSI_A: key = "A"
        case kVK_ANSI_V: key = "V"
        default: key = "?"
        }
        return modifiers + key
    }
}
