import AppKit
import AVFoundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

// Vídeo de demonstração do README, montado com as telas de verdade do app (AppModel no modo
// demonstração): nada é gravado da tela e nada toca de verdade. Cursor, cliques, legendas,
// barra de menus e moldura da janela são desenhados por cima.
// Uso: mac/Demo/make-video.sh (gera docs/demo/demo-pt e demo-en, em .mp4 e .gif).

@main
enum MakeVideo {
    static func main() {
        MainActor.assumeIsolated {
            _ = NSApplication.shared
            NSApp.setActivationPolicy(.prohibited)
            let repo = URL(fileURLWithPath: CommandLine.arguments[1])
            let lang = CommandLine.arguments[2]
            Recorder(repo: repo, english: lang == "en").run(to: repo.appendingPathComponent("docs/demo/demo-\(lang)"))
        }
    }
}

// MARK: - Roteiro

private let spotify = "com.spotify.client", chrome = "com.google.Chrome", vlc = "org.videolan.vlc", music = "com.apple.Music"

private struct Caption: Equatable {
    var keys: String?
    var text: String
}

/// O que está na tela num instante.
private struct DemoState {
    var selected = chrome
    var volumes: [String: Float] = [spotify: 0.8, chrome: 0.52, vlc: 0.94, music: 1]
    var muted: Set<String> = []
    var playing = true
    var position = 83.0
    var duration = 214.0
    var menuOpen = false
    var submenuOpen = false
    var osd: Osd.Content?
    var osdAt = -10.0
    var caption: Caption?
    var captionAt = 0.0
    var endAt: Double?
    var micMuted = false
}

@MainActor
private final class Recorder {
    static let canvas = NSSize(width: 960, height: 600)
    static let fps = 30.0
    static let length = 36.6

    let english: Bool
    let iconURL: URL
    let model: AppModel
    let apps: [AudioApp]
    var state = DemoState()
    var events: [(time: Double, apply: (inout DemoState) -> Void)] = []
    var cursorKeys: [(time: Double, point: CGPoint)] = []
    var clicks: [Double] = []
    /// "Câmera": centro e zoom do quadro ao longo do tempo (1 = tela inteira).
    var cameraKeys: [(time: Double, center: CGPoint, zoom: CGFloat)] = []

    // posições na tela (pontos do quadro); a janela começa em (56, 60) com 28 de barra de título
    static let windowOrigin = CGPoint(x: 56, y: 60)
    static let content = CGPoint(x: 56, y: 88)
    static let menuOrigin = CGPoint(x: 640, y: 26)
    static let menuBarIcon = CGPoint(x: 781, y: 12)

    // peças da cena
    let root = Flipped(frame: NSRect(origin: .zero, size: Recorder.canvas))
    var window: NSWindow!
    var menu: Flipped!
    var submenu: Flipped!
    var appsRowY: CGFloat = 0
    var appsRowFrame = NSRect.zero
    var appsRowHighlight: NSHostingView<NativeRow>!
    let osdView = NSHostingView(rootView: AnyView(EmptyView()))
    let captionView = NSHostingView(rootView: CaptionView(caption: nil, opacity: 0))
    let endView = NSHostingView(rootView: AnyView(EmptyView()))
    let cursor = NSImageView()
    let ring = NSHostingView(rootView: Ring(progress: 1))

    init(repo: URL, english: Bool) {
        self.english = english
        Lang.shared.code = english ? .en : .pt // as telas do app no idioma do vídeo
        iconURL = repo.appendingPathComponent("assets/icon/icon.png")
        func icon(_ path: String) -> NSImage? {
            FileManager.default.fileExists(atPath: path) ? NSWorkspace.shared.icon(forFile: path) : nil
        }
        apps = [
            AudioApp(bundleID: spotify, displayName: "Spotify", icon: icon("/Applications/Spotify.app"), isPlaying: true, processes: []),
            AudioApp(bundleID: chrome, displayName: "Google Chrome", icon: icon("/Applications/Google Chrome.app"), isPlaying: false, processes: []),
            AudioApp(bundleID: vlc, displayName: "VLC", icon: icon("/Applications/VLC.app"), isPlaying: true, processes: []),
            AudioApp(bundleID: music, displayName: english ? "Music" : "Música", icon: icon("/System/Applications/Music.app"), isPlaying: false, processes: []),
        ]
        model = AppModel(demoApps: apps)
        buildScene() // antes do roteiro: ele usa a posição do item "Aplicativos" no menu
        writeScript()
    }

