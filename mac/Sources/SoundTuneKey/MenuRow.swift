import SwiftUI

/// Item do menu da barra que **não fecha o menu** ao clicar: para escolher e ligar/desligar
/// (app controlado, mudo, microfone...), a pessoa vê o resultado e corrige na hora se errou.
/// Um item comum do macOS sempre fecha o menu; só um item desenhado (com view) fica aberto.
/// Lê o estado do modelo a cada mudança, então o ✓ e o texto acompanham sozinhos.
struct MenuRow: View {
    @ObservedObject var model: AppModel
    /// Texto, ícone (na coluna dos ícones) e cor do texto, lidos do modelo.
    let content: (AppModel) -> (title: String, icon: NSImage?, color: Color?)
    let action: () -> Void

    @ObservedObject private var lang = Lang.shared // o texto vem do content(), relido na troca de idioma
    @State private var hovering = false

    static let height: CGFloat = 22

    var body: some View {
        let (title, icon, color) = content(model)
        HStack(spacing: 6) {
            Group {
                if let icon {
                    Image(nsImage: icon).renderingMode(icon.isTemplate ? .template : .original)
                }
            }
            .frame(width: 16, height: 16)
            Text(title)
                .foregroundStyle(hovering ? Color.white : (color ?? Color.primary))
            Spacer(minLength: 0)
        }
        .font(.system(size: NSFont.menuFont(ofSize: 0).pointSize))
        .foregroundStyle(hovering ? Color.white : Color.primary)
        // 11 à esquerda: ícone e texto na mesma coluna dos itens comuns do menu
        .padding(.leading, 11)
        .padding(.trailing, 9)
        .frame(height: Self.height)
        // o mesmo destaque azul dos itens comuns ao passar o mouse
        .background(RoundedRectangle(cornerRadius: 4).fill(hovering ? Color.accentColor : .clear))
        .padding(.horizontal, 5)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture(perform: action)
        .accessibilityAddTraits(.isButton)
    }

    /// O item de menu com esta linha; a largura acompanha a do menu.
    @MainActor
    static func item(model: AppModel, content: @escaping (AppModel) -> (title: String, icon: NSImage?, color: Color?),
                     action: @escaping () -> Void) -> NSMenuItem {
        let item = NSMenuItem()
        let view = NSHostingView(rootView: MenuRow(model: model, content: content, action: action))
        // a mesma largura da linha de mídia: mais estreito, o menu encolhia e cortava os números dela
        view.frame = NSRect(x: 0, y: 0, width: MenuMediaRow.size.width, height: height)
        view.autoresizingMask = [.width]
        item.view = view
        return item
    }
}

/// Linha de um app em "Aplicativos": clicar no nome escolhe o app, sem fechar o menu. O submenu
/// (seta na ponta) tem o Mudo. Um item comum com submenu não aceita clique no Mac; desenhado, aceita.
struct AppMenuRow: View {
    @ObservedObject var model: AppModel
    let app: AudioApp

    @State private var hovering = false

    var body: some View {
        let selected = model.selectedBundleID == app.bundleID
        let muted = model.isMuted(app.bundleID)
        // em cinza: aberto, mas ainda sem som
        let text = hovering ? Color.white : !app.hasAudio ? Color.secondary : muted ? Theme.mute : Color.primary
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .opacity(selected ? 1 : 0)
                .frame(width: 16, height: 16)
            Text(app.displayName)
                .lineLimit(1)
            // tocando: o alto-falante da janela (cortado e vermelho no mudo)
            if app.isPlaying {
                MediaIcon(glyph: muted ? .speakerMuted : .speaker, size: 11, color: text)
            }
            Spacer(minLength: 12)
            // só app com som tem o submenu do Mudo
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .opacity(app.hasAudio ? 1 : 0)
        }
        .foregroundStyle(text)
        .font(.system(size: NSFont.menuFont(ofSize: 0).pointSize))
        // 11 à esquerda: ícone e texto na mesma coluna dos itens comuns do menu
        .padding(.leading, 11)
        .padding(.trailing, 9)
        .frame(height: MenuRow.height)
        .background(RoundedRectangle(cornerRadius: 4).fill(hovering ? Color.accentColor : .clear))
        .padding(.horizontal, 5)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture { model.selectedBundleID = app.bundleID }
        .accessibilityAddTraits(.isButton)
    }

    @MainActor
    static func item(model: AppModel, app: AudioApp) -> NSMenuItem {
        let item = NSMenuItem()
        let view = NSHostingView(rootView: AppMenuRow(model: model, app: app))
        view.frame = NSRect(x: 0, y: 0, width: 220, height: MenuRow.height)
        view.autoresizingMask = [.width]
        item.view = view
        guard app.hasAudio else { return item }
        let submenu = NSMenu()
        submenu.addItem(MenuRow.item(model: model, content: { model in
            let muted = model.isMuted(app.bundleID)
            return (T("Mudo", "Mute", "Silenciar"), muted ? NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil) : nil,
                    muted ? Theme.mute : nil)
        }, action: { model.toggleMute(app.bundleID) }))
        item.submenu = submenu
        return item
    }
}
