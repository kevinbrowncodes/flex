import SwiftUI

struct SetDailyTargetView: View {
    @Environment(PreferencesManager.self) private var preferencesManager
    @Binding var isPresented: Bool

    var body: some View {
        TargetEditorCard(
            title: "Set Daily Target",
            fieldLabel: "Target Workouts per Day",
            currentValue: preferencesManager.dailyTarget,
            isPresented: $isPresented
        ) { newValue in
            preferencesManager.setDailyTarget(newValue)
        }
    }
}

#Preview {
    SetDailyTargetView(isPresented: .constant(true))
        .environment(PreferencesManager())
}
