import Carbon

/// Atalhos mostrados na janela e no item "Atalhos" do menu. Os de mídia controlam o app
/// escolhido (Spotify ou Música); as teclas de mídia do Mac (F7/F8/F9) continuam valendo
/// para o app que estiver tocando.
enum Shortcuts {
    static var list: [(keys: String, action: String)] {
        [
            ("⌘ ⌥ ↑", T("Aumenta o volume", "Volume up")),
            ("⌘ ⌥ ↓", T("Diminui o volume", "Volume down")),
            ("⌃ ⌥ P", T("Pausar / continuar", "Play / pause")),
            ("⌃ ⌥ →", T("Próxima música", "Next track")),
            ("⌃ ⌥ ←", T("Volta ao começo (2x rápido: música anterior)", "Back to start (twice quickly: previous track)")),
            ("⌃ ⌥ M", T("Mudo / volta o som", "Mute / unmute")),
            ("⌃ ⌥ A", T("Troca o app controlado (o próximo da lista)", "Switch the controlled app (next in the list)")),
            ("⌃ ⌥ V", T("Liga / desliga o microfone (o do Mac inteiro)", "Microphone on / off (for the whole Mac)")),
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
