// swift-tools-version:5.5
import PackageDescription

// Version is technically not required here, SPM doesn't check
let version = "2.10.1-sakuracord.1"
// Tag is required to point towards the right asset. SPM requires the tag to follow semantic versioning to be able to resolve it.
let tag = "2.10.1-sakuracord.1"
let checksum = "330d4d5fef1d9f83c863af7e333b9f82091d72033f0e046af1bdb19935526452"
let url = "https://github.com/SakuraCordApp/Sparkle/releases/download/\(tag)/Sparkle-for-Swift-Package-Manager.zip"

let package = Package(
    name: "Sparkle",
    platforms: [.macOS("27.0")],
    products: [
        .library(
            name: "Sparkle",
            targets: ["Sparkle"])
    ],
    targets: [
        .binaryTarget(
            name: "Sparkle",
            url: url,
            checksum: checksum
        )
    ]
)
