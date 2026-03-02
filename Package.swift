// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Focus",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "Focus", targets: ["Focus"])
    ],
    targets: [
        .executableTarget(
            name: "Focus",
            path: ".",
            exclude: [
                "AGENTS.md",
                "AppIcon.icns",
                "Info.plist",
                "Makefile",
                "README.md",
            ],
            sources: [
                "FocusApp.swift"
            ]
        )
    ]
)
