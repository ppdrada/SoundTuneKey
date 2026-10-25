import AppKit
import Combine
import SwiftUI

/// Janela + ícone na barra de menus, como a janela + bandeja da versão Windows.
/// Fechar a janela só esconde: o app continua na barra de menus e os atalhos seguem funcionando.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    private let model = AppModel()
    private var window: NSWindow!
    private var statusItem: NSStatusItem!
    private let appsMenu = NSMenu()
    private var selectionWatch: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = makeMainMenu()
        setupWindow()
        setupStatusItem()
        showWindow()
    }

    /// Abrir o app de novo (Finder, Spotlight, Dock) com a janela escondida mostra a janela.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showWindow()
        return false
    }

    // MARK: - Janela

    private func setupWindow() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 411, height: 458),
                          styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Sound Tune Key"
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ContentView(model: model))
        window.delegate = self
        window.center()
    }

    @objc private func showWindow() {
        // com a janela aberta o app aparece no Dock e no ⌘Tab; escondido, só na barra de menus
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
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
        menu.addItem(item("Abrir", #selector(showWindow)))
        let apps = NSMenuItem(title: "Aplicativos", action: nil, keyEquivalent: "")
        apps.submenu = appsMenu
        menu.addItem(apps)
        menu.addItem(item("Atalhos", #selector(showShortcuts)))
        menu.addItem(.separator())
        menu.addItem(item("Sair", #selector(quit)))
        // a lista de apps é montada na hora em que o menu abre, para estar sempre atual
        appsMenu.delegate = self
        statusItem.menu = menu

        // o app pode ser escolhido na janela ou no menu; a dica do ícone acompanha os dois
        selectionWatch = model.$selectedBundleID.receive(on: RunLoop.main).sink { [weak self] _ in self?.updateToolTip() }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === appsMenu else { return }
        menu.removeAllItems()
        model.refresh()

        if model.apps.isEmpty {
            let empty = NSMenuItem(title: "Nenhum app com som", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
            return
        }
        for app in model.apps {
            let entry = item(app.isPlaying ? "\(app.displayName)  🔊" : app.displayName, #selector(selectApp(_:)))
            entry.representedObject = app.bundleID
            entry.state = app.bundleID == model.selectedBundleID ? .on : .off
            menu.addItem(entry)
        }
    }

    @objc private func selectApp(_ sender: NSMenuItem) {
        model.selectedBundleID = sender.representedObject as? String
    }

    /// Como o texto do ícone da bandeja no Windows: mostra qual app está sendo controlado.
    private func updateToolTip() {
        let name = model.selectedApp?.displayName
        statusItem.button?.toolTip = name.map { "Sound Tune Key — \($0)" } ?? "Sound Tune Key"
    }

    @objc private func showShortcuts() {
        let alert = NSAlert()
        alert.messageText = "Sound Tune Key — Atalhos"
        alert.informativeText = Shortcuts.list.map { "\($0.keys)    \($0.action)" }.joined(separator: "\n")
            + "\n\nO volume muda no app escolhido em Aplicativos."
        alert.icon = NSApp.applicationIconImage
        NSApp.activate()
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
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
