import Foundation

/// Shared number/date formatting so every screen shows values the same way.
enum Formatting {
    /// "135", "132.5", "132.25" — up to two decimals, trailing zeros dropped.
    static func weight(_ value: Double) -> String {
        var text = String(format: "%.2f", value)
        if text.contains(".") {
            while text.hasSuffix("0") { text.removeLast() }
            if text.hasSuffix(".") { text.removeLast() }
        }
        if text == "-0" { text = "0" }
        return text
    }

    /// "135 lb"
    static func weightWithUnit(_ value: Double) -> String {
        "\(weight(value)) lb"
    }

    /// A plate label: "45", "2.5", ".25".
    static func plate(_ value: Double) -> String {
        let text = weight(value)
        return text.hasPrefix("0.") ? String(text.dropFirst()) : text
    }

    /// One-line summary of a set: "135 lb × 10", "10 reps", "1:30", or nil when the set is empty.
    /// A weight of 0 means bodyweight, so only the reps are shown.
    static func setSummary(weight: Double?, reps: Int?, time: String? = nil) -> String? {
        let weight = (weight ?? 0) > 0 ? weight : nil
        if let weight, let reps {
            return "\(Formatting.weight(weight)) lb × \(reps)"
        } else if let weight {
            return "\(Formatting.weight(weight)) lb"
        } else if let reps {
            return "\(reps) reps"
        } else if let time, !time.isEmpty {
            return time
        }
        return nil
    }

    /// Compact form used in the "Previous" column: "135 × 10".
    static func compactSetSummary(weight: Double?, reps: Int?, time: String? = nil) -> String? {
        if let weight, weight > 0, let reps {
            return "\(Formatting.weight(weight)) × \(reps)"
        }
        return setSummary(weight: weight, reps: reps, time: time)
    }

    /// "45m" or "1h 5m".
    static func duration(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int(interval) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    /// Running clock: "0:41" or "1:02:03".
    static func timer(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let hours = total / 3600
        let minutes = total / 60 % 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
