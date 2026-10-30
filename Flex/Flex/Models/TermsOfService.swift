import Foundation

struct TermsOfService: Codable {
    let title: String
    let lastUpdated: String
    let introduction: [String]
    let sections: [TermsSection]
}

struct TermsSection: Codable, Identifiable {
    let number: String
    let title: String
    let content: String
    
    var id: String { number }
}
