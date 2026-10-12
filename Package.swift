// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ExecCommuteCoach",
    platforms: [.iOS(.v16)],
    products: [
        .executable(
            name: "Vocalis",
            targets: ["VocalisApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "VocalisApp",
            path: "Sources/VocalisApp"
        )
        .testTarget(
            name: "VocalisTests",
            dependencies: ["VocalisApp"]
        )
