// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ExecCommuteCoach",
    platforms: [.iOS(.v16)],
    products: [
        .iOSApplication(
            name: "Vocalis",
            targets: ["VocalisApp"],
            bundleIdentifier: "com.alexmohit825.ExecCommuteCoach",
            teamIdentifier: "523MJL63MC",
            displayVersion: "1.0",
            bundleVersion: "1"
        )
    ],
    targets: [
        .executableTarget(
            name: "VocalisApp",
            path: "Sources/VocalisApp"
        ),
        .testTarget(
            name: "VocalisTests",
            dependencies: ["VocalisApp"]
        )
    ]
)
