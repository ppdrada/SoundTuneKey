import SwiftUI

/// Paleta escura tirada do ícone (a mesma da versão Windows).
enum Theme {
    static let background = Color(hex: 0x1C1C1E)
    static let surface = Color(hex: 0x242427)
    static let elevated = Color(hex: 0x2C2C30)
    static let border = Color(hex: 0x3A3A40)
    static let text = Color(hex: 0xF2F2F2)
    static let mutedText = Color(hex: 0x9A9AA0)
    static let dim = Color(hex: 0x4A4A50)
    /// App no mudo: alto-falante e nome em vermelho, barra de volume apagada (como no Windows).
    static let mute = Color(hex: 0xE5534B)
    static let mutedBar = Color(hex: 0x6A6A70)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
