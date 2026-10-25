import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            Text("Aplicativos com som")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(model.apps) { app in
                        AppRow(app: app,
                               volume: model.volume(of: app.bundleID),
                               selected: app.bundleID == model.selectedBundleID)
                            .contentShape(Rectangle())
                            .onTapGesture { model.selectedBundleID = app.bundleID }
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

            volumePanel

            Divider().overlay(Theme.border)

            ShortcutsBox()

            Divider().overlay(Theme.border)

            Toggle("Iniciar com o Mac", isOn: Binding(get: { model.startsAtLogin },
                                                     set: { model.setStartsAtLogin($0) }))
                .toggleStyle(.checkbox)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .frame(width: 411, height: 500)
        .background(Theme.background)
        .foregroundStyle(Theme.text)
        .preferredColorScheme(.dark)
        .onAppear { model.refreshStartsAtLogin() }
    }

    private var volumePanel: some View {
        let app = model.selectedApp
        let volume = app.map { Int((model.volume(of: $0.bundleID) * 100).rounded()) }

        // de cima para baixo: tempo da música, ⏮ ⏯ ⏭ e o volume (a mesma ordem do menu da barra)
        return VStack(alignment: .leading, spacing: 14) {
            Text(app.map { "Controlando: \($0.displayName)" } ?? "Selecione um app na lista")
                .font(.system(size: 13))
                .foregroundStyle(app == nil ? Theme.mutedText : Theme.text)
                .lineLimit(1)

            // a bolinha do tempo é menor: tempos 3 pontos mais largos para as trilhas começarem juntas
            TimeBar(status: model.mediaStatus, labelWidth: 43) { model.seek(to: $0) }

            HStack(spacing: 0) {
                MediaButton(glyph: .previous, size: 14, enabled: model.mediaSupported,
                            help: "Volta ao começo (2x rápido: música anterior)") { model.mediaPrevious() }
                MediaButton(glyph: .playPause, size: 14, enabled: model.mediaSupported,
                            help: "Pausar / continuar") { model.mediaPlayPause() }
                MediaButton(glyph: .next, size: 14, enabled: model.mediaSupported,
                            help: "Próxima música") { model.mediaNext() }
            }

            HStack(spacing: 6) {
                // alto-falante ao lado do volume, para não confundir com a barra de tempo
                MediaIcon(glyph: .speaker, size: 14, color: Theme.mutedText)
                    .frame(width: 40, alignment: .leading) // mesma largura do tempo, para as barras se alinharem
                VolumeBar(value: volume ?? 0, enabled: app != nil) { newValue in
                    if let app { model.setVolume(Float(newValue) / 100, for: app.bundleID) }
                }
                Text(volume.map { "\($0)%" } ?? "—")
                    .font(.system(size: 13).monospacedDigit())
                    .foregroundStyle(app == nil ? Theme.mutedText : Theme.text)
                    .frame(width: 40, alignment: .trailing)
            }

            if let error = model.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.mutedText)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }
}

/// Lista de atalhos embaixo da janela, como na versão Windows.
private struct ShortcutsBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Atalhos (funcionam com qualquer janela na frente)")
                .foregroundStyle(Theme.mutedText)
                .padding(.bottom, 2)
            ForEach(Shortcuts.list, id: \.keys) { shortcut in
                HStack(spacing: 0) {
                    Text(shortcut.keys)
                        .fontWeight(.semibold)
                        .frame(width: 90, alignment: .leading)
                    Text(shortcut.action)
                        .foregroundStyle(Theme.mutedText)
                }
            }
        }
        .font(.system(size: 12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct AppRow: View {
    let app: AudioApp
    let volume: Float
    let selected: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let icon = app.icon {
                Image(nsImage: icon).resizable().frame(width: 22, height: 22)
            } else {
                RoundedRectangle(cornerRadius: 5).fill(Theme.dim).frame(width: 22, height: 22)
            }
            Text(app.displayName).lineLimit(1)
            Spacer()
            if app.isPlaying {
                HStack(spacing: 5) {
                    Circle().fill(Theme.text).frame(width: 6, height: 6)
                    Text("tocando")
                }
                .font(.system(size: 11))
                .foregroundStyle(Theme.text)
            } else {
                Text("parado")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.dim)
            }
            Text("\(Int((volume * 100).rounded()))%")
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(Theme.mutedText)
                .frame(width: 40, alignment: .trailing)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(selected ? Theme.border : Color.clear))
    }
}
