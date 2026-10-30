import AppKit

/// Ícone da barra de menus: as quatro barras crescentes e a linha do ícone do app
/// (assets/icon/icon.svg), em versão "template" para o macOS pintar de claro ou escuro.
/// Com o app escolhido no mudo, o ícone fica vermelho.
enum MenuBarIcon {
    static let image = make(.black)
    static let muted = make(NSColor(Theme.mute))

    private static func make(_ color: NSColor) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: true) { _ in
            // coordenadas do icon.svg (grupo de 512 x 570), encaixadas em 18 x 18
            let scale: CGFloat = 16 / 512
            let origin = CGPoint(x: 1, y: (18 - 570 * scale) / 2)
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
                NSRect(x: origin.x + x * scale, y: origin.y + y * scale, width: w * scale, height: h * scale)
            }

            // as partes claras do ícone ficam cheias; as apagadas, meio transparentes
            let full = color, dim = color.withAlphaComponent(0.35)
            for (x, y, color) in [(32, 170, full), (152, 115, full), (272, 60, dim), (392, 0, dim)] as [(CGFloat, CGFloat, NSColor)] {
                color.setFill()
                NSBezierPath(roundedRect: rect(x, y, 88, 360 - y), xRadius: 16 * scale, yRadius: 16 * scale).fill()
            }
            dim.setFill()
            NSBezierPath(roundedRect: rect(256, 455, 240, 30), xRadius: 15 * scale, yRadius: 15 * scale).fill()
            full.setFill()
            NSBezierPath(roundedRect: rect(16, 455, 240, 30), xRadius: 15 * scale, yRadius: 15 * scale).fill()

            // bolinha com o "play" vazado
            NSBezierPath(ovalIn: rect(156, 370, 200, 200)).fill()
            let play = NSBezierPath()
            play.move(to: NSPoint(x: origin.x + 231 * scale, y: origin.y + 427 * scale))
            play.line(to: NSPoint(x: origin.x + 306 * scale, y: origin.y + 470 * scale))
            play.line(to: NSPoint(x: origin.x + 231 * scale, y: origin.y + 513 * scale))
            play.close()
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            play.fill()
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            return true
        }
        // só o preto é template; o vermelho fica com a própria cor
        image.isTemplate = color == .black
        return image
    }
}
