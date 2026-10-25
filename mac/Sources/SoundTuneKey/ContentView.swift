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
        }
        .frame(width: 411, height: 458)
        .background(Theme.background)
        .foregroundStyle(Theme.text)
        .preferredColorScheme(.dark)
    }

    private var volumePanel: some View {
        let app = model.selectedApp
        let volume = app.map { Int((model.volume(of: $0.bundleID) * 100).rounded()) }

        return VStack(alignment: .leading, spacing: 8) {
            Text(app.map { "Controlando: \($0.displayName)" } ?? "Selecione um app na lista")
                .font(.system(size: 13))
                .foregroundStyle(app == nil ? Theme.mutedText : Theme.text)
                .lineLimit(1)

            HStack(spacing: 10) {
                VolumeBar(value: volume ?? 0, enabled: app != nil) { newValue in
                    if let app { model.setVolume(Float(newValue) / 100, for: app.bundleID) }
                }
                Text(volume.map { "\($0)%" } ?? "—")
                    .font(.system(size: 13).monospacedDigit())
                    .foregroundStyle(app == nil ? Theme.mutedText : Theme.text)
                    .frame(width: 44, alignment: .trailing)
            }

            Text("⌘⌥↑ / ⌘⌥↓  volume ±5% (funciona com qualquer janela na frente)")
                .font(.system(size: 11))
                .foregroundStyle(Theme.mutedText)

            if let error = model.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.mutedText)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
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
