import Foundation
import SwiftData

typealias SampleData = PreviewData

@MainActor
class PreviewData {
    static let shared = PreviewData()

    let modelContainer: ModelContainer

    var context: ModelContext {
        modelContainer.mainContext
    }
    
    var exercise: Exercise {
        let exercises = try? context.fetch(FetchDescriptor<Exercise>())
        return exercises?.first ?? Exercise(name: "Sample Exercise", bodyPart: "Chest")
    }

    private init() {
        let schema = Schema([
            Exercise.self,
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            insertSampleData()
            
            try context.save()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func insertSampleData() {
        // Load exercises from JSON file - same data source as the real app
        let exercises = Exercise.loadFromBundle()
        for exercise in exercises {
            context.insert(exercise)
        }
    }
}
