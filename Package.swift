// swift-tools-version:5.9
// NOTE: The iOS app / TestFlight build is produced from project.yml (XcodeGen),
// not from this manifest. This manifest is kept only for source organisation.
import PackageDescription

let package = Package(
    name: "ExecCommuteCoach",
    platforms: [.iOS(.v16)],
    targets: [
        .executableTarget(
            name: "VocalisApp",
            path: "Sources/VocalisApp",
            exclude: ["Info.plist", "Assets.xcassets"]
        ),
        .testTarget(
            name: "VocalisTests",
            dependencies: ["VocalisApp"]
        )
    ]
)
