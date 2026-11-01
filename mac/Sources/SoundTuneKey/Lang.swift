import Foundation

/// Idioma do app: português ou inglês, escolhido no Sobre e salvo. Na primeira vez segue o
/// sistema (português se ele estiver em português). As telas observam `Lang.shared` e se
/// redesenham na hora da troca; os itens comuns do menu da barra trocam o título.
@MainActor
final class Lang: ObservableObject {
    static let shared = Lang()
    nonisolated private static let key = "language"

    @Published var english: Bool {
        didSet {
            Self.isEnglish = english
            UserDefaults.standard.set(english ? "en" : "pt", forKey: Self.key)
        }
    }

    /// Cópia lida fora da thread principal (mensagens de erro); só muda na thread principal.
    nonisolated(unsafe) fileprivate static var isEnglish: Bool = {
        let saved = UserDefaults.standard.string(forKey: key)
        return saved.map { $0 == "en" } ?? !(Locale.preferredLanguages.first ?? "").hasPrefix("pt")
    }()

    private init() { english = Self.isEnglish }
}

/// O texto no idioma escolhido, como o `Lang.T` do Windows.
func T(_ portuguese: String, _ english: String) -> String { Lang.isEnglish ? english : portuguese }
