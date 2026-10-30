import Foundation

/// Public URLs for the app. The support site lives in the `kevinbrowncodes/flex-support` GitHub Pages repo.
enum AppLinks {
    static let support = URL(string: "https://kevinbrowncodes.github.io/flex-support/")!
    static let privacyPolicy = URL(string: "https://kevinbrowncodes.github.io/flex-support/privacy")!
    static let issues = URL(string: "https://github.com/kevinbrowncodes/flex-support/issues")!

    /// The people behind Flex, shown in Settings ▸ About.
    static let creators = "Ashton Krstolic & Kevin Brown"

    /// "1.0.2 (8)"
    static var versionDescription: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
