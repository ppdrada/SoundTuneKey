/// Atalhos mostrados na janela e no item "Atalhos" do menu. Pausar e trocar de música
/// ficam com as teclas de mídia do próprio teclado do Mac.
enum Shortcuts {
    static let list: [(keys: String, action: String)] = [
        ("⌘ ⌥ ↑", "Aumenta o volume"),
        ("⌘ ⌥ ↓", "Diminui o volume"),
        ("F8  ⏯", "Pausar / continuar"),
        ("F9  ⏭", "Próxima música"),
        ("F7  ⏮", "Música anterior"),
    ]
}
