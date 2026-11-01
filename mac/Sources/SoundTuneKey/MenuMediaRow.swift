import SwiftUI

/// Mini player no topo do menu da barra de menus, com o mesmo desenho da janela. Clicar não
/// fecha o menu (dá para tocar duas vezes no ⏮). Usa as cores do sistema, porque o menu
/// segue o modo claro ou escuro do Mac.
struct MenuMediaRow: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var lang = Lang.shared

    static let size = NSSize(width: 260, height: 8 + 26 + 36 + 8 + 28 + 12)

    var body: some View {
        PlayerView(model: model, style: .menu)
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 12, trailing: 10))
            .frame(width: Self.size.width, height: Self.size.height)
            .id(lang.english)
    }
}
