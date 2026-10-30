import SwiftUI

enum MediaGlyph { case previous, play, pause, next, speaker, speakerMuted, mic, micMuted }

/// Ícones desenhados em vez de caracteres como ⏮: as fontes deixam esses símbolos pequenos,
/// fora do centro ou coloridos (emoji). Mesmas formas da versão Windows (MediaIcons.cs).
struct MediaIcon: View {
    let glyph: MediaGlyph
    let size: CGFloat
    var color: Color = Theme.text

    var body: some View {
        Canvas { context, canvasSize in
            let s = size
            let x = (canvasSize.width - s) / 2
            let y = (canvasSize.height - s) / 2
            let shading = GraphicsContext.Shading.color(color)
            let line = StrokeStyle(lineWidth: max(1.5, s * 0.09), lineCap: .round)

            func triangle(_ tx: CGFloat, _ w: CGFloat, right: Bool) -> Path {
                Path { p in
                    if right {
                        p.move(to: CGPoint(x: tx, y: y))
                        p.addLine(to: CGPoint(x: tx + w, y: y + s / 2))
                        p.addLine(to: CGPoint(x: tx, y: y + s))
                    } else {
                        p.move(to: CGPoint(x: tx + w, y: y))
                        p.addLine(to: CGPoint(x: tx, y: y + s / 2))
                        p.addLine(to: CGPoint(x: tx + w, y: y + s))
                    }
                    p.closeSubpath()
                }
            }
            func bar(_ bx: CGFloat, _ w: CGFloat) -> Path {
                Path(CGRect(x: bx, y: y, width: w, height: s))
            }
            func cross() {
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: x + s * 0.62, y: y + s * 0.34)); p.addLine(to: CGPoint(x: x + s * 0.94, y: y + s * 0.66))
                    p.move(to: CGPoint(x: x + s * 0.94, y: y + s * 0.34)); p.addLine(to: CGPoint(x: x + s * 0.62, y: y + s * 0.66))
                }, with: shading, style: line)
            }

            switch glyph {
            case .next: // ▶▶|
                context.fill(triangle(x, s * 0.42, right: true), with: shading)
                context.fill(triangle(x + s * 0.38, s * 0.42, right: true), with: shading)
                context.fill(bar(x + s * 0.84, s * 0.16), with: shading)
            case .previous: // |◀◀
                context.fill(bar(x, s * 0.16), with: shading)
                context.fill(triangle(x + s * 0.20, s * 0.42, right: false), with: shading)
                context.fill(triangle(x + s * 0.58, s * 0.42, right: false), with: shading)
            case .play: // ▶, um pouco para a direita para parecer centrado
                context.fill(triangle(x + s * 0.12, s * 0.86, right: true), with: shading)
            case .pause: // ‖
                context.fill(bar(x + s * 0.12, s * 0.28), with: shading)
                context.fill(bar(x + s * 0.60, s * 0.28), with: shading)
            case .speaker, .speakerMuted: // caixa + cone; ao lado, duas ondas de som ou um X (mudo)
                context.fill(Path(CGRect(x: x, y: y + s * 0.34, width: s * 0.2, height: s * 0.32)), with: shading)
                context.fill(Path { p in
                    p.move(to: CGPoint(x: x + s * 0.18, y: y + s * 0.34))
                    p.addLine(to: CGPoint(x: x + s * 0.46, y: y + s * 0.08))
                    p.addLine(to: CGPoint(x: x + s * 0.46, y: y + s * 0.92))
                    p.addLine(to: CGPoint(x: x + s * 0.18, y: y + s * 0.66))
                    p.closeSubpath()
                }, with: shading)
                if glyph == .speakerMuted {
                    cross()
                    break
                }
                for (cx, rx, ry) in [(0.54, 0.18, 0.20), (0.63, 0.33, 0.38)] as [(CGFloat, CGFloat, CGFloat)] {
                    context.stroke(Path { p in
                        p.addArc(center: .zero, radius: 1, startAngle: .degrees(-50), endAngle: .degrees(50), clockwise: false)
                    }.applying(CGAffineTransform(translationX: x + s * cx, y: y + s * 0.5).scaledBy(x: s * rx, y: s * ry)),
                    with: shading, style: line)
                }
            case .mic, .micMuted: // cápsula, o "U" do suporte e o pé; cortado por uma diagonal quando desligado
                context.fill(Path(roundedRect: CGRect(x: x + s * 0.34, y: y, width: s * 0.32, height: s * 0.6), cornerRadius: s * 0.16), with: shading)
                context.stroke(Path { p in
                    p.addArc(center: CGPoint(x: x + s * 0.5, y: y + s * 0.38), radius: s * 0.3,
                             startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                    p.move(to: CGPoint(x: x + s * 0.5, y: y + s * 0.68)); p.addLine(to: CGPoint(x: x + s * 0.5, y: y + s * 0.9))
                    p.move(to: CGPoint(x: x + s * 0.3, y: y + s * 0.92)); p.addLine(to: CGPoint(x: x + s * 0.7, y: y + s * 0.92))
                }, with: shading, style: line)
                if glyph == .micMuted {
                    context.stroke(Path { p in
                        p.move(to: CGPoint(x: x + s * 0.1, y: y + s * 0.05)); p.addLine(to: CGPoint(x: x + s * 0.9, y: y + s * 0.95))
                    }, with: shading, style: line)
                }
            }
        }
        .frame(width: size + 4, height: size + 4)
    }
}

