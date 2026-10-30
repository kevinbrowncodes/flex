import Foundation
import SwiftData

@Model
class WorkoutTemplate: Identifiable {
    var id = UUID()
    var name: String = ""
    var createdDate: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.workoutTemplate)
    var templateExercises: [TemplateExercise]?
    var templateFolder: TemplateFolder?
    
    // Computed property for backward compatibility
    var exercises: [Exercise] {
        (templateExercises ?? []).compactMap { $0.exercise }
    }
    
    // Helper for safer access
    var templateExercisesArray: [TemplateExercise] {
        get { templateExercises ?? [] }
        set { templateExercises = newValue }
    }
    
    init(name: String, templateExercises: [TemplateExercise] = [], createdDate: Date = Date()) {
        self.name = name
        self.templateExercises = templateExercises
        self.createdDate = createdDate
    }
    
    // Convenience initializer for backward compatibility
    convenience init(name: String, exercises: [Exercise], createdDate: Date = Date()) {
        let templateExercises = exercises.enumerated().map { index, exercise in
            TemplateExercise(exercise: exercise, sets: [], order: index)
        }
        self.init(name: name, templateExercises: templateExercises, createdDate: createdDate)
    }
}
