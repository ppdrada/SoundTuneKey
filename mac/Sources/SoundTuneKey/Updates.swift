import AppKit
import UserNotifications

/// Versão do app e a versão mais nova publicada no GitHub (download/version-mac.txt), como no
/// Windows. Procura 15 s depois de abrir e uma vez por dia; avisa uma vez por versão.
@MainActor
final class Updates: ObservableObject {
    nonisolated static let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    static let repoURL = URL(string: "https://github.com/ppdrada/SoundTuneKey")!
    static let downloadURL = URL(string: "https://github.com/ppdrada/SoundTuneKey/raw/main/download/SoundTuneKey-mac.zip")!
    private static let versionURL = URL(string: "https://raw.githubusercontent.com/ppdrada/SoundTuneKey/main/download/version-mac.txt")!
    private static let notifiedKey = "notifiedVersion"

    /// Versão nova encontrada (item do menu e faixa na janela); nil quando não há.
    @Published private(set) var available: String?
    private var timer: Timer?

    enum CheckResult {
        case newer(String), upToDate, missing, offline, unexpected

        var message: String {
            switch self {
            case let .newer(version): T("Versão \(version) disponível! Você está na \(Updates.current).",
                                        "Version \(version) available! You have \(Updates.current).", "¡Versión \(version) disponible! Tienes la \(Updates.current).")
            case .upToDate: T("Você já tem a versão mais nova (\(Updates.current)).",
                              "You already have the latest version (\(Updates.current)).", "Ya tienes la versión más reciente (\(Updates.current)).")
            case .missing: T("O GitHub ainda não informa a versão nova. Tente de novo mais tarde.",
                             "GitHub doesn't list the new version yet. Try again later.", "GitHub todavía no muestra la nueva versión. Inténtalo más tarde.")
            case .offline: T("Não deu para falar com o GitHub. Confira a internet e tente de novo.",
                             "Couldn't reach GitHub. Check the internet and try again.", "No se pudo conectar con GitHub. Revisa internet e inténtalo de nuevo.")
            case .unexpected: T("O GitHub respondeu algo inesperado. Tente de novo mais tarde.",
                                "GitHub sent an unexpected answer. Try again later.", "GitHub respondió algo inesperado. Inténtalo más tarde.")
            }
        }
    }

    func startAutomaticCheck() {
        Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
            Task { @MainActor in await self?.automaticCheck() }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.automaticCheck() }
        }
    }

    private func automaticCheck() async {
        guard case let .newer(version) = await check(),
              UserDefaults.standard.string(forKey: Self.notifiedKey) != version else { return }
        UserDefaults.standard.set(version, forKey: Self.notifiedKey)
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert])) == true else { return }
        let content = UNMutableNotificationContent()
        content.title = "Sound Tune Key"
        content.body = T("Versão \(version) disponível. Clique aqui para atualizar.",
                         "Version \(version) available. Click here to update.", "Versión \(version) disponible. Haz clic aquí para actualizar.")
        try? await center.add(UNNotificationRequest(identifier: "update", content: content, trigger: nil))
    }

    func check() async -> CheckResult {
        var request = URLRequest(url: Self.versionURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let status = (response as? HTTPURLResponse)?.statusCode else { return .offline }
        if status == 404 { return .missing }
        guard status == 200, let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              Self.parse(text) != nil else { return .unexpected }
        guard Self.isNewer(text, than: Self.current) else {
            available = nil
            return .upToDate
        }
        available = text
        return .newer(text)
    }

    static func parse(_ version: String) -> [Int]? {
        let parts = version.split(separator: ".").map { Int($0) }
        return parts.isEmpty || parts.contains(nil) ? nil : parts.compactMap { $0 }
    }

    static func isNewer(_ a: String, than b: String) -> Bool {
        guard let x = parse(a), let y = parse(b) else { return false }
        for i in 0..<max(x.count, y.count) {
            let (p, q) = (i < x.count ? x[i] : 0, i < y.count ? y[i] : 0)
            if p != q { return p > q }
        }
        return false
    }

    // MARK: - Atualizar agora

    /// Baixa o .zip, descompacta ao lado, confere que é o Sound Tune Key, troca o .app e reabre.
    func install(progress: @escaping @MainActor (Int) -> Void, opening: @MainActor () -> Void) async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("SoundTuneKey-update-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let zip = folder.appendingPathComponent("SoundTuneKey-mac.zip")

        let (bytes, response) = try await URLSession.shared.bytes(from: Self.downloadURL)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw UpdateError() }
        let total = response.expectedContentLength
        var data = Data()
        if total > 0 { data.reserveCapacity(Int(total)) }
        var lastPercent = -1
        for try await byte in bytes {
            data.append(byte)
            if total > 0 {
                let percent = Int(Int64(data.count) * 100 / total)
                if percent != lastPercent { lastPercent = percent; progress(percent) }
            }
        }
        try data.write(to: zip)

        try run("/usr/bin/ditto", ["-x", "-k", zip.path, folder.path])
        let newApp = folder.appendingPathComponent("SoundTuneKey.app")
        // o programa de verdade: mesmo identificador e o executável dentro
        guard let bundle = Bundle(url: newApp), bundle.bundleIdentifier == Bundle.main.bundleIdentifier,
              let executable = bundle.executableURL, FileManager.default.isExecutableFile(atPath: executable.path) else {
            throw UpdateError()
        }
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

        let current = Bundle.main.bundleURL
        _ = try FileManager.default.replaceItemAt(current, withItemAt: newApp)
        opening()

        // reabre o app novo depois que este fechar; ele mostra "Atualizado para a versão X"
        let script = "while kill -0 \(getpid()) 2>/dev/null; do sleep 0.2; done; open -n \"$0\" --args --after-update \"$1\""
        let relaunch = Process()
        relaunch.executableURL = URL(fileURLWithPath: "/bin/sh")
        relaunch.arguments = ["-c", script, current.path, version]
        try relaunch.run()
        NSApp.terminate(nil)
    }

    /// Versão que acabou de ser instalada, se o app foi aberto pela atualização.
    static var justUpdatedTo: String? {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: "--after-update"), index + 1 < args.count else { return nil }
        return args[index + 1]
    }

    private func run(_ tool: String, _ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw UpdateError() }
    }

    struct UpdateError: LocalizedError {
        var errorDescription: String? {
            T("Não deu para atualizar sozinho. Clique em Baixar para pegar pelo navegador.",
              "Couldn't update by itself. Click Download to get it in the browser.", "No se pudo actualizar solo. Haz clic en Descargar para bajarla en el navegador.")
        }
    }
}