    private func t(_ pt: String, _ en: String) -> String { english ? en : pt }

    private func caption(_ time: Double, _ pt: String, _ en: String, keys: String? = nil) {
        let text = t(pt, en)
        events.append((time, { $0.caption = Caption(keys: keys, text: text); $0.captionAt = time }))
    }

    private func at(_ time: Double, _ apply: @escaping (inout DemoState) -> Void) { events.append((time, apply)) }

    private func move(_ time: Double, _ point: CGPoint) { cursorKeys.append((time, point)) }

    private func click(_ time: Double, _ apply: @escaping (inout DemoState) -> Void) {
        clicks.append(time)
        at(time, apply)
    }

    /// Segurar o atalho de volume: 1% a cada 0,06 s, com o aviso na tela.
    private func holdVolume(from start: Double, _ from: Int, to: Int) {
        let step = to > from ? 1 : -1
        for (i, value) in stride(from: from + step, through: to, by: step).enumerated() {
            at(start + Double(i) * 0.06) { st in
                st.volumes[st.selected] = Float(value) / 100
                st.muted.remove(st.selected)
                st.osd = .volume(app: "Spotify", volume: value, muted: false)
                st.osdAt = start + Double(i) * 0.06
            }
        }
    }

    private func osdVolume(_ st: inout DemoState, _ time: Double) {
        let volume = Int(((st.volumes[st.selected] ?? 1) * 100).rounded())
        st.osd = .volume(app: "Spotify", volume: volume, muted: st.muted.contains(st.selected))
        st.osdAt = time
    }

    private func camera(_ time: Double, _ center: CGPoint, zoom: CGFloat) { cameraKeys.append((time, center, zoom)) }

