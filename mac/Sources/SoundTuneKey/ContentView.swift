import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var updates: Updates
    var openShortcuts: () -> Void = {}
    /// Abre o Sobre; true já procura a versão nova (faixa de versão nova).
    var openAbout: (Bool) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            // títulos das colunas, como na lista do Windows
            HStack {
                Text("Aplicativo")
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
                            // só o Mudo, marcado com ✓; não troca o app controlado
                            .contextMenu {
                                Toggle("Mudo", isOn: Binding(get: { model.isMuted(app.bundleID) },
                                                             set: { _ in model.toggleMute(app.bundleID) }))
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
                    Text("Nenhum app com som aberto")
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
                LinkText(title: "Versão \(version) disponível · Atualizar") { openAbout(true) }
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
    }

    private var controllingRow: some View {
        let app = model.selectedApp
        return HStack(spacing: 0) {
            Text(app.map { "Controlando: \($0.displayName)" } ?? "Selecione um app na lista")
                .font(.system(size: 13))
                .foregroundStyle(app == nil ? Theme.mutedText : Theme.text)
                .lineLimit(1)
            Spacer(minLength: 8)
            ToggleSwitch(title: "Aviso na tela", isOn: $model.showOsd)
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
                Button("Como ligar") { ChromeMedia.showSetup() }
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
            RadioDot(title: "Iniciar com o Mac", isOn: Binding(get: { model.startsAtLogin },
                                                              set: { model.setStartsAtLogin($0) }))
            Spacer()
            if let micMuted = model.micMuted {
                MicButton(muted: micMuted) { model.toggleMic() }
            }
            LinkText(title: "Atalhos", action: openShortcuts)
            LinkText(title: "Sobre") { openAbout(false) }
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
        .help(muted ? "Ligar o microfone (⌃⌥V)" : "Desligar o microfone (⌃⌥V)")
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
            Text(app.displayName).lineLimit(1)
                .foregroundStyle(muted ? Theme.mute : Theme.text)
            Spacer()
            if app.isPlaying {
                HStack(spacing: 5) {
                    Circle().fill(Theme.text).frame(width: 6, height: 6)
                    Text("tocando")
                }
                .font(.system(size: 11))
                .foregroundStyle(muted ? Theme.mute : Theme.text)
            } else {
                Text("parado")
                    .font(.system(size: 11))
                    .foregroundStyle(muted ? Theme.mute : Theme.dim)
            }
            Text("\(Int((volume * 100).rounded()))%")
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(muted ? Theme.mute : Theme.mutedText)
                .frame(width: 40, alignment: .trailing)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(selected ? Theme.border : Color.clear))
    }
}
