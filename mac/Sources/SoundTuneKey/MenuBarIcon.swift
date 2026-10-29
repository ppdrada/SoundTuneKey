import AppKit

/// Ícone da barra de menus: as quatro barras em rampa e a linha com o play do ícone do app
/// (assets/icon/icon.svg), em versão "template" para o macOS pintar de claro ou escuro.
enum MenuBarIcon {
    static let image: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: true) { _ in
            // coordenadas do icon.svg (grupo de 512 x 576), encaixadas em 18 x 18
            let scale: CGFloat = 16 / 576
            let origin = CGPoint(x: (18 - 512 * scale) / 2, y: 1)
            func pt(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
                NSPoint(x: origin.x + x * scale, y: origin.y + y * scale)
            }
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
                NSRect(x: origin.x + x * scale, y: origin.y + y * scale, width: w * scale, height: h * scale)
            }
            // polígono com os cantos arredondados do svg (stroke com junção redonda)
            func shape(_ points: [(CGFloat, CGFloat)], corner: CGFloat) -> NSBezierPath {
                let path = NSBezierPath()
                path.move(to: pt(points[0].0, points[0].1))
                for p in points.dropFirst() { path.line(to: pt(p.0, p.1)) }
                path.close()
                path.lineJoinStyle = .round
                path.lineWidth = corner * scale
                return path
            }

            // as barras clareiam da esquerda para a direita no app; aqui viram transparências
            let bars: [([(CGFloat, CGFloat)], CGFloat)] = [
                ([(20, 281.7), (96, 237.3), (96, 300), (20, 300)], 1),
                ([(152, 204.7), (228, 160.3), (228, 300), (152, 300)], 0.8),
                ([(284, 127.7), (360, 83.3), (360, 300), (284, 300)], 0.6),
                ([(416, 50.7), (492, 6.3), (492, 300), (416, 300)], 0.4),
            ]
            for (points, alpha) in bars {
                let color = NSColor.black.withAlphaComponent(alpha)
                color.setFill()
                color.setStroke()
                let bar = shape(points, corner: 8)
                bar.fill()
                bar.stroke()
            }

            // a linha do slider: acesa até a bolinha, apagada depois
            NSColor.black.withAlphaComponent(0.35).setFill()
            NSBezierPath(roundedRect: rect(256, 439, 240, 34), xRadius: 17 * scale, yRadius: 17 * scale).fill()
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect(16, 439, 240, 34), xRadius: 17 * scale, yRadius: 17 * scale).fill()

            // bolinha com o "play" vazado
            NSBezierPath(ovalIn: rect(136, 336, 240, 240)).fill()
            let play = shape([(226, 404), (318, 456), (226, 508)], corner: 12)
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            play.fill()
            play.stroke()
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            return true
        }
        image.isTemplate = true
        return image
    }()
}