/// Cores do player: escuras na janela; no menu, as do sistema, que segue o modo claro ou escuro.
struct PlayerStyle {
    let iconSize: CGFloat
    let rowHeight: CGFloat
    let volumeThumb: CGFloat
    let text: Color
    let secondary: Color
    let rest: Color
    let disabled: Color
    let hover: Color
    let playIcon: Color

    static let window = PlayerStyle(iconSize: 16, rowHeight: 44, volumeThumb: 18, text: Theme.text, secondary: Theme.mutedText,
                                    rest: Theme.dim, disabled: Theme.border, hover: Theme.border, playIcon: Theme.background)
    static let menu = PlayerStyle(iconSize: 13, rowHeight: 36, volumeThumb: 14, text: .primary, secondary: .secondary,
                                  rest: .primary.opacity(0.25), disabled: .primary.opacity(0.12), hover: .primary.opacity(0.15),
                                  playIcon: Color(nsColor: .textBackgroundColor))
}

/// ⏮ e ⏭: só o ícone; com o mouse em cima aparece um círculo, e ao clicar o ícone encolhe.
struct MediaButton: View {
    let glyph: MediaGlyph
    let size: CGFloat
    let enabled: Bool
    var color: Color = Theme.text
    var dimColor: Color = Theme.dim
    var hoverColor: Color = Theme.border
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MediaIcon(glyph: glyph, size: size, color: enabled ? color : dimColor)
        }
        .buttonStyle(PressStyle(diameter: size * 2.6, enabled: enabled) { hovering, _ in
            Circle().fill(hoverColor.opacity(enabled && hovering ? 1 : 0))
        })
        .disabled(!enabled)
        .help(help)
    }
}

/// ▶ / ‖ num círculo cheio: ▶ quando está pausado, ‖ quando está tocando.
struct PlayButton: View {
    let playing: Bool
    let style: PlayerStyle
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MediaIcon(glyph: playing ? .pause : .play, size: style.iconSize * 0.9, color: style.playIcon)
        }
        .buttonStyle(PressStyle(diameter: style.iconSize * 2.5, enabled: enabled, hoverScale: 1.06) { _, _ in
            Circle().fill(enabled ? style.text : style.disabled)
        })
        .disabled(!enabled)
        .help("Pausar / continuar")
    }
}

/// Círculo de fundo, crescer com o mouse em cima e encolher para 82% ao clicar, com animação curta.
private struct PressStyle<Background: View>: ButtonStyle {
    let diameter: CGFloat
    let enabled: Bool
    var hoverScale: CGFloat = 1
    let background: (_ hovering: Bool, _ pressed: Bool) -> Background

