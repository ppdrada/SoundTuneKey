// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SoundTuneKey",
    // A lista de processos com áudio do Core Audio só existe a partir do macOS 14.2.
    platforms: [.macOS("14.2")],
    targets: [
        .executableTarget(name: "SoundTuneKey", swiftSettings: [.swiftLanguageMode(.v5)])
    ]
)
