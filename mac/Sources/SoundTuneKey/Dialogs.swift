import AppKit
import SwiftUI

/// "Sobre": logo, versão, autor, link do GitHub e a verificação de versão nova, que também
/// atualiza o app (é a janela que o item do menu, a faixa e a notificação abrem).
struct AboutView: View {
    @ObservedObject var updates: Updates
    let checkOnOpen: Bool
    let close: () -> Void

    @ObservedObject private var lang = Lang.shared
    @State private var message: String?
    @State private var newer = false
    @State private var failed = false
    @State private var busy = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)
                .frame(height: 140)
            Text("Sound Tune Key").font(.system(size: 13, weight: .bold)).frame(height: 34)
            Text(T("Versão ", "Version ", "Versión ") + Updates.current).font(.system(size: 12)).frame(height: 24)
            Text(T("Desenvolvido por ppdrada", "Made by ppdrada", "Hecho por ppdrada")).font(.system(size: 12)).foregroundStyle(Theme.mutedText).frame(height: 24)
            LinkText(title: "github.com/ppdrada/SoundTuneKey") { NSWorkspace.shared.open(Updates.repoURL) }
                .frame(height: 30)
            // idioma do app inteiro: o escolhido em branco, o outro em cinza
            HStack(spacing: 6) {
                ForEach(Array(zip(Lang.Code.allCases, ["Português", "English", "Español"])), id: \.0) { code, name in
                    if code != .pt { Text("·").font(.system(size: 12)).foregroundStyle(Theme.mutedText) }
                    LinkText(title: name, color: lang.code == code ? Theme.text : Theme.mutedText) { lang.code = code }
                }
            }
            .frame(height: 30)
            Text(message ?? "")
                .font(.system(size: 12))
                .foregroundStyle(Theme.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .frame(height: 54)
            HStack(spacing: 10) {
                Spacer()
                DarkButton(title: failed ? T("Baixar", "Download", "Descargar") : newer ? T("Atualizar agora", "Update now", "Actualizar ahora")
                           : T("Verificar atualizações", "Check for updates", "Buscar actualizaciones"), width: 150,
                           primary: newer || failed) { mainAction() }
                    .disabled(busy)
                DarkButton(title: T("Fechar", "Close", "Cerrar"), width: 100, action: close)
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.trailing, 30)
            .frame(height: 32)
            Spacer()
        }
        .onAppear {
            if let version = Updates.justUpdatedTo {
                message = T("Atualizado para a versão \(version).", "Updated to version \(version).", "Actualizado a la versión \(version).")
            } else if checkOnOpen {
                mainAction()
            }
        }
    }

    private func mainAction() {
        if failed {
            NSWorkspace.shared.open(Updates.downloadURL)
            return
        }
        busy = true
        Task {
            defer { busy = false }
            if newer {
                message = T("Baixando a versão nova… 0%", "Downloading the new version… 0%", "Descargando la nueva versión… 0%")
                do {
                    try await updates.install(progress: {
                        message = T("Baixando a versão nova… \($0)%", "Downloading the new version… \($0)%", "Descargando la nueva versión… \($0)%")
                    }, opening: { message = T("Pronto! Abrindo a versão nova…", "Done! Opening the new version…", "¡Listo! Abriendo la nueva versión…") })
                } catch {
                    failed = true
                    message = error.localizedDescription
                }
            } else {
                message = T("Procurando atualizações…", "Checking for updates…", "Buscando actualizaciones…")
                let result = await updates.check()
                message = result.message
                if case .newer = result { newer = true }
            }
        }
    }

    static let size = NSSize(width: 340, height: 410)
}

/// Janelinha "Atalhos": a tecla em negrito e o que ela faz, em cinza.
struct ShortcutsView: View {
    let close: () -> Void
    @ObservedObject private var lang = Lang.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(T("Atalhos", "Shortcuts", "Atajos")).font(.system(size: 13, weight: .bold))
            Text(T("Funcionam com qualquer janela na frente, inclusive jogos", "They work with any window in front, even games", "Funcionan con cualquier ventana al frente, incluso juegos"))
                .font(.system(size: 12))
                .foregroundStyle(Theme.mutedText)
                .padding(.top, 4)
                .padding(.bottom, 10)
            VStack(alignment: .leading, spacing: 7) {
                ForEach(Shortcuts.list, id: \.keys) { shortcut in
                    HStack(spacing: 0) {
                        Text(shortcut.keys).fontWeight(.semibold).frame(width: 120, alignment: .leading)
                        Text(shortcut.action).foregroundStyle(Theme.mutedText)
                    }
                    .frame(height: 21)
                }
            }
            .font(.system(size: 12))
            Spacer()
            HStack {
                Spacer()
                DarkButton(title: T("Fechar", "Close", "Cerrar"), width: 100, action: close)
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .id(lang.code)
    }

    static var size: NSSize { NSSize(width: 440, height: 112 + 28 * CGFloat(Shortcuts.list.count)) }
}