    func makeBody(configuration: Configuration) -> some View {
        Styled(configuration: configuration, style: self)
    }

    private struct Styled: View {
        let configuration: Configuration
        let style: PressStyle
        @State private var hovering = false

        var body: some View {
            let active = style.enabled && hovering
            configuration.label
                .frame(width: style.diameter, height: style.diameter)
                .background(style.background(hovering, configuration.isPressed))
                .scaleEffect(style.enabled && configuration.isPressed ? 0.82 : active ? style.hoverScale : 1)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .animation(.easeOut(duration: 0.15), value: hovering)
                .contentShape(Circle())
                .onHover { hovering = $0 }
                .pointerCursor(style.enabled)
        }
    }
}

/// O player, o mesmo na janela e no menu da barra: tempo da música, ⏮ ▶ ⏭ juntos no meio e o volume.
struct PlayerView: View {
    @ObservedObject var model: AppModel
    let style: PlayerStyle

    var body: some View {
        let app = model.selectedApp
        let volume = app.map { Int((model.volume(of: $0.bundleID) * 100).rounded()) }
        let muted = app.map { model.isMuted($0.bundleID) } ?? false
        let h = style.rowHeight

        VStack(spacing: 0) {
            TimeBar(status: model.mediaStatus, labelColor: style.secondary, fill: style.text, rest: style.rest,
                    disabled: style.disabled) { model.seek(to: $0) }
                .frame(height: 26)

            HStack(spacing: 0) {
                Spacer(minLength: 0)
                MediaButton(glyph: .previous, size: style.iconSize, enabled: model.mediaSupported, color: style.text,
                            dimColor: style.disabled, hoverColor: style.hover,
                            help: "Volta ao começo (2x rápido: música anterior)") { model.mediaPrevious() }
                    .frame(width: h * 2.4)
                PlayButton(playing: model.mediaStatus?.isPlaying ?? false, style: style,
                           enabled: model.mediaSupported) { model.mediaPlayPause() }
                    .frame(width: h * 1.5)
                MediaButton(glyph: .next, size: style.iconSize, enabled: model.mediaSupported, color: style.text,
                            dimColor: style.disabled, hoverColor: style.hover, help: "Próxima música") { model.mediaNext() }
                    .frame(width: h * 2.4)
                Spacer(minLength: 0)
            }
            .frame(height: h)

            Spacer().frame(height: 8)

            HStack(spacing: 0) {
                // o alto-falante liga e desliga o mudo
                Button { if let app { model.toggleMute(app.bundleID) } } label: {
                    MediaIcon(glyph: muted ? .speakerMuted : .speaker, size: style.iconSize * 0.85,
                              color: muted ? Theme.mute : style.secondary)
                        .frame(width: 30, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(app == nil)
                .help(muted ? "Tirar o mudo" : "Mudo")
                .pointerCursor(app != nil)
                Spacer().frame(width: 16)
                VolumeBar(value: volume ?? 0, enabled: app != nil, thumbSize: style.volumeThumb,
                          fill: muted ? Theme.mutedBar : style.text, rest: style.rest, disabled: style.disabled,
                          arrowKeys: true) { newValue in
                    if let app { model.setVolume(Float(newValue) / 100, for: app.bundleID) }
                }
                Text(volume.map { "\($0)%" } ?? "—")
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(style.secondary)
                    .frame(width: 46, alignment: .trailing)
            }
            .frame(height: 28)
        }
    }
}

extension View {
    /// Mãozinha do mouse em cima de algo clicável (como um link).
    func pointerCursor(_ active: Bool = true) -> some View {
        modifier(PointerCursor(active: active))
    }
}

private struct PointerCursor: ViewModifier {
    let active: Bool
    /// Só tira a mãozinha se foi este item que colocou (o cursor do macOS é uma pilha).
    @State private var pushed = false

    func body(content: Content) -> some View {
        content.onHover { inside in
            if inside && active && !pushed {
                NSCursor.pointingHand.push()
                pushed = true
            } else if !inside && pushed {
                NSCursor.pop()
                pushed = false
            }
        }
    }
}
