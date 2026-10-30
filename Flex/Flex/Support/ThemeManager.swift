import SwiftUI

@Observable
class ThemeManager {
    static let options = ["Light", "Dark", "System"]

    private let persists: Bool

    var selectedTheme: String {
        didSet {
            guard persists else { return }
            UserDefaults.standard.set(selectedTheme, forKey: "selectedTheme")
        }
    }

    var colorScheme: ColorScheme? {
        switch selectedTheme {
        case "Light":
            return .light
        case "Dark":
            return .dark
        default:
            return nil
        }
    }

    /// - Parameters:
    ///   - initialTheme: overrides the stored theme (used by demo/UI-test launches).
    ///   - persists: when false, changes are kept in memory only.
    init(initialTheme: String? = nil, persists: Bool = true) {
        self.persists = persists
        self.selectedTheme = initialTheme ?? UserDefaults.standard.string(forKey: "selectedTheme") ?? "System"
    }
}
