import Foundation

/// Pure plate-loading arithmetic used by the plate calculator.
enum PlateMath {
    /// Plates available in most gyms, heaviest first (per side, in lb).
    static let standardPlates: [Double] = [45, 35, 25, 10, 5, 2.5, 1, 0.5, 0.25]

    /// Greedy loading of one side of the bar to reach `target` as closely as possible.
    static func optimalPlates(target: Double, barWeight: Double, available: [Double] = standardPlates) -> [Double] {
        var remaining = max(0, (target - barWeight) / 2)
        var plates: [Double] = []
        for plate in available.sorted(by: >) where plate > 0 {
            // Tolerate floating point residue (e.g. 0.7499999) when dividing.
            let count = Int((remaining / plate) + 1e-9)
            guard count > 0 else { continue }
            plates.append(contentsOf: Array(repeating: plate, count: count))
            remaining -= Double(count) * plate
        }
        return plates
    }

    /// Total bar weight for plates loaded on one side.
    static func totalWeight(platesPerSide: [Double], barWeight: Double) -> Double {
        barWeight + platesPerSide.reduce(0, +) * 2
    }

    /// Weight still needed per side to reach `target`.
    static func remainingPerSide(target: Double, barWeight: Double, platesPerSide: [Double]) -> Double {
        max(0, (target - barWeight) / 2) - platesPerSide.reduce(0, +)
    }

    /// Groups plates by weight, heaviest first: [(45, 2), (10, 1)].
    static func grouped(_ plates: [Double]) -> [(weight: Double, count: Int)] {
        var counts: [Double: Int] = [:]
        for plate in plates { counts[plate, default: 0] += 1 }
        return counts.keys.sorted(by: >).map { (weight: $0, count: counts[$0]!) }
    }
}