    private func writeScript() {
        let c = Self.content
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: c.x + x, y: c.y + y) }
        let spotifyRow = p(150, 49), playButton = p(205, 336), nextButton = p(291, 336), speaker = p(24, 380), mic = p(286, 423)
        func timeThumb(_ fraction: Double) -> CGPoint { p(70 + 271 * fraction, 300) }
        let whole = CGPoint(x: Self.canvas.width / 2, y: Self.canvas.height / 2)

        camera(0, whole, zoom: 1)
        caption(0, "Controle o som de um app só, sem sair do jogo", "Control one app's sound without leaving your game")
        move(0, CGPoint(x: 700, y: 330))
        move(1.5, spotifyRow)
        click(1.8) { $0.selected = spotify }
        caption(1.9, "Escolha o app na lista", "Pick the app in the list")

        // volume: perto da barra de volume e do aviso na tela
        camera(2.9, whole, zoom: 1)
        camera(3.6, CGPoint(x: 440, y: 330), zoom: 1.25)
        caption(3.2, "Diminui só o volume do Spotify", "Turns down only Spotify", keys: "⌘ ⌥ ↓")
        move(3.4, CGPoint(x: 560, y: 240))
        holdVolume(from: 3.7, 80, to: 45)
        caption(6.6, "Aumenta, segurando a tecla", "Turns it up, hold to repeat", keys: "⌘ ⌥ ↑")
        holdVolume(from: 7.0, 45, to: 65)

        // mudo: bem perto do alto-falante
        camera(8.8, CGPoint(x: 440, y: 330), zoom: 1.25)
        camera(9.6, CGPoint(x: 250, y: 430), zoom: 2)
        caption(9.2, "Clique no alto-falante para deixar mudo", "Click the speaker to mute")
        move(10.0, speaker)
        click(10.2) { st in st.muted.insert(st.selected); self.osdVolume(&st, 10.2) }
        click(11.5) { st in st.muted.remove(st.selected); self.osdVolume(&st, 11.5) }
        move(11.7, speaker) // parado no botão até o segundo clique

        // botões de mídia e barra de tempo
        camera(12.2, CGPoint(x: 250, y: 430), zoom: 2)
        camera(12.9, CGPoint(x: 262, y: 410), zoom: 1.8)
        caption(12.5, "Pausa e continua a música", "Pause and resume")
        move(13.1, playButton)
        click(13.3) { $0.playing = false }
        click(14.5) { $0.playing = true }
        move(14.7, playButton)

        caption(15.4, "Arraste para pular na música", "Drag to jump in the track")
        move(16.2, timeThumb(0.45))
        clicks.append(16.3)
        for i in 0...24 {
            let time = 16.4 + Double(i) * 0.05, fraction = 0.45 + (0.8 - 0.45) * Double(i) / 24
            move(time, timeThumb(fraction))
            at(time) { $0.position = $0.duration * fraction }
        }

        caption(18.2, "Próxima música", "Next track", keys: "⏭")
        move(18.9, nextButton)
        click(19.1) { $0.position = 0; $0.duration = 187 }

        // microfone: o ícone do rodapé e o aviso na tela
        camera(19.8, CGPoint(x: 262, y: 410), zoom: 1.8)
        camera(20.5, CGPoint(x: 530, y: 440), zoom: 1.7)
        caption(20.2, "Liga e desliga o microfone do Mac", "Mutes and unmutes the Mac's microphone", keys: "⌃ ⌥ V")
        move(20.9, mic)
        click(21.1) { $0.micMuted = true; $0.osd = .mic(muted: true); $0.osdAt = 21.1 }
        click(22.4) { $0.micMuted = false; $0.osd = .mic(muted: false); $0.osdAt = 22.4 }
        move(22.6, mic)

        // menu da barra: primeiro a tela toda, depois perto do menu
        let o = 3.3 // o resto do roteiro começa depois do microfone
        camera(23.1, CGPoint(x: 530, y: 440), zoom: 1.7)
        camera(23.8, whole, zoom: 1)
        caption(20.1 + o, "Tudo também pelo ícone da barra de menus", "Everything from the menu bar icon too")
        move(20.9 + o, Self.menuBarIcon)
        click(21.1 + o) { $0.menuOpen = true }
        camera(21.3 + o, whole, zoom: 1)
        camera(22.0 + o, CGPoint(x: 660, y: 222), zoom: 1.35)
        move(22.4 + o, CGPoint(x: Self.menuOrigin.x + 120, y: appsRowY))
        at(22.5 + o) { $0.submenuOpen = true }
        caption(22.6 + o, "Troque o app sem abrir a janela", "Switch apps without opening the window")
        // linha i do submenu fica em appsRowY + 22 * i (Spotify, Chrome, VLC, Música)
        let submenuX = Self.menuOrigin.x - 216
        move(23.2 + o, CGPoint(x: submenuX + 150, y: appsRowY))
        move(23.8 + o, CGPoint(x: submenuX + 90, y: appsRowY + 44))
        click(24.1 + o) { $0.selected = vlc }
        caption(24.3 + o, "O menu fica aberto: errou, é só trocar", "The menu stays open, so a wrong pick is easy to fix")
        move(25.3 + o, CGPoint(x: submenuX + 90, y: appsRowY))
        click(25.6 + o) { $0.selected = spotify }

        at(27.0 + o) { $0.menuOpen = false; $0.submenuOpen = false }
        camera(26.8 + o, CGPoint(x: 660, y: 222), zoom: 1.35)
        camera(27.4 + o, whole, zoom: 1)
        move(27.4 + o, CGPoint(x: 640, y: 420))
        caption(27.2 + o, "Atalhos de mídia com qualquer janela na frente", "Media shortcuts over any window, even games",
                keys: "⌃ ⌥ P  ·  ⌃ ⌥ →  ·  ⌃ ⌥ ←")
        at(28.0 + o) { $0.position = 0; $0.duration = 201 }

        at(29.6 + o) { $0.endAt = 29.6 + o }
        events.sort { $0.time < $1.time }
        cursorKeys.sort { $0.time < $1.time }
        clicks.sort()
        cameraKeys.sort { $0.time < $1.time }
    }

    // MARK: - Cena

    private func buildScene() {
        window = NSWindow(contentRect: NSRect(origin: .zero, size: Self.canvas), styleMask: [.borderless],
                          backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = root

        add(NSHostingView(rootView: Desktop(english: english)), NSRect(origin: .zero, size: Self.canvas))
        let windowView = NSHostingView(rootView: WindowChrome(model: model))
        add(windowView, NSRect(origin: Self.windowOrigin, size: NSSize(width: 411, height: 468)))

        buildMenu()
        buildSubmenu()

        add(osdView, NSRect(x: 640 - Osd.size.width / 2, y: 440, width: Osd.size.width, height: Osd.size.height))
        add(captionView, NSRect(x: 0, y: 540, width: Self.canvas.width, height: 50))
        add(ring, NSRect(x: 0, y: 0, width: 36, height: 36))
        cursor.image = NSCursor.arrow.image
        add(cursor, NSRect(origin: .zero, size: NSCursor.arrow.image.size))
        add(endView, NSRect(origin: .zero, size: Self.canvas))
    }

    private func add(_ view: NSView, _ frame: NSRect, to parent: NSView? = nil) {
        // as linhas do menu crescem com o menu (autoresizing); aqui a moldura já vem certa
        view.autoresizingMask = []
        view.frame = frame
        (parent ?? root).addSubview(view)
    }

    /// O menu da barra com as linhas de verdade (mídia, microfone, bolinhas) e as comuns desenhadas igual.
    private func buildMenu() {
        menu = Flipped()
        var y: CGFloat = 5
        let width: CGFloat = 260
        var rows: [(NSView, CGFloat)] = []
        func native(_ symbol: String?, _ title: String, chevron: Bool = false, appIcon: Bool = false) -> NSHostingView<NativeRow> {
            NSHostingView(rootView: NativeRow(symbol: symbol, title: title, chevron: chevron, appIcon: appIcon ? NSImage(contentsOf: iconURL) : nil))
        }
        rows.append((native(nil, "Sound Tune Key", appIcon: true), 22))
        rows.append((SeparatorView.make(), 9))
        rows.append((NSHostingView(rootView: MenuMediaRow(model: model)), MenuMediaRow.size.height))
        rows.append((SeparatorView.make(), 9))
        rows.append((MenuRow.item(model: model, content: { model in
            let off = model.micMuted == true
            return (off ? "Microfone desligado" : "Microfone ligado",
                    NSImage(systemSymbolName: off ? "mic.slash" : "mic", accessibilityDescription: nil), off ? Theme.mute : nil)
        }, action: {}).view!, 22))
        rows.append((native("macwindow", "Abrir"), 22))
        appsRowHighlight = native("list.bullet", "Aplicativos", chevron: true)
        rows.append((appsRowHighlight, 22))
        rows.append((native("keyboard", "Atalhos"), 22))
        rows.append((SeparatorView.make(), 9))
        rows.append((MenuRow.item(model: model, content: { ("Iniciar com o Mac", RadioDot.menuImage(on: $0.startsAtLogin), nil) },
                                  action: {}).view!, 22))
        rows.append((MenuRow.item(model: model, content: { ("Mostrar aviso na tela", RadioDot.menuImage(on: $0.showOsd), nil) },
                                  action: {}).view!, 22))
        rows.append((SeparatorView.make(), 9))
        rows.append((native("arrow.clockwise", "Verificar atualizações..."), 22))
        rows.append((native("power", "Sair"), 22))

        let height = rows.reduce(10) { $0 + $1.1 }
        add(NSHostingView(rootView: MenuBackground()), NSRect(x: 0, y: 0, width: width, height: height), to: menu)
        for (view, rowHeight) in rows {
            if view === appsRowHighlight {
                appsRowFrame = NSRect(x: 0, y: y, width: width, height: rowHeight)
                appsRowY = Self.menuOrigin.y + y + rowHeight / 2
            }
            add(view, NSRect(x: 0, y: y, width: width, height: rowHeight), to: menu)
            y += rowHeight
        }
        add(menu, NSRect(origin: Self.menuOrigin, size: NSSize(width: width, height: height)))
    }

    /// Submenu "Aplicativos": as linhas de app de verdade (clicar escolhe, a seta abre o Mudo).
    private func buildSubmenu() {
        submenu = Flipped()
        let width: CGFloat = 220, height = CGFloat(apps.count) * 22 + 10
        add(NSHostingView(rootView: MenuBackground()), NSRect(x: 0, y: 0, width: width, height: height), to: submenu)
        for (i, app) in apps.enumerated() {
            add(AppMenuRow.item(model: model, app: app).view!, NSRect(x: 0, y: 5 + CGFloat(i) * 22, width: width, height: 22), to: submenu)
        }
        add(submenu, NSRect(x: Self.menuOrigin.x - width + 4, y: appsRowY - 16, width: width, height: height))
    }

    // MARK: - Quadros

    func run(to base: URL) {
        let frames = Int(Self.length * Self.fps)
        let video = VideoWriter(url: base.appendingPathExtension("mp4"), size: Self.canvas)
        let gif = GifWriter(url: base.appendingPathExtension("gif"), frames: frames / 3)
        var next = 0
        var lastSelected = ""
        var lastHighlight: Bool?
        for frame in 0..<frames {
            let time = Double(frame) / Self.fps
            while next < events.count, events[next].time <= time {
                events[next].apply(&state)
                next += 1
            }
            if state.playing, state.selected == spotify, !isDragging(time) {
                state.position = min(state.position + 1 / Self.fps, state.duration)
            }

            if state.selected != lastSelected {
                model.selectedBundleID = state.selected
                lastSelected = state.selected
            }
            let media: MediaPlayer.Status? = switch state.selected {
            case spotify: .init(isPlaying: state.playing, position: state.position, duration: state.duration)
            case vlc: .init(isPlaying: true, position: 512 + time, duration: 1380)
            default: nil
            }
            model.setDemo(volumes: state.volumes, muted: state.muted, media: media, startsAtLogin: true, micMuted: state.micMuted)

            menu.isHidden = !state.menuOpen
            submenu.isHidden = !state.submenuOpen
            if lastHighlight != state.submenuOpen {
                appsRowHighlight.rootView = NativeRow(symbol: "list.bullet", title: "Aplicativos", chevron: true,
                                                      appIcon: nil, highlighted: state.submenuOpen)
                lastHighlight = state.submenuOpen
            }

            let osdAge = time - state.osdAt
            osdView.rootView = AnyView(state.osd.map { OsdCard(content: $0) })
            osdView.alphaValue = osdAge < 1.2 ? 1 : max(0, 1 - (osdAge - 1.2) / 0.3)
            captionView.rootView = CaptionView(caption: state.caption, opacity: min(1, (time - state.captionAt) / 0.25))
            if let endAt = state.endAt {
                endView.rootView = AnyView(EndCard(icon: NSImage(contentsOf: iconURL), english: english))
                endView.alphaValue = min(1, (time - endAt) / 0.5)
            }

            let point = cursorPoint(time)
            cursor.setFrameOrigin(point)
            let lastClick = clicks.last { $0 <= time } ?? -10
            ring.isHidden = time - lastClick > 0.35
            ring.rootView = Ring(progress: (time - lastClick) / 0.35)
            ring.setFrameOrigin(CGPoint(x: point.x - 18, y: point.y - 18))
            cursor.isHidden = state.endAt != nil

            // o SwiftUI atualiza as telas no próximo giro do runloop
            RunLoop.main.run(until: Date().addingTimeInterval(0.004))
            root.layoutSubtreeIfNeeded()
            captionView.isHidden = true
            guard let scene = snapshot(root) else { continue }
            captionView.isHidden = false
            guard let image = zoomed(scene, camera: cameraAt(time), caption: snapshot(captionView)) else { continue }
            video.append(image, at: frame, fps: Self.fps)
            if frame % 3 == 0 { gif.append(image, delay: 3 / Self.fps) }
        }
        video.finish()
        gif.finish()
    }

    private func snapshot(_ view: NSView) -> CGImage? {
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return nil }
        view.cacheDisplay(in: view.bounds, to: rep)
        return rep.cgImage
    }

    /// Recorta a cena em volta do centro da câmera e amplia; a legenda vai por cima, sem zoom.
    private func zoomed(_ scene: CGImage, camera: (center: CGPoint, zoom: CGFloat), caption: CGImage?) -> CGImage? {
        let scale = CGFloat(scene.width) / Self.canvas.width
        let size = CGSize(width: Self.canvas.width / camera.zoom, height: Self.canvas.height / camera.zoom)
        // o recorte nunca sai da tela
        let x = min(max(camera.center.x - size.width / 2, 0), Self.canvas.width - size.width)
        let y = min(max(camera.center.y - size.height / 2, 0), Self.canvas.height - size.height)
        guard let crop = scene.cropping(to: CGRect(x: x * scale, y: y * scale, width: size.width * scale, height: size.height * scale)),
              let context = CGContext(data: nil, width: scene.width, height: scene.height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        context.interpolationQuality = .high
        context.draw(crop, in: CGRect(x: 0, y: 0, width: scene.width, height: scene.height))
        if let caption {
            // a legenda fica em y = 540 (de cima); no CGContext a origem é embaixo
            let frame = captionView.frame
            context.draw(caption, in: CGRect(x: frame.minX * scale, y: (Self.canvas.height - frame.maxY) * scale,
                                             width: frame.width * scale, height: frame.height * scale))
        }
        return context.makeImage()
    }

    /// Câmera entre os pontos do roteiro, com aceleração suave.
    private func cameraAt(_ time: Double) -> (center: CGPoint, zoom: CGFloat) {
        guard let after = cameraKeys.firstIndex(where: { $0.time >= time }) else { return (cameraKeys.last!.center, cameraKeys.last!.zoom) }
        guard after > 0 else { return (cameraKeys[0].center, cameraKeys[0].zoom) }
        let a = cameraKeys[after - 1], b = cameraKeys[after]
        let linear = (time - a.time) / (b.time - a.time)
        let e = CGFloat(linear * linear * (3 - 2 * linear))
        return (CGPoint(x: a.center.x + (b.center.x - a.center.x) * e, y: a.center.y + (b.center.y - a.center.y) * e),
                a.zoom + (b.zoom - a.zoom) * e)
    }

    private func isDragging(_ time: Double) -> Bool { time >= 16.3 && time <= 17.7 }

    /// Cursor entre os pontos do roteiro, com aceleração suave.
    private func cursorPoint(_ time: Double) -> CGPoint {
        guard let after = cursorKeys.firstIndex(where: { $0.time >= time }) else { return cursorKeys.last!.point }
        guard after > 0 else { return cursorKeys[0].point }
        let a = cursorKeys[after - 1], b = cursorKeys[after]
        let linear = (time - a.time) / (b.time - a.time)
        let eased = linear * linear * (3 - 2 * linear)
        return CGPoint(x: a.point.x + (b.point.x - a.point.x) * eased, y: a.point.y + (b.point.y - a.point.y) * eased)
    }
}

