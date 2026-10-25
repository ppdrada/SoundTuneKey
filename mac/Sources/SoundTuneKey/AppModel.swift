import Foundation

/// Estado do app. O app escolhido fica aqui, não na tela: assim ele continua valendo
/// mesmo com a janela fechada (lição da versão Windows).
@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var apps: [AudioApp] = []
    @Published var selectedBundleID: String?

    private var timer: Timer?

    init() {
        refresh()
        // Reler a lista a cada segundo é mais simples que ouvir cada processo, e barato.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        let list = AudioApps.list()
        if list != apps { apps = list }
    }
}
