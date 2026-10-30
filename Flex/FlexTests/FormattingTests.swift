import Testing
@testable import Flex

struct FormattingTests {
    @Test("Weights drop trailing zeros but keep meaningful decimals")
    func weightFormatting() {
        #expect(Formatting.weight(135) == "135")
        #expect(Formatting.weight(132.5) == "132.5")
        #expect(Formatting.weight(132.25) == "132.25")
        #expect(Formatting.weight(100.0) == "100")
        #expect(Formatting.weight(0) == "0")
        #expect(Formatting.weight(2.5) == "2.5")
        #expect(Formatting.weightWithUnit(225) == "225 lb")
    }

    @Test("Plate labels drop the leading zero on fractional plates")
    func plateFormatting() {
        #expect(Formatting.plate(45) == "45")
        #expect(Formatting.plate(2.5) == "2.5")
        #expect(Formatting.plate(0.5) == ".5")
        #expect(Formatting.plate(0.25) == ".25")
    }

    @Test("Set summaries describe whatever was logged")
    func setSummary() {
        #expect(Formatting.setSummary(weight: 135, reps: 10) == "135 lb × 10")
        #expect(Formatting.setSummary(weight: 135, reps: nil) == "135 lb")
        #expect(Formatting.setSummary(weight: nil, reps: 12) == "12 reps")
        #expect(Formatting.setSummary(weight: 0, reps: 10) == "10 reps", "zero weight means bodyweight")
        #expect(Formatting.setSummary(weight: 0, reps: nil) == nil)
        #expect(Formatting.setSummary(weight: nil, reps: nil, time: "1:30") == "1:30")
        #expect(Formatting.setSummary(weight: nil, reps: nil, time: "") == nil)
        #expect(Formatting.setSummary(weight: nil, reps: nil) == nil)
        #expect(Formatting.compactSetSummary(weight: 185, reps: 8) == "185 × 8")
    }

    @Test("Durations round down to whole minutes, with hours when needed")
    func durationFormatting() {
        #expect(Formatting.duration(0) == "0m")
        #expect(Formatting.duration(59) == "0m")
        #expect(Formatting.duration(45 * 60 + 30) == "45m")
        #expect(Formatting.duration(3600 + 5 * 60) == "1h 5m")
        #expect(Formatting.duration(-10) == "0m")
    }

    @Test("Timer shows m:ss, and h:mm:ss after an hour")
    func timerFormatting() {
        #expect(Formatting.timer(0) == "0:00")
        #expect(Formatting.timer(41) == "0:41")
        #expect(Formatting.timer(605) == "10:05")
        #expect(Formatting.timer(3723) == "1:02:03")
    }
}
