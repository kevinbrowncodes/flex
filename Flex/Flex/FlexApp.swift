import SwiftUI
import SwiftData

@main
struct FlexKeyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Check if we need to prepopulate
            let context = container.mainContext
            
            if try context.fetchCount(FetchDescriptor<Exercise>()) == 0 {
                // First launch - load all exercises from JSON
                for exercise in Exercise.loadFromBundle() {
                    context.insert(exercise)
                }
                try context.save()
            } else {
                // Check for new exercises not in database
                let existingExercises = try context.fetch(FetchDescriptor<Exercise>())
                let existingNames = Set(existingExercises.map { $0.name })
                let newExercises = Exercise.loadFromBundle().filter { !existingNames.contains($0.name) }
                
                if !newExercises.isEmpty {
                    for exercise in newExercises {
                        context.insert(exercise)
                    }
                    try context.save()
                    print("Added \(newExercises.count) new exercise(s) from JSON")
                }
            }
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
