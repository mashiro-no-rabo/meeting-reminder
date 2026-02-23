// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MeetingReminder",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MeetingReminder",
            path: "Sources/MeetingReminder",
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/Resources/Info.plist",
                ]),
            ]
        ),
    ]
)