// MARK: - Peças desenhadas

private final class Flipped: NSView {
    override var isFlipped: Bool { true }
}

/// Fundo de mesa e barra de menus do Mac, com o ícone do Sound Tune Key perto do Wi-Fi.
private struct Desktop: View {
    let english: Bool

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [Color(white: 0.42), Color(white: 0.30), Color(white: 0.18)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            HStack(spacing: 16) {
                Image(systemName: "applelogo")
                Text("Sound Tune Key").fontWeight(.semibold)
                Spacer()
                Image(nsImage: MenuBarIcon.image).renderingMode(.template)
                Image(systemName: "wifi")
                Image(systemName: "battery.75percent")
                Text(english ? "Fri 2:32 PM" : "sex. 14:32")
            }
            .font(.system(size: 13))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 24)
            .background(Color.black.opacity(0.35))
        }
    }
}

/// Moldura da janela (barra de título como a do app: só o botão de fechar ativo) com a janela de verdade.
private struct WindowChrome: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle().fill(Color(red: 1, green: 0.37, blue: 0.34)).frame(width: 12, height: 12)
                Circle().fill(Color.white.opacity(0.2)).frame(width: 12, height: 12)
                Circle().fill(Color.white.opacity(0.2)).frame(width: 12, height: 12)
                Text("Sound Tune Key")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .padding(.leading, 12)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(Color(red: 0.17, green: 0.17, blue: 0.18))
            ContentView(model: model, updates: model.updates)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.12)))
    }
}

