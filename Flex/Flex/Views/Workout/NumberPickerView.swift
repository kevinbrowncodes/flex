import SwiftUI

enum NumberPickerType {
    case weight
    case reps

    var title: String {
        switch self {
        case .weight: return "lbs"
        case .reps: return "reps"
        }
    }

    var allowsDecimal: Bool {
        self == .weight
    }

    var incrementValue: Double {
        switch self {
        case .weight: return 2.5
        case .reps: return 1
        }
    }
}

/// Custom number pad shown at the bottom of the workout screen for weight and rep entry.
struct NumberPickerView: View {
    let type: NumberPickerType
    @Binding var value: Double?
    @Binding var isPresented: Bool
    var exerciseName: String? = nil
    var barType: BarType? = nil
    @State private var currentValue: String = ""
    @State private var showPlateCalculator = false
    var onDone: () -> Void

    private static let maximumDigits = 7

    private var shouldShowPlateCalculator: Bool {
        type == .weight && (barType != nil || (exerciseName?.contains("(Barbell)") ?? false))
    }

    private func updateValue() {
        if let doubleValue = Double(currentValue), doubleValue >= 0 {
            value = doubleValue
        } else if currentValue.isEmpty {
            value = nil
        }
    }

    private func format(_ number: Double) -> String {
        type.allowsDecimal ? Formatting.weight(number) : String(format: "%.0f", number)
    }

    var body: some View {
        if showPlateCalculator {
            PlateCalculatorView(
                weight: $value,
                isPresented: $showPlateCalculator,
                barType: barType ?? .olympicBarbell
            )
        } else {
            numberPadView
        }
    }

    private var numberPadView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(currentValue.isEmpty ? "0" : currentValue)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("numberpad-display")
                Text(type.title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            Divider()

            VStack(spacing: 1) {
                HStack(spacing: 1) {
                    numberButton("1")
                    numberButton("2")
                    numberButton("3")
                    actionButton(systemImage: "chevron.down", label: "Hide keypad") {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }

                HStack(spacing: 1) {
                    numberButton("4")
                    numberButton("5")
                    numberButton("6")

                    if shouldShowPlateCalculator {
                        actionButton(systemImage: "scalemass.fill", label: "Plate calculator") {
                            showPlateCalculator = true
                        }
                        .accessibilityIdentifier("numberpad-plates")
                    } else {
                        Color(.systemGray5)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }

                HStack(spacing: 1) {
                    numberButton("7")
                    numberButton("8")
                    numberButton("9")
                    actionButton(systemImage: "minus", label: "Decrease") {
                        let current = Double(currentValue) ?? 0
                        currentValue = format(max(0, current - type.incrementValue))
                        updateValue()
                    }
                }

                HStack(spacing: 1) {
                    if type.allowsDecimal {
                        Button(action: {
                            if !currentValue.contains(".") && currentValue.count < Self.maximumDigits {
                                currentValue += currentValue.isEmpty ? "0." : "."
                                updateValue()
                            }
                        }) {
                            Text(".")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(.systemGray5))
                                .foregroundStyle(.primary)
                        }
                        .accessibilityLabel("Decimal point")
                    } else {
                        Color(.systemGray5)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }

                    numberButton("0")

                    Button(action: {
                        if !currentValue.isEmpty {
                            currentValue.removeLast()
                            updateValue()
                        }
                    }) {
                        Image(systemName: "delete.backward")
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Delete")

                    actionButton(systemImage: "plus", label: "Increase") {
                        let current = Double(currentValue) ?? 0
                        currentValue = format(current + type.incrementValue)
                        updateValue()
                    }
                }
            }
            .background(Color(.systemGray6))
            .padding(.bottom, 8)

            Button(action: onDone) {
                Text("Done")
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.blue)
                    .foregroundStyle(.white)
            }
            .accessibilityIdentifier("numberpad-done")
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .onAppear {
            currentValue = value.map(format) ?? ""
        }
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                currentValue = ""
            }
        }
        .onChange(of: value) { _, newValue in
            // Keep the display in sync when the plate calculator writes a new weight.
            if let newValue, Double(currentValue) != newValue {
                currentValue = format(newValue)
            }
        }
    }

    private func numberButton(_ number: String) -> some View {
        Button(action: {
            guard currentValue.count < Self.maximumDigits else { return }
            currentValue += number
            updateValue()
        }) {
            Text(number)
                .font(.title2)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(.systemGray5))
                .foregroundStyle(.primary)
        }
        .accessibilityIdentifier("numberpad-\(number)")
    }

    private func actionButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(.systemGray4))
                .foregroundStyle(.primary)
        }
        .accessibilityLabel(label)
    }
}

#Preview("Default") {
    NumberPickerView(type: .weight, value: .constant(225), isPresented: .constant(true), onDone: {})
}

#Preview("Barbell Exercise") {
    NumberPickerView(type: .weight, value: .constant(225), isPresented: .constant(true), exerciseName: "Bench Press (Barbell)", barType: .olympicBarbell, onDone: {})
}
