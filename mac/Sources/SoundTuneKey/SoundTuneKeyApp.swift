import SwiftUI

@main
struct SoundTuneKeyApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        Window("Sound Tune Key", id: "main") {
            ContentView(model: model)
        }
        .windowResizability(.contentSize)
    }
}
