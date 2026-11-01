import Foundation

/// Idioma do app: português, inglês ou espanhol, escolhido no Sobre e salvo. Na primeira vez
/// segue o sistema (português ou espanhol se ele estiver num deles; senão, inglês). As telas
/// observam `Lang.shared` e se redesenham na hora da troca; os itens comuns do menu da barra
/// trocam o título.
@MainActor
final class Lang: ObservableObject {
    enum Code: String, CaseIterable { case pt, en, es }

    static let shared = Lang()
    nonisolated private static let key = "language"

    @Published var code: Code {
        didSet {
            Self.current = code
            UserDefaults.standard.set(code.rawValue, forKey: Self.key)
        }
    }

    /// Cópia lida fora da thread principal (mensagens de erro); só muda na thread principal.
    nonisolated(unsafe) fileprivate static var current: Code = {
        if let saved = UserDefaults.standard.string(forKey: key).flatMap(Code.init) { return saved }
        let system = String((Locale.preferredLanguages.first ?? "").prefix(2))
        return Code(rawValue: system) ?? .en
    }()

    private init() { code = Self.current }
}

/// O texto no idioma escolhido, como o `Lang.T` do Windows.
func T(_ portuguese: String, _ english: String, _ spanish: String) -> String {
    switch Lang.current {
    case .pt: portuguese
    case .en: english
    case .es: spanish
    }
}