/// Item comum do menu, desenhado igual ao do macOS (o vídeo não tem como desenhar um NSMenu de verdade).
struct NativeRow: View {
    let symbol: String?
    let title: String
    var chevron = false
    var appIcon: NSImage?
    var highlighted = false

    var body: some View {
        HStack(spacing: 6) {
            Group {
                if let appIcon {
                    Image(nsImage: appIcon).resizable()
                } else if let symbol {
                    Image(systemName: symbol)
                }
            }
            .frame(width: 16, height: 16)
            Text(title)
            Spacer(minLength: 0)
            if chevron { Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold)) }
        }
        .font(.system(size: NSFont.menuFont(ofSize: 0).pointSize))
        .foregroundStyle(highlighted ? Color.white : Color.primary)
        .padding(.leading, 11)
        .padding(.trailing, 9)
        .frame(height: 22)
        .background(RoundedRectangle(cornerRadius: 4).fill(highlighted ? Color.accentColor : .clear))
        .padding(.horizontal, 5)
        .environment(\.colorScheme, .dark)
    }
}

private struct MenuBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(red: 0.16, green: 0.16, blue: 0.18).opacity(0.97))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.15)))
    }
}

private enum SeparatorView {
    @MainActor static func make() -> NSView {
        NSHostingView(rootView: Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1).padding(.horizontal, 14))
    }
}

