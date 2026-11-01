import AppKit
import CoreAudio

/// Estado do app. O app escolhido fica aqui, não na tela: assim ele continua valendo
/// mesmo com a janela fechada (lição da versão Windows).
@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var apps: [AudioApp] = []
    @Published var selectedBundleID: String? {
        didSet {
            guard !demo else { return }
            defaults.set(selectedBundleID, forKey: Keys.lastApp)
            refreshMedia()
        }
    }
    /// Tempo da música do app escolhido; nil quando o app não informa (só Spotify e Música informam).
    @Published private(set) var mediaStatus: MediaPlayer.Status?
    @Published private(set) var volumes: [String: Float] = [:]
    /// Apps no mudo. O volume fica guardado: tirar o mudo volta ao mesmo volume (como no Windows).
    @Published private(set) var muted: Set<String> = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var startsAtLogin = LoginItem.isEnabled
    /// Aviso na tela ao usar os atalhos (interruptor da janela e item do menu, sempre iguais).
    @Published var showOsd: Bool { didSet { defaults.set(showOsd, forKey: Keys.showOsd) } }
    /// Mudo do microfone do Mac; nil quando não há microfone (o ícone e a linha do menu somem).
    @Published private(set) var micMuted: Bool?
    let updates = Updates()
    private let osd = Osd()

    /// O último app e os volumes ficam salvos, para os atalhos já valerem quando o Mac liga.
    private let defaults = UserDefaults.standard
    private enum Keys {
        static let lastApp = "lastApp"
        static let volumes = "volumes"
        static let muted = "muted"
        static let showOsd = "showOsd"
    }

    /// Uma captura por app com volume abaixo de 100% ou no mudo. Em 100% o app toca direto, sem captura.
    private var taps: [String: AppVolumeTap] = [:]
    /// Apps cuja captura falhou; só tenta de novo quando o volume deles mudar.
    private var failed: Set<String> = []
    private var timer: Timer?
    private var hotkeys: GlobalHotkeys?
    private var mediaTimer: Timer?
    /// Quem está mostrando o tempo da música (janela, menu); o tempo só é lido enquanto alguém mostra.
    private var mediaViewers: Set<String> = []
    private var lastPreviousPress = Date.distantPast
    /// Aviso de mídia na tela (permissão, opção do Chrome), para tirar quando voltar a funcionar.
    private var mediaErrorShown: String?
    /// Modo demonstração (vídeo do README): estado de mentira, sem ler o sistema nem mexer no som.
    private var demo = false

    init() {
        showOsd = defaults.object(forKey: Keys.showOsd) as? Bool ?? true
        selectedBundleID = defaults.string(forKey: Keys.lastApp)
        volumes = (defaults.dictionary(forKey: Keys.volumes) as? [String: Double] ?? [:]).mapValues { Float($0) }
        muted = Set(defaults.stringArray(forKey: Keys.muted) ?? [])
        refresh()
        // Reler a lista a cada segundo é mais simples que ouvir cada processo, e barato.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.taps.removeAll() }
        }
        registerHotkeys()
        refreshMic()
        updates.startAutomaticCheck()
    }

    private func registerHotkeys() {
        typealias Hotkey = GlobalHotkeys.Hotkey
        hotkeys = GlobalHotkeys([
            Hotkey(keyCode: Hotkey.upArrow, modifiers: Hotkey.commandOption, repeats: true) { [weak self] in self?.nudgeVolume(by: 0.01) },
            Hotkey(keyCode: Hotkey.downArrow, modifiers: Hotkey.commandOption, repeats: true) { [weak self] in self?.nudgeVolume(by: -0.01) },
            Hotkey(keyCode: Hotkey.mKey, modifiers: Hotkey.controlOption, repeats: false) { [weak self] in
                guard let self, let bundleID = selectedBundleID, selectedHasAudio else { return }
                toggleMute(bundleID)
                showVolumeOsd()
            },
            Hotkey(keyCode: Hotkey.aKey, modifiers: Hotkey.controlOption, repeats: false) { [weak self] in self?.switchApp() },
            Hotkey(keyCode: Hotkey.vKey, modifiers: Hotkey.controlOption, repeats: false) { [weak self] in
                guard let self else { return }
                toggleMic()
                if showOsd, let micMuted { osd.show(.mic(muted: micMuted)) }
            },
            // mídia com ⌃⌥ (as mesmas teclas do Ctrl+Alt do Windows): ⌘⌥←/→ troca de aba nos navegadores
            Hotkey(keyCode: Hotkey.pKey, modifiers: Hotkey.controlOption, repeats: false) { [weak self] in self?.mediaPlayPause() },
            Hotkey(keyCode: Hotkey.rightArrow, modifiers: Hotkey.controlOption, repeats: false) { [weak self] in self?.mediaNext() },
            Hotkey(keyCode: Hotkey.leftArrow, modifiers: Hotkey.controlOption, repeats: false) { [weak self] in self?.mediaPrevious() },
        ])
        if let failed = hotkeys?.failed, !failed.isEmpty {
            let names = failed.map { Shortcuts.name(of: $0) }.joined(separator: ", ")
            errorMessage = T("Outro programa já usa \(names); esse atalho não vai funcionar.",
                             "Another program already uses \(names); that shortcut won't work.")
        }
    }

    /// Atalhos de volume: ±1% no app escolhido, arredondando para o 1% mais perto.
    private func nudgeVolume(by step: Float) {
        guard let bundleID = selectedBundleID, selectedHasAudio else { return }
        let steps = ((volume(of: bundleID) + step) * 100).rounded()
        setVolume(steps / 100, for: bundleID)
        showVolumeOsd()
    }

    /// ⌃⌥A: o próximo app com som da lista (os tocando vêm primeiro); depois do último, volta ao primeiro.
    func switchApp() {
        refresh()
        let audible = apps.filter(\.hasAudio)
        guard !audible.isEmpty else { return }
        let index = audible.firstIndex { $0.bundleID == selectedBundleID }.map { ($0 + 1) % audible.count } ?? 0
        selectedBundleID = audible[index].bundleID
        showVolumeOsd()
    }

    private func showVolumeOsd() {
        guard showOsd, let app = selectedApp else { return }
        osd.show(.volume(app: app.displayName, volume: Int((volume(of: app.bundleID) * 100).rounded()),
                         muted: isMuted(app.bundleID)))
    }

    // MARK: - Microfone

    /// Relido ao abrir o menu e ao ativar a janela: o sistema ou o Discord podem mudá-lo.
    func refreshMic() {
        let value = Microphone.isMuted()
        if value != micMuted { micMuted = value }
    }

    func toggleMic() {
        refreshMic()
        guard let micMuted else { return }
        if !Microphone.setMuted(!micMuted) { errorMessage = T("Não foi possível mudar o microfone.", "Couldn't change the microphone.") }
        refreshMic()
    }

    var selectedApp: AudioApp? { apps.first { $0.bundleID == selectedBundleID } }
    /// App em cinza (ainda sem som): sem volume nem mudo; a mídia funciona.
    var selectedHasAudio: Bool { selectedApp?.hasAudio ?? false }

    func volume(of bundleID: String) -> Float { volumes[bundleID] ?? 1 }

    func isMuted(_ bundleID: String) -> Bool { muted.contains(bundleID) }

    /// O que de fato toca: 0 no mudo, senão o volume.
    private func gain(of bundleID: String) -> Float { isMuted(bundleID) ? 0 : volume(of: bundleID) }

    /// Mexer no volume tira o mudo, como no Windows.
    func setVolume(_ volume: Float, for bundleID: String) {
        volumes[bundleID] = min(max(volume, 0), 1)
        defaults.set(volumes.mapValues { Double($0) }, forKey: Keys.volumes)
        setMuted(false, for: bundleID)
    }

    func toggleMute(_ bundleID: String) { setMuted(!isMuted(bundleID), for: bundleID) }

    private func setMuted(_ mute: Bool, for bundleID: String) {
        if mute { muted.insert(bundleID) } else { muted.remove(bundleID) }
        defaults.set(Array(muted), forKey: Keys.muted)
        failed.remove(bundleID)
        if let tap = taps[bundleID], gain(of: bundleID) < 1 {
            tap.setVolume(gain(of: bundleID))
        } else {
            syncTaps()
        }
    }

    // MARK: - Mídia (botões ⏮ ⏯ ⏭ e barra de tempo)

    var mediaSupported: Bool { selectedBundleID.map(MediaPlayer.supports) ?? false }

    /// Um toque: volta para o começo da música. Dois toques em menos de 1 s: música anterior.
    func mediaPrevious() {
        let now = Date()
        let doublePress = now.timeIntervalSince(lastPreviousPress) < 1
        // depois de um toque duplo, o próximo toque começa a contagem de novo
        lastPreviousPress = doublePress ? .distantPast : now
        sendMedia(doublePress ? .previous : .restart)
    }

    func mediaPlayPause() { sendMedia(.playPause) }
    func mediaNext() { sendMedia(.next) }

    func seek(to seconds: Double) {
        guard let bundleID = selectedBundleID else { return }
        do {
            try MediaPlayer.seek(bundleID, to: seconds)
            // mostra o novo tempo na hora, sem esperar a próxima leitura
            if let status = mediaStatus {
                mediaStatus = .init(isPlaying: status.isPlaying, position: seconds, duration: status.duration)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sendMedia(_ command: MediaPlayer.Command) {
        guard let bundleID = selectedBundleID else { return }
        do {
            try MediaPlayer.send(command, to: bundleID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        refreshMedia()
    }

    /// O player não avisa quando a música anda: com a janela ou o menu aberto, o tempo é lido
    /// duas vezes por segundo (como no Windows).
    func setShowingMedia(_ showing: Bool, by viewer: String) {
        if showing { mediaViewers.insert(viewer) } else { mediaViewers.remove(viewer) }
        if mediaViewers.isEmpty {
            mediaTimer?.invalidate()
            mediaTimer = nil
        } else if mediaTimer == nil {
            refreshMedia()
            let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.refreshMedia() }
            }
            // .common: continua andando enquanto o menu da barra está aberto
            RunLoop.main.add(timer, forMode: .common)
            mediaTimer = timer
        }
    }

    private func refreshMedia() {
        guard let bundleID = selectedBundleID, MediaPlayer.supports(bundleID) else {
            if mediaStatus != nil { mediaStatus = nil }
            return
        }
        let status: MediaPlayer.Status?
        do {
            status = try MediaPlayer.status(of: bundleID)
            // só um tempo lido de verdade prova que o ajuste (permissão, opção do Chrome) foi
            // resolvido; "nada encontrado agora" não apaga o aviso, senão ele pisca
            if status != nil {
                if let shown = mediaErrorShown, errorMessage == shown { errorMessage = nil }
                mediaErrorShown = nil
            }
        } catch {
            status = nil
            if let error = error as? MediaError, error.needsUserAction {
                errorMessage = error.localizedDescription
                mediaErrorShown = errorMessage
            }
        }
        if status != mediaStatus { mediaStatus = status }
    }

    // MARK: - Iniciar com o Mac

    /// Relê do sistema: o usuário também pode desligar em Ajustes do Sistema.
    func refreshStartsAtLogin() {
        guard !demo else { return }
        startsAtLogin = LoginItem.isEnabled
    }

    func setStartsAtLogin(_ enabled: Bool) {
        do {
            try LoginItem.setEnabled(enabled)
            errorMessage = nil
        } catch {
            errorMessage = T("Não foi possível mudar o Iniciar com o Mac: ", "Couldn't change Start with Mac: ") + error.localizedDescription
        }
        if enabled && LoginItem.needsApproval {
            errorMessage = T("Libere o Sound Tune Key em Ajustes do Sistema → Geral → Itens de Início.",
                             "Allow Sound Tune Key in System Settings → General → Login Items.")
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
            if gain(of: bundleID) >= 1 || app == nil || app?.processes != tap.processes || tap.outputUID != outputUID {
                taps[bundleID] = nil
            }
        }

        guard let outputUID else { return }
        for app in apps where app.hasAudio && taps[app.bundleID] == nil && gain(of: app.bundleID) < 1 && !failed.contains(app.bundleID) {
            do {
                taps[app.bundleID] = try AppVolumeTap(processes: app.processes, outputUID: outputUID, volume: gain(of: app.bundleID))
                errorMessage = nil
            } catch {
                failed.insert(app.bundleID)
                errorMessage = "\(app.displayName): \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Modo demonstração (mac/Demo/make-video.swift)

    /// Só para gravar o vídeo do README: não lê o sistema, não registra atalhos e não mexe no som.
    init(demoApps: [AudioApp]) {
        showOsd = true
        demo = true
        apps = demoApps
    }

    /// Muda o estado mostrado na tela, sem tocar em nada de verdade.
    func setDemo(volumes: [String: Float], muted: Set<String>, media: MediaPlayer.Status?,
                 startsAtLogin: Bool, micMuted: Bool?) {
        precondition(demo, "só no modo demonstração")
        self.volumes = volumes
        self.muted = muted
        mediaStatus = media
        self.startsAtLogin = startsAtLogin
        self.micMuted = micMuted
    }

}
