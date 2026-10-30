import Foundation

enum BarType: String, Codable, CaseIterable {
    case olympicBarbell
    case womensBarbell
    case ezCurlBar
    case trapBar
    case safetySquatBar

    /// Bar weight in pounds.
    var weight: Double {
        switch self {
        case .olympicBarbell: return 45
        case .womensBarbell: return 35
        case .ezCurlBar: return 20
        case .trapBar: return 45
        case .safetySquatBar: return 60
        }
    }

    var shortName: String {
        switch self {
        case .olympicBarbell: return "Olympic Bar"
        case .womensBarbell: return "Women's Bar"
        case .ezCurlBar: return "EZ Curl Bar"
        case .trapBar: return "Trap Bar"
        case .safetySquatBar: return "Safety Squat Bar"
        }
    }

    var displayName: String {
        switch self {
        case .olympicBarbell: return "Olympic Barbell (\(Int(weight)) lb)"
        case .womensBarbell: return "Women's Barbell (\(Int(weight)) lb)"
        case .ezCurlBar: return "EZ Curl Bar (\(Int(weight)) lb)"
        case .trapBar: return "Trap Bar (\(Int(weight)) lb)"
        case .safetySquatBar: return "Safety Squat Bar (\(Int(weight)) lb)"
        }
    }
}
