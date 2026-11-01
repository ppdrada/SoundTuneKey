import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var updates: Updates
    @ObservedObject private var lang = Lang.shared
    var openShortcuts: () -> Void = {}
    /// Abre o Sobre; true já procura a versão nova (faixa de versão nova).
    var openAbout: (Bool) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            // títulos das colunas, como na lista do Windows
            HStack {
                Text(T("Aplicativo", "App"))
                Spacer()
                Text("Volume")
            }
            .font(.system(size: 11))
            .foregroundStyle(Theme.mutedText)
            .padding(.horizontal, 16) // o mesmo recuo das linhas (8 da lista + 8 da linha)
            .padding(.vertical, 6)
            .background(Theme.elevated)

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(model.apps) { app in
                        AppRow(app: app,
                               volume: model.volume(of: app.bundleID),
                               muted: model.isMuted(app.bundleID),
                               selected: app.bundleID == model.selectedBundleID)
                            .contentShape(Rectangle())
                            .onTapGesture { model.selectedBundleID = app.bundleID }
                            // só o Mudo, marcado com ✓; não troca o app controlado. App em cinza não tem mudo
                            .contextMenu {
                                if app.hasAudio {
                                    Toggle(T("Mudo", "Mute"), isOn: Binding(get: { model.isMuted(app.bundleID) },
                                                                            set: { _ in model.toggleMute(app.bundleID) }))
                                }
                            }
                            .pointerCursor()
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .background(Theme.surface)
            .overlay(alignment: .center) {
                if model.apps.isEmpty {
                    Text(T("Nenhum app com som", "No apps with sound"))
                        .foregroundStyle(Theme.mutedText)
                }
            }

            Divider().overlay(Theme.border)

            controllingRow

            PlayerView(model: model, style: .window)
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 14, trailing: 10))

            if let error = model.errorMessage {
                errorBox(error)
            }

            if let version = updates.available {
                LinkText(title: T("Versão \(version) disponível · Atualizar", "Version \(version) available · Update")) { openAbout(true) }
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .background(Theme.elevated)
            }

            footer
        }
        .frame(width: 411, height: 440)
        .background(Theme.background)
        .foregroundStyle(Theme.text)
        .preferredColorScheme(.dark)
        .onAppear { model.refreshStartsAtLogin() }
        .id(lang.english) // trocar o idioma escreve tudo de novo, na hora
    }

    private var controllingRow: some View {
        let app = model.selectedApp
        return HStack(spacing: 0) {
            Text(app.map { T("Controlando: ", "Controlling: ") + $0.displayName + ($0.hasAudio ? "" : T(" (sem som ainda)", " (no sound yet)")) }
                 ?? T("Selecione um app na lista", "Pick an app from the list"))
                .font(.system(size: 13))
                .foregroundStyle(app == nil ? Theme.mutedText : Theme.text)
                .lineLimit(1)
            Spacer(minLength: 8)
            ToggleSwitch(title: T("Aviso na tela", "On-screen notice"), isOn: $model.showOsd)
        }
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .frame(height: 34)
    }

    private func errorBox(_ error: String) -> some View {
        HStack(spacing: 8) {
            Text(error)
                .font(.system(size: 11))
                .foregroundStyle(Theme.mutedText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true) // as duas linhas, sem cortar
            if error == MediaError.chromeJavaScriptOffMessage {
                Button(T("Como ligar", "How to turn on")) { ChromeMedia.showSetup() }
                    .controlSize(.small)
                    .pointerCursor()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    /// Rodapé: "Iniciar com o Mac" à esquerda; microfone, Atalhos e Sobre à direita.
    private var footer: some View {
        HStack(spacing: 12) {
            RadioDot(title: T("Iniciar com o Mac", "Start with Mac"), isOn: Binding(get: { model.startsAtLogin },
                                                              set: { model.setStartsAtLogin($0) }))
            Spacer()
            if let micMuted = model.micMuted {
                MicButton(muted: micMuted) { model.toggleMic() }
            }
            LinkText(title: T("Atalhos", "Shortcuts"), action: openShortcuts)
            LinkText(title: T("Sobre", "About")) { openAbout(false) }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 2)
        .frame(height: 32)
    }
}

/// Ícone do microfone no rodapé: cinza, branco com o mouse em cima, vermelho e cortado desligado.
private struct MicButton: View {
    let muted: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            MediaIcon(glyph: muted ? .micMuted : .mic, size: 13,
                      color: muted ? Theme.mute : hovering ? Theme.text : Theme.mutedText)
                .frame(width: 30, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(T("Liga / desliga o microfone (⌃⌥V)", "Microphone on / off (⌃⌥V)"))
        .pointerCursor()
    }
}

private struct AppRow: View {
    let app: AudioApp
    let volume: Float
    let muted: Bool
    let selected: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let icon = app.icon {
                Image(nsImage: icon).resizable().frame(width: 22, height: 22)
            } else {
                RoundedRectangle(cornerRadius: 5).fill(Theme.dim).frame(width: 22, height: 22)
            }
            // em cinza: aberto, mas ainda sem som
            Text(app.displayName).lineLimit(1)
                .foregroundStyle(!app.hasAudio ? Theme.mutedText : muted ? Theme.mute : Theme.text)
            Spacer()
            // tocando: alto-falante no fim da coluna do nome (cortado e vermelho no mudo)
            if app.isPlaying {
                MediaIcon(glyph: muted ? .speakerMuted : .speaker, size: 11, color: muted ? Theme.mute : Theme.mutedText)
            }
            Text(app.hasAudio ? "\(Int((volume * 100).rounded()))%" : "—")
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(muted && app.hasAudio ? Theme.mute : Theme.mutedText)
                .frame(width: 40, alignment: .trailing)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(selected ? Theme.border : Color.clear))
    }
}
