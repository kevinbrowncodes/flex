import SwiftUI

struct SetWorkoutTargetView: View {
    @Environment(PreferencesManager.self) private var preferencesManager
    @Binding var isPresented: Bool

    var body: some View {
        TargetEditorCard(
            title: "Set Workout Target",
            fieldLabel: "Target Workouts per Week",
            currentValue: preferencesManager.workoutTarget,
            isPresented: $isPresented
        ) { newValue in
            preferencesManager.setWorkoutTarget(newValue)
        }
    }
}

/// Shared card used to edit a small positive integer goal.
struct TargetEditorCard: View {
    let title: String
    let fieldLabel: String
    let currentValue: Int
    @Binding var isPresented: Bool
    let onSave: (Int) -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    static let maximumTarget = 99

    private var parsedValue: Int? {
        guard let value = Int(text.trimmingCharacters(in: .whitespaces)), value > 0, value <= Self.maximumTarget else {
            return nil
        }
        return value
    }

    private var canSave: Bool {
        parsedValue != nil && parsedValue != currentValue
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("Cancel")

                Spacer()

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("Save") {
                    if let value = parsedValue {
                        onSave(value)
                    }
                    isPresented = false
                }
                .disabled(!canSave)
                .accessibilityIdentifier("save-target")
            }
            .padding()
            .background(Color(.systemBackground))

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                Text(fieldLabel)
                    .font(.body)
                    .fontWeight(.semibold)

                TextField("1", text: $text)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(parsedValue == nil && !text.isEmpty ? Color.red : Color.primary, lineWidth: 2)
                    )
                    .accessibilityIdentifier("target-field")

                if parsedValue == nil && !text.isEmpty {
                    Text("Enter a number between 1 and \(Self.maximumTarget).")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .onAppear {
            text = String(currentValue)
            isFocused = true
        }
    }
}

#Preview {
    SetWorkoutTargetView(isPresented: .constant(true))
        .environment(PreferencesManager())
}
