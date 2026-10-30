import SwiftUI

/// Barra no tema escuro, igual à do Windows: trilha clara até o valor atual e apagada depois,
/// com uma bolinha para arrastar. Clicar na trilha também funciona. Usada no volume e, mais
/// fina, no tempo da música.
struct VolumeBar: View {
    let value: Int
    var maximum = 100
    let enabled: Bool
    var trackHeight: CGFloat = 6
    var thumbSize: CGFloat = 18
    var fill: Color = Theme.text
    var rest: Color = Theme.dim
    var disabled: Color = Theme.border
    /// Setas do teclado mudam 1 de cada vez (a barra de volume, como no Windows).
    var arrowKeys = false
    let onChange: (Int) -> Void
    /// Ao soltar o mouse (a barra de tempo só pula para o trecho nessa hora).
    var onRelease: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            // a trilha começa e termina meia bolinha para dentro, para a bolinha caber nas pontas
            let width = geo.size.width - thumbSize
            let fraction = maximum > 0 ? CGFloat(min(max(value, 0), maximum)) / CGFloat(maximum) : 0
            let thumbX = thumbSize / 2 + width * fraction

            ZStack(alignment: .leading) {
                Capsule().fill(enabled ? rest : disabled)
                    .frame(width: width, height: trackHeight)
                    .offset(x: thumbSize / 2)
                if enabled {
                    Capsule().fill(fill)
                        .frame(width: thumbX - thumbSize / 2, height: trackHeight)
                        .offset(x: thumbSize / 2)
                }
                Circle().fill(enabled ? fill : rest)
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: thumbX - thumbSize / 2)
            }
            .frame(height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    guard enabled else { return }
                    let fraction = (drag.location.x - thumbSize / 2) / width
                    let newValue = Int((min(max(fraction, 0), 1) * CGFloat(maximum)).rounded())
                    if newValue != value { onChange(newValue) }
                }
                .onEnded { _ in if enabled { onRelease() } })
        }
        .frame(height: thumbSize + 4)
        .pointerCursor(enabled)
        .focusable(arrowKeys && enabled)
        .focusEffectDisabled()
        .onKeyPress(keys: [.leftArrow, .downArrow, .rightArrow, .upArrow]) { press in
            guard arrowKeys && enabled else { return .ignored }
            let step = press.key == .leftArrow || press.key == .downArrow ? -1 : 1
            let newValue = min(max(value + step, 0), maximum)
            if newValue != value { onChange(newValue) }
            return .handled
        }
    }
}

/// Barra de tempo da música: mais fina que a de volume, com o tempo atual à esquerda e a
/// duração à direita, para não confundir as duas. Arrastando, só o tempo da esquerda muda;
/// ao soltar, pula para o trecho. Apagada com --:-- quando o app não informa o tempo.
struct TimeBar: View {
    let status: MediaPlayer.Status?
    var labelColor: Color = Theme.mutedText
    var fill: Color = Theme.text
    var rest: Color = Theme.dim
    var disabled: Color = Theme.border
    var labelWidth: CGFloat = 49
    let onSeek: (Double) -> Void

    @State private var dragging: Int?

    var body: some View {
        let position = dragging ?? Int(status?.position ?? 0)
        HStack(spacing: 6) {
            Text(status.map { _ in Self.format(Double(position)) } ?? "--:--")
                .frame(width: labelWidth, alignment: .leading)
            VolumeBar(value: position, maximum: Int((status?.duration ?? 0).rounded(.up)), enabled: status != nil,
                      trackHeight: 3, thumbSize: 10, fill: fill, rest: rest, disabled: disabled,
                      onChange: { dragging = $0 },
                      onRelease: {
                          if let dragging { onSeek(Double(dragging)) }
                          dragging = nil
                      })
            Text(status.map { Self.format($0.duration) } ?? "--:--")
                .frame(width: labelWidth, alignment: .trailing)
        }
        .font(.system(size: 11).monospacedDigit())
        .foregroundStyle(labelColor)
    }

    static func format(_ seconds: Double) -> String {
        let total = Int(seconds)
        let (h, m, s) = (total / 3600, total / 60 % 60, total % 60)
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
