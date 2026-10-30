import AppKit
import SwiftUI

/// Interruptor do "Aviso na tela": trilha de 34 × 18, a bolinha desliza e a cor muda junto.
struct ToggleSwitch: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(title).foregroundStyle(Theme.mutedText)
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule().fill(isOn ? Theme.text : Theme.dim)
                Circle().fill(isOn ? Theme.background : Theme.mutedText)
                    .frame(width: 12, height: 12)
                    .padding(.horizontal, 3)
            }
            .frame(width: 34, height: 18)
        }
        .font(.system(size: 12))
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { isOn.toggle() } }
        .pointerCursor()
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? "ligado" : "desligado")
    }
}

/// Bolinha no lugar da caixinha ("Iniciar com o Mac"): anel de 11; marcada, com uma bolinha no meio.
struct RadioDot: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                Circle().strokeBorder(isOn ? Theme.text : Theme.mutedText, lineWidth: 1.2)
                if isOn { Circle().fill(Theme.text).frame(width: 5.5, height: 5.5) }
            }
            .frame(width: 11, height: 11)
            Text(title)
        }
        .font(.system(size: 12))
        .contentShape(Rectangle())
        .onTapGesture { isOn.toggle() }
        .pointerCursor()
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? "ligado" : "desligado")
    }

    /// A mesma bolinha para os itens de liga/desliga do menu da barra.
    static func menuImage(on: Bool) -> NSImage {
        // 16 × 16 como os símbolos dos outros itens, com o anel de 11 no meio
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { rect in
            let dot = rect.insetBy(dx: 2.5, dy: 2.5)
            NSColor.black.setStroke()
            let ring = NSBezierPath(ovalIn: dot.insetBy(dx: 0.6, dy: 0.6))
            ring.lineWidth = 1.2
            ring.stroke()
            if on { NSBezierPath(ovalIn: dot.insetBy(dx: 2.75, dy: 2.75)).fill() }
            return true
        }
        image.isTemplate = true
        return image
    }
}

/// Link em cinza que sublinha com o mouse em cima e fica branco ao clicar ("Atalhos", "Sobre").
struct LinkText: View {
    let title: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(title).underline(hovering)
        }
        .buttonStyle(LinkStyle())
        .onHover { hovering = $0 }
        .pointerCursor()
    }

    private struct LinkStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 12))
                .foregroundStyle(configuration.isPressed ? Theme.text : Theme.mutedText)
        }
    }
}

/// Botão escuro das janelinhas (Fechar, Verificar atualizações).
struct DarkButton: View {
    let title: String
    let width: CGFloat
    var primary = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: primary ? .semibold : .regular))
                .foregroundStyle(primary ? Theme.background : Theme.text)
                .frame(width: width, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(primary ? Theme.text : Theme.elevated))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.border, lineWidth: primary ? 0 : 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointerCursor()
    }
}

/// Janelinha sem barra de título, com cantos arredondados e tema escuro; fecha com Esc.
final class DialogWindow: NSWindow {
    init<Content: View>(size: NSSize, @ViewBuilder content: (_ close: @escaping () -> Void) -> Content) {
        super.init(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        let view = content { [weak self] in self?.close() }
            .frame(width: size.width, height: size.height)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
            .foregroundStyle(Theme.text)
            .preferredColorScheme(.dark)
        contentView = NSHostingView(rootView: view)
        center()
    }

    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { close() }
}