/// Legenda embaixo, com o atalho num "teclado" ao lado.
private struct CaptionView: View {
    let caption: Caption?
    let opacity: Double

    var body: some View {
        HStack {
            Spacer()
            if let caption {
                HStack(spacing: 12) {
                    if let keys = caption.keys {
                        Text(keys)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.18)))
                    }
                    Text(caption.text).font(.system(size: 19, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                .background(Capsule().fill(Color.black.opacity(0.6)))
                .opacity(opacity)
            }
            Spacer()
        }
    }
}

/// Anel que cresce e some no lugar do clique.
private struct Ring: View {
    let progress: Double

    var body: some View {
        Circle()
            .strokeBorder(Color.white.opacity(0.8 * (1 - progress)), lineWidth: 2)
            .frame(width: 12 + 24 * progress, height: 12 + 24 * progress)
            .frame(width: 36, height: 36)
    }
}

private struct EndCard: View {
    let icon: NSImage?
    let english: Bool

    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.12)
            VStack(spacing: 12) {
                if let icon { Image(nsImage: icon).resizable().frame(width: 96, height: 96) }
                Text("Sound Tune Key").font(.system(size: 34, weight: .bold))
                Text(english ? "Free · Windows and macOS" : "Grátis · Windows e macOS").font(.system(size: 18))
                Text("github.com/ppdrada/SoundTuneKey").font(.system(size: 15)).foregroundStyle(Theme.mutedText)
            }
            .foregroundStyle(Theme.text)
        }
    }
}

