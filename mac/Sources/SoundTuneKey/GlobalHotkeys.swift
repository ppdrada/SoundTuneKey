import Carbon
import Foundation

/// Atalhos globais pelo Carbon (RegisterEventHotKey): funcionam com qualquer app na frente,
/// inclusive jogos, e não pedem a permissão de Acessibilidade.
final class GlobalHotkeys {
    struct Hotkey {
        let keyCode: UInt32
        let modifiers: UInt32
        /// Segurar a tecla repete a ação (como o volume no Windows).
        let repeats: Bool
        let action: () -> Void
    }

    private var hotkeys: [UInt32: Hotkey] = [:]
    private var refs: [EventHotKeyRef] = []
    private var handler: EventHandlerRef?
    private var repeatTimer: Timer?
    private var heldID: UInt32?

    /// Atalhos que outro programa já usa (registro falhou).
    private(set) var failed: [Hotkey] = []

    init(_ list: [Hotkey]) {
        var types = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
                     EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))]
        InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            let me = Unmanaged<GlobalHotkeys>.fromOpaque(context).takeUnretainedValue()
            me.handle(id: id.id, pressed: GetEventKind(event) == UInt32(kEventHotKeyPressed))
            return noErr
        }, types.count, &types, Unmanaged.passUnretained(self).toOpaque(), &handler)

        for (index, hotkey) in list.enumerated() {
            let id = UInt32(index + 1)
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(hotkey.keyCode, hotkey.modifiers, EventHotKeyID(signature: 0x53544b59, id: id),
                                             GetApplicationEventTarget(), 0, &ref)
            if status == noErr, let ref {
                hotkeys[id] = hotkey
                refs.append(ref)
            } else {
                failed.append(hotkey)
            }
        }
    }

    deinit {
        repeatTimer?.invalidate()
        refs.forEach { UnregisterEventHotKey($0) }
        if let handler { RemoveEventHandler(handler) }
    }

    private func handle(id: UInt32, pressed: Bool) {
        guard let hotkey = hotkeys[id] else { return }
        guard pressed else {
            if heldID == id { stopRepeat() }
            return
        }
        // a repetição do teclado pode mandar "apertou" de novo enquanto segura; o timer já cuida disso
        if heldID == id { return }

        stopRepeat()
        hotkey.action()
        guard hotkey.repeats else { return }
        heldID = id
        // espera um pouco antes de repetir, como a repetição normal do teclado
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
            self?.repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in hotkey.action() }
        }
    }

    private func stopRepeat() {
        repeatTimer?.invalidate()
        repeatTimer = nil
        heldID = nil
    }
}

extension GlobalHotkeys.Hotkey {
    static let commandOption = UInt32(cmdKey | optionKey)
    static let upArrow = UInt32(kVK_UpArrow)
    static let downArrow = UInt32(kVK_DownArrow)
}
