import SwiftUI

/// Barra de volume no tema escuro, igual à do Windows: trilha clara até o volume atual e
/// apagada depois, com uma bolinha para arrastar. Clicar na trilha também funciona.
struct VolumeBar: View {
    /// De 0 a 100.
    let value: Int
    let enabled: Bool
    let onChange: (Int) -> Void

    private let trackHeight: CGFloat = 6
    private let thumbSize: CGFloat = 18

    var body: some View {
        GeometryReader { geo in
            // a trilha começa e termina meia bolinha para dentro, para a bolinha caber nas pontas
            let width = geo.size.width - thumbSize
            let thumbX = thumbSize / 2 + width * CGFloat(value) / 100

            ZStack(alignment: .leading) {
                Capsule().fill(enabled ? Theme.dim : Theme.border)
                    .frame(width: width, height: trackHeight)
                    .offset(x: thumbSize / 2)
                if enabled {
                    Capsule().fill(Theme.text)
                        .frame(width: thumbX - thumbSize / 2, height: trackHeight)
                        .offset(x: thumbSize / 2)
                }
                Circle().fill(enabled ? Theme.text : Theme.dim)
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: thumbX - thumbSize / 2)
            }
            .frame(height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                guard enabled else { return }
                let fraction = (drag.location.x - thumbSize / 2) / width
                let newValue = Int((min(max(fraction, 0), 1) * 100).rounded())
                if newValue != value { onChange(newValue) }
            })
        }
        .frame(height: thumbSize + 4)
    }
}
