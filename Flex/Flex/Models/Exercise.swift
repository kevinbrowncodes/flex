import Foundation
import SwiftData

@Model
class Exercise {
    var name: String
    var bodyPart: String
    
    init(name: String, bodyPart: String) {
        self.name = name
        self.bodyPart = bodyPart
    }
    
    static func loadFromBundle() -> [Exercise] {
        guard let url = Bundle.main.url(forResource: "Exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to locate Exercises.json in bundle")
            return []
        }
        
        let decoder = JSONDecoder()
        
        struct ExerciseData: Codable {
            let name: String
            let bodyPart: String
        }
        
        guard let exerciseData = try? decoder.decode([ExerciseData].self, from: data) else {
            print("Failed to decode Exercises.json")
            return []
        }
        
        return exerciseData.map { Exercise(name: $0.name, bodyPart: $0.bodyPart) }
    }
}
