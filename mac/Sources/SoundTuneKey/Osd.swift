import AppKit
import SwiftUI

/// Aviso na tela dos atalhos (volume, mudo, troca de app, microfone): um cartão embaixo, no
/// meio da tela em uso. Não rouba o foco, o clique passa através dele e aparece até sobre
/// jogos em tela cheia. Fica 1,2 s e some aos poucos em 0,3 s; apertar de novo reinicia o tempo.
@MainActor
final class Osd {
    enum Content: Equatable {
        case volume(app: String, volume: Int, muted: Bool)
        case mic(muted: Bool)
    }

    static let size = NSSize(width: 340, height: 78)

    private lazy var panel: NSPanel = {
        let panel = NSPanel(contentRect: NSRect(origin: .zero, size: Self.size),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.level = .screenSaver // acima das telas cheias
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        return panel
    }()
    private var hideTimer: Timer?

    func show(_ content: Content) {
        panel.contentView = NSHostingView(rootView: OsdCard(content: content))
        // NSScreen.main é a tela com o app em foco
        if let screen = NSScreen.main {
            panel.setFrameOrigin(NSPoint(x: screen.frame.midX - Self.size.width / 2, y: screen.frame.minY + 90))
        }
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let panel = self?.panel else { return }
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3
                    panel.animator().alphaValue = 0
                }, completionHandler: {
                    MainActor.assumeIsolated { if panel.alphaValue == 0 { panel.orderOut(nil) } }
                })
            }
        }
    }
}

struct OsdCard: View { // fora do private: o vídeo de demonstração desenha o aviso
    let content: Osd.Content

    var body: some View {
        let width = Osd.size.width
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(Theme.background.opacity(0.78))
            RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border, lineWidth: 1)

            switch content {
            case let .volume(app, volume, muted):
                Text(app)
                    .font(.system(size: 12.7))
                    .foregroundStyle(muted ? Theme.mute : Theme.mutedText)
                    .lineLimit(1)
                    .frame(width: width - 40)
                    .position(x: width / 2, y: 25)
                MediaIcon(glyph: muted ? .speakerMuted : .speaker, size: 13, color: muted ? Theme.mute : Theme.text)
                    .position(x: 20 + 13 / 2, y: 56)
                Bar(fraction: CGFloat(volume) / 100, fill: muted ? Theme.mutedBar : Theme.text)
                    .frame(width: width - 144, height: 6)
                    .position(x: width / 2, y: 56)
                Text("\(volume)%")
                    .font(.system(size: 12, weight: .bold).monospacedDigit())
                    .foregroundStyle(muted ? Theme.mutedText : Theme.text)
                    .frame(width: 44, alignment: .trailing)
                    .position(x: width - 20 - 22, y: 56)
            case let .mic(muted):
                Text(T("Microfone", "Microphone"))
                    .font(.system(size: 12.7))
                    .foregroundStyle(muted ? Theme.mute : Theme.mutedText)
                    .position(x: width / 2, y: 25)
                HStack(spacing: 8) {
                    MediaIcon(glyph: muted ? .micMuted : .mic, size: 18, color: muted ? Theme.mute : Theme.text)
                    Text(muted ? T("Desligado", "Off") : T("Ligado", "On"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(muted ? Theme.mute : Theme.text)
                }
                .position(x: width / 2, y: 54)
            }
        }
        .frame(width: Osd.size.width, height: Osd.size.height)
    }

    private struct Bar: View {
        let fraction: CGFloat
        let fill: Color

        var body: some View {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.dim)
                    Capsule().fill(fill).frame(width: geo.size.width * min(max(fraction, 0), 1))
                }
            }
        }
    }
}
