import SwiftUI

enum MediaGlyph { case previous, playPause, next, speaker }

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

            switch glyph {
            case .next: // ▶▶|
                context.fill(triangle(x, s * 0.42, right: true), with: shading)
                context.fill(triangle(x + s * 0.38, s * 0.42, right: true), with: shading)
                context.fill(bar(x + s * 0.84, s * 0.16), with: shading)
            case .previous: // |◀◀
                context.fill(bar(x, s * 0.16), with: shading)
                context.fill(triangle(x + s * 0.20, s * 0.42, right: false), with: shading)
                context.fill(triangle(x + s * 0.58, s * 0.42, right: false), with: shading)
            case .playPause: // ▶ ‖
                context.fill(triangle(x, s * 0.5, right: true), with: shading)
                context.fill(bar(x + s * 0.62, s * 0.14), with: shading)
                context.fill(bar(x + s * 0.86, s * 0.14), with: shading)
            case .speaker: // caixa + cone, e duas ondas de som
                context.fill(Path(CGRect(x: x, y: y + s * 0.34, width: s * 0.2, height: s * 0.32)), with: shading)
                context.fill(Path { p in
                    p.move(to: CGPoint(x: x + s * 0.18, y: y + s * 0.34))
                    p.addLine(to: CGPoint(x: x + s * 0.46, y: y + s * 0.08))
                    p.addLine(to: CGPoint(x: x + s * 0.46, y: y + s * 0.92))
                    p.addLine(to: CGPoint(x: x + s * 0.18, y: y + s * 0.66))
                    p.closeSubpath()
                }, with: shading)
                let line = StrokeStyle(lineWidth: max(1.5, s * 0.09), lineCap: .round)
                for (cx, rx, ry) in [(0.54, 0.18, 0.20), (0.63, 0.33, 0.38)] as [(CGFloat, CGFloat, CGFloat)] {
                    context.stroke(Path { p in
                        p.addArc(center: .zero, radius: 1, startAngle: .degrees(-50), endAngle: .degrees(50), clockwise: false)
                    }.applying(CGAffineTransform(translationX: x + s * cx, y: y + s * 0.5).scaledBy(x: s * rx, y: s * ry)),
                    with: shading, style: line)
                }
            }
        }
        .frame(width: size + 4, height: size + 4)
    }
}

/// Botão com ícone de mídia, apagado quando o app escolhido não aceita controles.
/// Mãozinha e um círculo claro com o mouse em cima; encolhe um pouco ao clicar.
struct MediaButton: View {
    let glyph: MediaGlyph
    let size: CGFloat
    let enabled: Bool
    var color: Color = Theme.text
    var dimColor: Color = Theme.dim
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MediaIcon(glyph: glyph, size: size, color: enabled ? color : dimColor)
        }
        .buttonStyle(MediaButtonStyle(size: size, color: color, enabled: enabled))
        .disabled(!enabled)
        .help(help)
        .frame(maxWidth: .infinity)
    }
}

private struct MediaButtonStyle: ButtonStyle {
    let size: CGFloat
    let color: Color
    let enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        Styled(configuration: configuration, size: size, color: color, enabled: enabled)
    }

    private struct Styled: View {
        let configuration: Configuration
        let size: CGFloat
        let color: Color
        let enabled: Bool
        @State private var hovering = false

        var body: some View {
            let diameter = size * 2.4
            configuration.label
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(color.opacity(enabled && hovering ? (configuration.isPressed ? 0.22 : 0.12) : 0)))
                .scaleEffect(configuration.isPressed ? 0.86 : 1)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .animation(.easeOut(duration: 0.15), value: hovering)
                .contentShape(Circle())
                .onHover { hovering = $0 }
                .pointerCursor(enabled)
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
