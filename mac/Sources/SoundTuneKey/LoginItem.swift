import AppKit
import ServiceManagement

/// "Iniciar com o Mac": o app entra nos Itens de Início (Ajustes do Sistema → Geral) e,
/// aberto assim, começa escondido na barra de menus, como o --tray do Windows.
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    /// O macOS pode exigir que o usuário libere o item em Ajustes do Sistema.
    static var needsApproval: Bool { SMAppService.mainApp.status == .requiresApproval }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    static func openSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    /// Verdadeiro se o app foi aberto pelo login (ou com --tray, útil para testar).
    /// Só vale durante a abertura: o macOS marca o evento de "abrir app" de quem inicia com o login.
    @MainActor static var launchedHidden: Bool {
        if CommandLine.arguments.contains("--tray") { return true }
        let event = NSAppleEventManager.shared().currentAppleEvent
        return event?.eventID == kAEOpenApplication
            && event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }
}
