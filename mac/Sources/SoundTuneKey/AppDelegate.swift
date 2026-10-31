import AppKit
import Combine
import SwiftUI
import UserNotifications

/// Janela + ícone na barra de menus, como a janela + bandeja da versão Windows.
/// Fechar a janela só esconde: o app continua na barra de menus e os atalhos seguem funcionando.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate {
    private let model = AppModel()
    private var window: NSWindow!
    private var statusItem: NSStatusItem!
    private let appsMenu = NSMenu()
    private var selectionWatch: AnyCancellable?
    private var muteWatch: AnyCancellable?
    // escolher e ligar/desligar não fecham o menu (MenuRow); a bolinha acompanha a da janela
    private lazy var startAtLoginItem = MenuRow.item(model: model, content: {
        ("Iniciar com o Mac", RadioDot.menuImage(on: $0.startsAtLogin), nil)
    }, action: { [unowned self] in toggleStartAtLogin() })
    private lazy var osdItem = MenuRow.item(model: model, content: {
        ("Mostrar aviso na tela", RadioDot.menuImage(on: $0.showOsd), nil)
    }, action: { [unowned self] in toggleOsd() })
    private lazy var updateItem = item("Atualizar", #selector(showUpdate), symbol: "arrow.down.circle")
    private lazy var micItem = MenuRow.item(model: model, content: { [unowned self] model in
        let off = model.micMuted == true
        return (off ? "Microfone desligado" : "Microfone ligado",
                symbol(off ? "mic.slash" : "mic", color: off ? NSColor(Theme.mute) : nil), off ? Theme.mute : nil)
    }, action: { [unowned self] in toggleMic() })
    private var aboutWindow: NSWindow?
    private var shortcutsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = makeMainMenu()
        setupWindow()
        setupStatusItem()
        UNUserNotificationCenter.current().delegate = self
        if Updates.justUpdatedTo != nil { showAbout(checking: false) }
        // aberto pelo "Iniciar com o Mac": fica só na barra de menus, como o --tray do Windows
        if LoginItem.launchedHidden {
            NSApp.setActivationPolicy(.accessory)
        } else {
            showWindow()
        }
    }

    /// Abrir o app de novo (Finder, Spotlight, Dock) com a janela escondida mostra a janela.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showWindow()
        return false
    }

    // MARK: - Janela

    private func setupWindow() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 411, height: 440),
                          styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Sound Tune Key"
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ContentView(
            model: model, updates: model.updates,
            openShortcuts: { [weak self] in self?.showShortcuts() },
            openAbout: { [weak self] in self?.showAbout(checking: $0) }))
        window.delegate = self
        window.center()
    }

    @objc private func showWindow() {
        // com a janela aberta o app aparece no Dock e no ⌘Tab; escondido, só na barra de menus
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        model.setShowingMedia(true, by: "janela")
    }

    func windowDidBecomeKey(_ notification: Notification) {
        if notification.object as? NSWindow === window { model.refreshMic() }
    }

    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === window else { return }
        NSApp.setActivationPolicy(.accessory)
        model.setShowingMedia(false, by: "janela")
    }

    // o tempo da música só é lido com o menu aberto (ou a janela visível)
    func menuWillOpen(_ menu: NSMenu) {
        if menu === statusItem.menu {
            model.setShowingMedia(true, by: "menu")
            model.refreshMic()
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        if menu === statusItem.menu { model.setShowingMedia(false, by: "menu") }
    }

    // MARK: - Barra de menus

    private func setupStatusItem() {
        // Ícone novo entra na ponta esquerda dos ícones; com a barra cheia, essa ponta fica atrás
        // do recorte da câmera e o ícone some. Na primeira vez, pede uma posição perto do Wi-Fi
        // (distância da borda direita). Depois vale onde o usuário arrastar com ⌘.
        let positionKey = "NSStatusItem Preferred Position SoundTuneKey"
        if UserDefaults.standard.object(forKey: positionKey) == nil {
            UserDefaults.standard.set(300, forKey: positionKey)
        }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        // com nome fixo, o macOS lembra onde o usuário deixou o ícone (⌘ + arrastar)
        statusItem.autosaveName = "SoundTuneKey"
        statusItem.button?.image = MenuBarIcon.image
        statusItem.button?.toolTip = "Sound Tune Key"

        let menu = NSMenu()
        let about = item("Sound Tune Key", #selector(showAboutFromMenu))
        about.image = NSApp.applicationIconImage.resized(16)
        menu.addItem(about)
        menu.addItem(updateItem)
        menu.addItem(.separator())
        let media = NSMenuItem()
        let mediaView = NSHostingView(rootView: MenuMediaRow(model: model))
        mediaView.frame = NSRect(origin: .zero, size: MenuMediaRow.size)
        media.view = mediaView
        menu.addItem(media)
        menu.addItem(.separator())
        menu.addItem(micItem)
        menu.addItem(item("Abrir", #selector(showWindow), symbol: "macwindow"))
        let apps = NSMenuItem(title: "Aplicativos", action: nil, keyEquivalent: "")
        apps.image = symbol("list.bullet")
        apps.submenu = appsMenu
        menu.addItem(apps)
        menu.addItem(item("Atalhos", #selector(showShortcuts), symbol: "keyboard"))
        menu.addItem(.separator())
        menu.addItem(startAtLoginItem)
        menu.addItem(osdItem)
        menu.addItem(.separator())
        menu.addItem(item("Verificar atualizações...", #selector(showUpdate), symbol: "arrow.clockwise"))
        menu.addItem(item("Sair", #selector(quit), symbol: "power"))
        // a lista de apps é montada na hora em que o menu abre, para estar sempre atual
        appsMenu.delegate = self
        menu.delegate = self
        statusItem.menu = menu

        // o app pode ser escolhido na janela ou no menu; a dica do ícone acompanha os dois
        selectionWatch = model.$selectedBundleID.receive(on: RunLoop.main).sink { [weak self] _ in self?.updateToolTip() }
        // ícone vermelho enquanto o app escolhido estiver no mudo
        muteWatch = model.$selectedBundleID.combineLatest(model.$muted).receive(on: RunLoop.main).sink { [weak self] app, muted in
            self?.statusItem.button?.image = app.map(muted.contains) == true ? MenuBarIcon.muted : MenuBarIcon.image
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === appsMenu else {
            // menu principal: a bolinha acompanha a da janela e os Ajustes do Sistema
            model.refreshStartsAtLogin()
            updateItem.isHidden = model.updates.available == nil
            updateItem.title = "Atualizar para a versão \(model.updates.available ?? "")"
            model.refreshMic()
            micItem.isHidden = model.micMuted == nil
            return
        }
        menu.removeAllItems()
        model.refresh()

        if model.apps.isEmpty {
            let empty = NSMenuItem(title: "Nenhum app com som", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
            return
        }
        for app in model.apps {
            menu.addItem(AppMenuRow.item(model: model, app: app))
        }
    }

    /// Como o texto do ícone da bandeja no Windows: mostra qual app está sendo controlado.
    private func updateToolTip() {
        let name = model.selectedApp?.displayName
        statusItem.button?.toolTip = name.map { "Sound Tune Key — \($0)" } ?? "Sound Tune Key"
    }

    @objc private func showShortcuts() {
        if shortcutsWindow?.isVisible != true {
            shortcutsWindow = DialogWindow(size: ShortcutsView.size) { ShortcutsView(close: $0) }
        }
        NSApp.activate()
        shortcutsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func showAboutFromMenu() { showAbout(checking: false) }
    @objc private func showUpdate() { showAbout(checking: true) }

    /// Sobre e atualizações na mesma janelinha; checking já procura a versão nova.
    private func showAbout(checking: Bool) {
        aboutWindow?.close()
        aboutWindow = DialogWindow(size: AboutView.size) { [model] close in
            AboutView(updates: model.updates, checkOnOpen: checking, close: close)
        }
        NSApp.activate()
        aboutWindow?.makeKeyAndOrderFront(nil)
    }

    private func toggleOsd() { model.showOsd.toggle() }
    private func toggleMic() { model.toggleMic() }

    // clicar na notificação de versão nova abre a janela de atualizar
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await MainActor.run { showAbout(checking: true) }
    }

    private func toggleStartAtLogin() {
        model.setStartsAtLogin(!model.startsAtLogin)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func item(_ title: String, _ action: Selector, symbol name: String? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        if let name { item.image = symbol(name) }
        return item
    }

    /// Ícones do menu com os símbolos do próprio macOS.
    private func symbol(_ name: String, color: NSColor? = nil) -> NSImage? {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        guard let color else { return image }
        return image?.withSymbolConfiguration(.init(paletteColors: [color]))
    }

    // MARK: - Menu do app (⌘W fecha a janela, ⌘Q sai)

    private func makeMainMenu() -> NSMenu {
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Sair do Sound Tune Key", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        let windowMenu = NSMenu(title: "Janela")
        windowMenu.addItem(NSMenuItem(title: "Fechar", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))

        let main = NSMenu()
        for submenu in [appMenu, windowMenu] {
            let entry = NSMenuItem()
            entry.submenu = submenu
            main.addItem(entry)
        }
        return main
    }
}

private extension NSImage {
    func resized(_ side: CGFloat) -> NSImage {
        NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            self.draw(in: rect)
            return true
        }
    }
}
