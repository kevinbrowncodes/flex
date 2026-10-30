import Foundation
import SwiftData

@Model
class TemplateExercise: Identifiable {
    var id = UUID()
    @Relationship(deleteRule: .nullify, inverse: \Exercise.templateExercises)
    var exercise: Exercise?
    var order: Int = 0
    @Relationship(deleteRule: .cascade, inverse: \TemplateSet.templateExercise)
    var sets: [TemplateSet]?
    var workoutTemplate: WorkoutTemplate?
    
    init(exercise: Exercise, sets: [TemplateSet] = [], order: Int = 0) {
        self.exercise = exercise
        self.sets = sets.isEmpty ? nil : sets
        self.order = order
    }
    
    // Helper for safer access
    var setsArray: [TemplateSet] {
        get { sets ?? [] }
        set { sets = newValue.isEmpty ? nil : newValue }
    }
}

@Model
class TemplateSet: Identifiable {
    var id = UUID()
    var setNumber: Int = 1
    var reps: Int?
    var weight: Double?
    var templateExercise: TemplateExercise?
    
    init(setNumber: Int, reps: Int? = nil, weight: Double? = nil) {
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
    }
}
