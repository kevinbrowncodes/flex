import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable {
    case profile
    case history
    case exercises
    case workout
}

struct ContentView: View {
    @Environment(LiveWorkoutSession.self) private var session
    @State private var selectedTab: AppTab = ContentView.initialTab

    var body: some View {
        tabs
            // A workout Flex was closed in the middle of comes back on the Workout tab (STORY_002), and
            // one the watch starts while Flex is open goes there too (STORY_009).
            .onAppear {
                if session.isActive { selectedTab = .workout }
            }
            .onChange(of: session.isActive) { _, isActive in
                if isActive { selectedTab = .workout }
            }
    }

    private var tabs: some View {
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
        .environment(LiveWorkoutSession(store: nil, resume: false))
        .environment(PhoneMirrorHost(session: LiveWorkoutSession(store: nil, resume: false), healthStore: nil))
}
