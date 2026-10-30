import Testing
@testable import Flex

struct PlateMathTests {
    @Test("225 on an Olympic bar is two 45s per side")
    func classicTwoPlates() {
        #expect(PlateMath.optimalPlates(target: 225, barWeight: 45) == [45, 45])
    }

    @Test("Greedy loading picks the fewest plates")
    func greedyLoading() {
        #expect(PlateMath.optimalPlates(target: 135, barWeight: 45) == [45])
        #expect(PlateMath.optimalPlates(target: 185, barWeight: 45) == [45, 25])
        #expect(PlateMath.optimalPlates(target: 315, barWeight: 45) == [45, 45, 45])
        #expect(PlateMath.optimalPlates(target: 200, barWeight: 45) == [45, 25, 5, 2.5])
    }

    @Test("Fractional plates load without floating point drift")
    func fractionalPlates() {
        #expect(PlateMath.optimalPlates(target: 46.5, barWeight: 45) == [0.5, 0.25])
        #expect(PlateMath.optimalPlates(target: 47, barWeight: 45) == [1])
        #expect(PlateMath.optimalPlates(target: 137.5, barWeight: 45) == [45, 1, 0.25])
    }

    @Test("Targets at or below the bar weight need no plates")
    func barOnly() {
        #expect(PlateMath.optimalPlates(target: 45, barWeight: 45).isEmpty)
        #expect(PlateMath.optimalPlates(target: 20, barWeight: 45).isEmpty)
        #expect(PlateMath.optimalPlates(target: 0, barWeight: 45).isEmpty)
    }

    @Test("Other bars use their own weight")
    func womensBar() {
        #expect(PlateMath.optimalPlates(target: 135, barWeight: BarType.womensBarbell.weight) == [45, 5])
        #expect(BarType.womensBarbell.weight == 35)
        #expect(BarType.safetySquatBar.weight == 60)
    }

    @Test("Totals and remaining weight account for both sides")
    func totalsAndRemaining() {
        #expect(PlateMath.totalWeight(platesPerSide: [45, 45], barWeight: 45) == 225)
        #expect(PlateMath.totalWeight(platesPerSide: [], barWeight: 45) == 45)
        #expect(PlateMath.remainingPerSide(target: 225, barWeight: 45, platesPerSide: [45]) == 45)
        #expect(PlateMath.remainingPerSide(target: 225, barWeight: 45, platesPerSide: [45, 45]) == 0)
    }

    @Test("Grouping counts plates heaviest first")
    func grouping() {
        let grouped = PlateMath.grouped([10, 45, 45, 2.5])
        #expect(grouped.map { $0.weight } == [45, 10, 2.5])
        #expect(grouped.map { $0.count } == [2, 1, 1])
    }
}