// MARK: - Arquivos

/// MP4 em H.264 com o AVFoundation do macOS (sem instalar nada).
@MainActor
private final class VideoWriter {
    let writer: AVAssetWriter
    let input: AVAssetWriterInput
    let adaptor: AVAssetWriterInputPixelBufferAdaptor
    let pixels: (width: Int, height: Int)

    init(url: URL, size: NSSize) {
        try? FileManager.default.removeItem(at: url)
        pixels = (Int(size.width * 2), Int(size.height * 2))
        writer = try! AVAssetWriter(outputURL: url, fileType: .mp4)
        input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: pixels.width,
            AVVideoHeightKey: pixels.height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 2_500_000],
        ])
        adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: pixels.width,
            kCVPixelBufferHeightKey as String: pixels.height,
        ])
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
    }

    func append(_ image: CGImage, at frame: Int, fps: Double) {
        while !input.isReadyForMoreMediaData { RunLoop.main.run(until: Date().addingTimeInterval(0.002)) }
        var buffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
        guard let buffer else { return }
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: pixels.width, height: pixels.height,
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: pixels.width, height: pixels.height))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: CMTimeScale(fps)))
    }

    func finish() {
        input.markAsFinished()
        var done = false
        writer.finishWriting { done = true }
        while !done { RunLoop.main.run(until: Date().addingTimeInterval(0.01)) }
    }
}

/// GIF para aparecer direto no README: metade do tamanho e 10 quadros por segundo, para ficar leve.
@MainActor
private final class GifWriter {
    let destination: CGImageDestination

    init(url: URL, frames: Int) {
        try? FileManager.default.removeItem(at: url)
        destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, frames, nil)!
        CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
    }

    func append(_ image: CGImage, delay: Double) {
        let width = image.width / 2, height = image.height / 2
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        CGImageDestinationAddImage(destination, context.makeImage()!,
                                   [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delay]] as CFDictionary)
    }

    func finish() {
        precondition(CGImageDestinationFinalize(destination), "não foi possível gravar o GIF")
    }
}
