import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable {
    case profile
    case history
    case exercises
    case workout
}

struct ContentView: View {
    @State private var selectedTab: AppTab = ContentView.initialTab

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Profile", systemImage: "person.fill", value: .profile) {
                ProfileView()
            }

            Tab("History", systemImage: "clock.fill", value: .history) {
                HistoryView()
            }

            Tab("Exercises", systemImage: "dumbbell.fill", value: .exercises) {
                ExerciseListView()
            }

            Tab("Workout", systemImage: "plus.circle.fill", value: .workout) {
                WorkoutView()
            }
        }
    }

    private static var initialTab: AppTab {
        #if DEBUG
        if let requested = DemoMode.current?.initialTab, let tab = AppTab(rawValue: requested) {
            return tab
        }
        #endif
        return .profile
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.shared.modelContainer)
        .environment(ThemeManager())
        .environment(PreferencesManager())
        .environment(AuthenticationManager())
        .environment(CloudKitSyncMonitor(simulatedStatus: .synced))
}
