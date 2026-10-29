import SwiftUI

/// Primeira linha do menu da barra de menus, como no mini player do Spotify e na mesma ordem
/// da janela: o tempo da música, ⏮ ⏯ ⏭ e o volume. Clicar não fecha o menu (dá para tocar
/// duas vezes no ⏮). Usa as cores do sistema, porque o menu segue o modo claro ou escuro do Mac.
struct MenuMediaRow: View {
    @ObservedObject var model: AppModel

    static let size = NSSize(width: 260, height: 134)

    var body: some View {
        let app = model.selectedApp
        let volume = app.map { Int((model.volume(of: $0.bundleID) * 100).rounded()) }
        let muted = app.map { model.isMuted($0.bundleID) } ?? false

        VStack(spacing: 10) {
            // a bolinha do tempo é menor: tempos 3 pontos mais largos para as trilhas começarem juntas
            TimeBar(status: model.mediaStatus, labelColor: .secondary,
                    fill: .primary, rest: .primary.opacity(0.25), disabled: .primary.opacity(0.12),
                    labelWidth: 39) { model.seek(to: $0) }

            HStack(spacing: 0) {
                button(.previous, "Volta ao começo (2x rápido: música anterior)") { model.mediaPrevious() }
                button(.playPause, "Pausar / continuar") { model.mediaPlayPause() }
                button(.next, "Próxima música") { model.mediaNext() }
            }

            HStack(spacing: 6) {
                MediaIcon(glyph: .speaker, size: 12, color: muted ? Theme.mute : .secondary)
                    .frame(width: 36, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { if let app { model.toggleMute(app.bundleID) } }
                    .help(muted ? "Tirar o mudo" : "Mudo")
                VolumeBar(value: volume ?? 0, enabled: app != nil,
                          fill: muted ? .primary.opacity(0.45) : .primary, rest: .primary.opacity(0.25), disabled: .primary.opacity(0.12)) { newValue in
                    if let app { model.setVolume(Float(newValue) / 100, for: app.bundleID) }
                }
                Text(volume.map { "\($0)%" } ?? "—")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .frame(width: Self.size.width, height: Self.size.height)
    }

    private func button(_ glyph: MediaGlyph, _ help: String, _ action: @escaping () -> Void) -> some View {
        MediaButton(glyph: glyph, size: 12, enabled: model.mediaSupported,
                    color: .primary, dimColor: .secondary.opacity(0.5), help: help, action: action)
    }
}
