// swift-tools-version:5.5
import PackageDescription

// Version is technically not required here, SPM doesn't check
let version = "2.10.0-sakuracord.1"
// Tag is required to point towards the right asset. SPM requires the tag to follow semantic versioning to be able to resolve it.
let tag = "2.10.0-sakuracord.1"
let checksum = "584394bad0e5c5c363459e19e4aac43d51fdf3b08f4eb588933e2e88336284a7"
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
