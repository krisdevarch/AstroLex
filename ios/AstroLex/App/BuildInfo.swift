import Foundation

/// Version and build number as shown on screen, so every TestFlight build is identifiable
/// in screenshots and bug reports. The build number maps to the git tag `tf/<build>`.
enum BuildInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }

    static var label: String { "v\(version) (\(build))" }
}
