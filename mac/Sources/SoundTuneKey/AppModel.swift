import AppKit
import CoreAudio

/// Estado do app. O app escolhido fica aqui, não na tela: assim ele continua valendo
/// mesmo com a janela fechada (lição da versão Windows).
@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var apps: [AudioApp] = []
    @Published var selectedBundleID: String? {
        didSet { defaults.set(selectedBundleID, forKey: Keys.lastApp) }
    }
    @Published private(set) var volumes: [String: Float] = [:]
    @Published private(set) var errorMessage: String?
    @Published private(set) var startsAtLogin = LoginItem.isEnabled

    /// O último app e os volumes ficam salvos, para os atalhos já valerem quando o Mac liga.
    private let defaults = UserDefaults.standard
    private enum Keys {
        static let lastApp = "lastApp"
        static let volumes = "volumes"
    }

    /// Uma captura por app com volume abaixo de 100%. Em 100% o app toca direto, sem captura.
    private var taps: [String: AppVolumeTap] = [:]
    /// Apps cuja captura falhou; só tenta de novo quando o volume deles mudar.
    private var failed: Set<String> = []
    private var timer: Timer?
    private var hotkeys: GlobalHotkeys?

    init() {
        selectedBundleID = defaults.string(forKey: Keys.lastApp)
        volumes = (defaults.dictionary(forKey: Keys.volumes) as? [String: Double] ?? [:]).mapValues { Float($0) }
        refresh()
        // Reler a lista a cada segundo é mais simples que ouvir cada processo, e barato.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.taps.removeAll() }
        }
        registerHotkeys()
    }

    private func registerHotkeys() {
        typealias Hotkey = GlobalHotkeys.Hotkey
        hotkeys = GlobalHotkeys([
            Hotkey(keyCode: Hotkey.upArrow, modifiers: Hotkey.commandOption, repeats: true) { [weak self] in self?.nudgeVolume(by: 0.05) },
            Hotkey(keyCode: Hotkey.downArrow, modifiers: Hotkey.commandOption, repeats: true) { [weak self] in self?.nudgeVolume(by: -0.05) },
        ])
        if hotkeys?.failed.isEmpty == false {
            errorMessage = "Outro programa já usa ⌘⌥↑ ou ⌘⌥↓; o atalho não vai funcionar."
        }
    }

    /// Atalhos de volume: ±5% no app escolhido, arredondando para múltiplos de 5%.
    private func nudgeVolume(by step: Float) {
        guard let bundleID = selectedBundleID else { return }
        let steps = ((volume(of: bundleID) + step) * 20).rounded()
        setVolume(steps / 20, for: bundleID)
    }

    var selectedApp: AudioApp? { apps.first { $0.bundleID == selectedBundleID } }

    func volume(of bundleID: String) -> Float { volumes[bundleID] ?? 1 }

    func setVolume(_ volume: Float, for bundleID: String) {
        let volume = min(max(volume, 0), 1)
        volumes[bundleID] = volume
        defaults.set(volumes.mapValues { Double($0) }, forKey: Keys.volumes)
        failed.remove(bundleID)
        if let tap = taps[bundleID], volume < 1 {
            tap.setVolume(volume)
        } else {
            syncTaps()
        }
    }

    // MARK: - Iniciar com o Mac

    /// Relê do sistema: o usuário também pode desligar em Ajustes do Sistema.
    func refreshStartsAtLogin() {
        startsAtLogin = LoginItem.isEnabled
    }

    func setStartsAtLogin(_ enabled: Bool) {
        do {
            try LoginItem.setEnabled(enabled)
            errorMessage = nil
        } catch {
            errorMessage = "Não foi possível mudar o Iniciar com o Mac: \(error.localizedDescription)"
        }
        if enabled && LoginItem.needsApproval {
            errorMessage = "Libere o Sound Tune Key em Ajustes do Sistema → Geral → Itens de Início."
            LoginItem.openSettings()
        }
        refreshStartsAtLogin()
    }

    func refresh() {
        let list = AudioApps.list()
        if list != apps { apps = list }
        syncTaps()
    }

    /// Cria, refaz ou remove as capturas para bater com os volumes, os processos de cada app
    /// e a saída de som atual (trocar para o fone, por exemplo, refaz a captura).
    private func syncTaps() {
        let outputUID = AudioOutput.defaultUID()

        for (bundleID, tap) in taps {
            let app = apps.first { $0.bundleID == bundleID }
            if volume(of: bundleID) >= 1 || app == nil || app?.processes != tap.processes || tap.outputUID != outputUID {
                taps[bundleID] = nil
            }
        }

        guard let outputUID else { return }
        for app in apps where taps[app.bundleID] == nil && volume(of: app.bundleID) < 1 && !failed.contains(app.bundleID) {
            do {
                taps[app.bundleID] = try AppVolumeTap(processes: app.processes, outputUID: outputUID, volume: volume(of: app.bundleID))
                errorMessage = nil
            } catch {
                failed.insert(app.bundleID)
                errorMessage = "\(app.displayName): \(error.localizedDescription)"
            }
        }
    }
}
