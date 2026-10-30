import Foundation
import SwiftUI
import Testing
@testable import Flex

struct SupportTests {
    @Test("Sign in with Apple names join whichever components exist")
    func appleNameComponents() {
        var full = PersonNameComponents()
        full.givenName = "Kevin"
        full.familyName = "Brown"
        #expect(AuthenticationManager.displayName(from: full) == "Kevin Brown")

        var givenOnly = PersonNameComponents()
        givenOnly.givenName = "Kevin"
        #expect(AuthenticationManager.displayName(from: givenOnly) == "Kevin")

        var blank = PersonNameComponents()
        blank.givenName = "  "
        #expect(AuthenticationManager.displayName(from: blank) == nil)
        #expect(AuthenticationManager.displayName(from: nil) == nil)
    }

    @Test("Theme manager maps names to color schemes without persisting when asked not to")
    func themeManager() {
        let manager = ThemeManager(initialTheme: "Dark", persists: false)
        #expect(manager.colorScheme == .dark)
        manager.selectedTheme = "Light"
        #expect(manager.colorScheme == .light)
        manager.selectedTheme = "System"
        #expect(manager.colorScheme == nil)
        #expect(ThemeManager.options == ["Light", "Dark", "System"])
    }

    @Test("Demo mode only activates from the launch environment")
    func demoModeParsing() {
        #expect(DemoMode(environment: [:]) == nil)
        #expect(DemoMode(environment: ["FLEX_DEMO": "0"]) == nil)

        let sample = DemoMode(environment: ["FLEX_DEMO": "1", "FLEX_THEME": "Dark", "FLEX_TAB": "History"])
        #expect(sample?.dataset == .sample)
        #expect(sample?.theme == "Dark")
        #expect(sample?.initialTab == "history")
        #expect(sample?.userName == "Alex")

        let empty = DemoMode(environment: ["FLEX_DEMO": "empty", "FLEX_USER_NAME": "Sam"])
        #expect(empty?.dataset == .empty)
        #expect(empty?.userName == "Sam")
    }

    @Test("Bar types expose readable names")
    func barTypes() {
        #expect(BarType.olympicBarbell.displayName == "Olympic Barbell (45 lb)")
        #expect(BarType.ezCurlBar.shortName == "EZ Curl Bar")
        #expect(BarType.allCases.count == 5)
    }

    @Test("Exercises know when they use a barbell")
    func barbellDetection() {
        #expect(Exercise(name: "Bench Press (Barbell)", bodyPart: "Chest").usesBarbell)
        #expect(Exercise(name: "Curl", bodyPart: "Arms", barType: .ezCurlBar).usesBarbell)
        #expect(!Exercise(name: "Push Up", bodyPart: "Chest").usesBarbell)
        #expect(Exercise(name: "Running", bodyPart: "Cardio").isCardio)
    }

    @Test("Terms of service JSON decodes")
    func termsOfServiceDecodes() throws {
        let url = try #require(Bundle.main.url(forResource: "TermsOfService", withExtension: "json"))
        let terms = try JSONDecoder().decode(TermsOfService.self, from: Data(contentsOf: url))
        #expect(!terms.title.isEmpty)
        #expect(!terms.sections.isEmpty)
        #expect(Set(terms.sections.map { $0.id }).count == terms.sections.count)
    }

    @Test("App links point at the support site")
    func appLinks() {
        #expect(AppLinks.support.host == "kevinbrowncodes.github.io")
        #expect(AppLinks.privacyPolicy.path.hasSuffix("/privacy"))
    }
}
