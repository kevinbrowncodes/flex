import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Profile", systemImage: "person.fill") {
                ProfileView()
            }
            
            Tab("History", systemImage: "clock.fill") {
                HistoryView()
            }
            
            Tab("Workout", systemImage: "plus.circle.fill") {
                WorkoutView()
            }
            
            Tab("Exercises", systemImage: "dumbbell.fill") {
                ExerciseListView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.shared.modelContainer)
}
