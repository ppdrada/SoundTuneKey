import Carbon

/// Atalhos mostrados na janela e no item "Atalhos" do menu. Os de mídia controlam o app
/// escolhido (Spotify ou Música); as teclas de mídia do Mac (F7/F8/F9) continuam valendo
/// para o app que estiver tocando.
enum Shortcuts {
    static let list: [(keys: String, action: String)] = [
        ("⌘ ⌥ ↑", "Aumenta o volume"),
        ("⌘ ⌥ ↓", "Diminui o volume"),
        ("⌃ ⌥ M", "Mudo / volta o som"),
        ("⌃ ⌥ P", "Pausar / continuar"),
        ("⌃ ⌥ →", "Próxima música"),
        ("⌃ ⌥ ←", "Volta ao começo (2x rápido: anterior)"),
    ]

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
        default: key = "?"
        }
        return modifiers + key
    }
}
