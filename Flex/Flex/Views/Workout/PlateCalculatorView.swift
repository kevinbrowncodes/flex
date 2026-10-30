import SwiftUI

/// Shows which plates to load on each side of the bar to reach the target weight.
struct PlateCalculatorView: View {
    @Binding var weight: Double?
    @Binding var isPresented: Bool
    var barType: BarType = .olympicBarbell
    @State private var actualPlates: [Double] = [] // plates on one side, heaviest first
    @State private var previousPlates: [Double]? // for undo

    private let availablePlates = PlateMath.standardPlates
    private let maxPlatesPerSide = 8

    private var barWeight: Double { barType.weight }
    private var targetWeight: Double { weight ?? 0 }

    private var remainingWeight: Double {
        PlateMath.remainingPerSide(target: targetWeight, barWeight: barWeight, platesPerSide: actualPlates)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { isPresented = false }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .accessibilityLabel("Back to keypad")

                if previousPlates != nil {
                    Button(action: undo) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.body)
                            .foregroundStyle(.blue)
                    }
                    .accessibilityLabel("Undo")
                }

                Spacer()

                VStack(spacing: 4) {
                    Text(Formatting.weightWithUnit(targetWeight))
                        .font(.system(size: 28, weight: .bold))
                        .accessibilityIdentifier("plate-target")

                    Text(barType.displayName)
                        .font(.caption2)
                        .foregroundStyle(.blue)

                    Text(remainingWeight > 0.001
                         ? "Remaining: \(Formatting.weightWithUnit(remainingWeight)) per side"
                         : "Bar loaded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: clear) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundStyle(.red)
                }
                .accessibilityLabel("Clear plates")
            }
            .padding()
            .background(Color(.systemBackground))

            Divider()

            ScrollView([.horizontal, .vertical]) {
                BarbellView(plates: PlateMath.grouped(actualPlates), barType: barType)
                    .padding(20)
            }
            .frame(height: 180)

            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Select")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button(action: optimize) {
                            Image(systemName: "wand.and.rays")
                                .font(.body)
                                .fontWeight(.semibold)
                                .frame(width: 60, height: 40)
                                .background(Color.blue.opacity(0.15))
                                .foregroundStyle(.blue)
                                .cornerRadius(8)
                        }
                        .accessibilityLabel("Load optimal plates")

                        ForEach(availablePlates, id: \.self) { plateWeight in
                            Button(action: { addPlate(plateWeight) }) {
                                Text(Formatting.plate(plateWeight))
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .frame(width: 60, height: 40)
                                    .background(Color(.systemGray5))
                                    .foregroundStyle(.primary)
                                    .cornerRadius(8)
                            }
                            .disabled(actualPlates.count >= maxPlatesPerSide)
                            .opacity(actualPlates.count >= maxPlatesPerSide ? 0.5 : 1.0)
                            .accessibilityLabel("Add \(Formatting.plate(plateWeight)) pound plate")
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 12)
        }
        .frame(height: 350)
        .background(Color(.systemBackground))
        .onAppear {
            if actualPlates.isEmpty {
                actualPlates = PlateMath.optimalPlates(target: targetWeight, barWeight: barWeight, available: availablePlates)
            }
        }
    }

    private func optimize() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            previousPlates = actualPlates
            actualPlates = PlateMath.optimalPlates(target: targetWeight, barWeight: barWeight, available: availablePlates)
        }
    }

    private func undo() {
        guard let previous = previousPlates else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            actualPlates = previous
            updateWeight()
            previousPlates = nil
        }
    }

    private func clear() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            previousPlates = actualPlates
            actualPlates = []
            weight = barWeight
        }
    }

    private func addPlate(_ plateWeight: Double) {
        guard actualPlates.count < maxPlatesPerSide else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            previousPlates = actualPlates
            actualPlates.append(plateWeight)
            actualPlates.sort(by: >)
            updateWeight()
        }
    }

    private func updateWeight() {
        weight = PlateMath.totalWeight(platesPerSide: actualPlates, barWeight: barWeight)
    }
}

struct BarbellView: View {
    let plates: [(weight: Double, count: Int)]
    let barType: BarType

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 2) {
                ForEach(Array(plates.reversed().enumerated()), id: \.offset) { _, plate in
                    ForEach(0..<plate.count, id: \.self) { _ in
                        PlateView(weight: plate.weight, isLeft: true)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }

            VStack(spacing: 4) {
                Text(barType.shortName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Rectangle()
                    .fill(Color(.systemGray2))
                    .frame(width: 120, height: 8)
                    .cornerRadius(4)

                Text(Formatting.weightWithUnit(barType.weight))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)

            HStack(spacing: 2) {
                ForEach(Array(plates.enumerated()), id: \.offset) { _, plate in
                    ForEach(0..<plate.count, id: \.self) { _ in
                        PlateView(weight: plate.weight)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: plates.map { "\($0.weight)-\($0.count)" }.joined())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        guard !plates.isEmpty else { return "\(barType.shortName), no plates" }
        let list = plates.map { "\($0.count) × \(Formatting.plate($0.weight))" }.joined(separator: ", ")
        return "\(barType.shortName) with \(list) per side"
    }
}

struct PlateView: View {
    let weight: Double
    var isLeft: Bool = false

    private var plateColor: Color {
        switch weight {
        case 45: return .blue
        case 35: return .yellow
        case 25: return .green
        case 10: return .white
        case 5: return .blue
        case 2.5: return .green
        case 1: return .red
        case 0.5: return .yellow
        case 0.25: return .green
        default: return .gray
        }
    }

    private var plateHeight: CGFloat {
        switch weight {
        case 45: return 75
        case 35: return 70
        case 25: return 60
        case 10: return 45
        case 5: return 35
        case 2.5: return 30
        case 1: return 25
        case 0.5: return 20
        case 0.25: return 18
        default: return 30
        }
    }

    private var fontSize: CGFloat {
        switch weight {
        case 0.25: return 6
        case 0.5: return 7
        case 1: return 8
        case 2.5: return 9
        default: return 10
        }
    }

    private var plateWidth: CGFloat {
        weight < 1 ? 24 : 20
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(plateColor.opacity(0.8))
            .frame(width: plateWidth, height: plateHeight)
            .overlay {
                Text(Formatting.plate(weight))
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isLeft ? 90 : -90))
            }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var weight: Double? = 225
        @State private var isPresented = true

        var body: some View {
            PlateCalculatorView(weight: $weight, isPresented: $isPresented)
        }
    }

    return PreviewWrapper()
}

#Preview("Women's Barbell") {
    struct PreviewWrapper: View {
        @State private var weight: Double? = 135
        @State private var isPresented = true

        var body: some View {
            PlateCalculatorView(weight: $weight, isPresented: $isPresented, barType: .womensBarbell)
        }
    }

    return PreviewWrapper()
}
