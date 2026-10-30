import Foundation
import SwiftData

@Model
class TemplateFolder: Identifiable {
    var id = UUID()
    var name: String = ""
    var createdDate: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplate.templateFolder)
    var templates: [WorkoutTemplate]?
    
    var templateCount: Int {
        templates?.count ?? 0
    }
    
    // Helper for safer access
    var templatesArray: [WorkoutTemplate] {
        get { templates ?? [] }
        set { templates = newValue }
    }
    
    init(name: String, createdDate: Date = Date()) {
        self.name = name
        self.createdDate = createdDate
    }
}
