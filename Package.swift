// swift-tools-version: 5.9
// HanaTime — 花时 · 中国樱花开放预测
// No external dependencies; uses only Apple frameworks.
// Open HanaTime.xcodeproj in Xcode to build and run.

import PackageDescription

let package = Package(
    name: "HanaTime",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "HanaTime", targets: ["HanaTime"])
    ],
    targets: [
        .target(
            name: "HanaTime",
            path: "HanaTime",
            resources: [
                .process("Assets.xcassets"),
                .process("Info.plist"),
            ]
        )
    ]
)
