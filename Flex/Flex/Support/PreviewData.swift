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
            Workout.self,
            WorkoutExercise.self,
            ExerciseSet.self,
            WorkoutTemplate.self,
            TemplateFolder.self,
            TemplateExercise.self,
            TemplateSet.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            PreviewData.insertSampleData(into: context)
            
            try context.save()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    /// Inserts the full sample data set (exercise library, workouts, folders and templates) into `context`.
    static func insertSampleData(into context: ModelContext) {
        // Load exercises from JSON file - same data source as the real app
        let exercises = Exercise.loadFromBundle()
        for exercise in exercises {
            context.insert(exercise)
        }
        
        // Add custom user-created exercises
        let customExercises = [
            Exercise(name: "My Cable Crossover", bodyPart: "Chest", isBuiltIn: false),
            Exercise(name: "Custom Leg Extension", bodyPart: "Legs", isBuiltIn: false),
            Exercise(name: "Bulgarian Split Squat", bodyPart: "Legs", isBuiltIn: false),
            Exercise(name: "Farmer's Walk", bodyPart: "Core", isBuiltIn: false)
        ]
        for customExercise in customExercises {
            context.insert(customExercise)
        }
        
        // Add deleted exercises for testing
        let deletedExercises = [
            Exercise(name: "Old Rope Climb", bodyPart: "Back", isBuiltIn: false, isArchived: true),
            Exercise(name: "Deleted Plank Hold", bodyPart: "Core", isBuiltIn: false, isArchived: true),
            Exercise(name: "Removed Chest Fly", bodyPart: "Chest", isBuiltIn: false, isArchived: true)
        ]
        for deletedExercise in deletedExercises {
            context.insert(deletedExercise)
        }
        
        // Pick well-known exercises by name so sample workouts and templates read naturally.
        func exercise(named name: String, fallback: (Exercise) -> Bool) -> Exercise {
            exercises.first { $0.name == name } ?? exercises.first(where: fallback) ?? exercises[0]
        }
        let benchPress = exercise(named: "Bench Press (Barbell)") { $0.bodyPart == "Chest" }
        let chestFly = exercise(named: "Chest Fly (Dumbbell)") { $0.bodyPart == "Chest" && $0.name.contains("Fly") }
        let inclineBench = exercise(named: "Incline Bench Press (Barbell)") { $0.bodyPart == "Chest" && $0.name.contains("Incline") }
        let chestPress = exercise(named: "Incline Chest Press (Machine)") { $0.bodyPart == "Chest" && $0.name.contains("Press") }
        let pecDeck = exercise(named: "Pec Deck (Machine)") { $0.bodyPart == "Chest" }

        let squatExercise = exercise(named: "Squat (Barbell)") { $0.bodyPart == "Legs" && $0.name.contains("Squat") }
        let legPress = exercise(named: "Leg Press") { $0.bodyPart == "Legs" && $0.name.contains("Press") }
        let lunges = exercise(named: "Lunge (Dumbbell)") { $0.bodyPart == "Legs" && $0.name.contains("Lunge") }
        let legCurl = exercise(named: "Lying Leg Curl (Machine)") { $0.bodyPart == "Legs" && $0.name.contains("Curl") }

        let backRow = exercise(named: "Bent Over Row (Barbell)") { $0.bodyPart == "Back" && $0.name.contains("Row") }
        let pulldown = exercise(named: "Lat Pulldown (Cable)") { $0.bodyPart == "Back" && $0.name.contains("Pulldown") }
        let deadlift = exercise(named: "Deadlift (Barbell)") { $0.name.contains("Deadlift") }

        let shoulderPress = exercise(named: "Overhead Press (Barbell)") { $0.bodyPart == "Shoulders" && $0.name.contains("Press") }
        let shoulderShrug = exercise(named: "Shrug (Dumbbell)") { $0.name.contains("Shrug") }
        let reverseFly = exercise(named: "Reverse Fly (Dumbbell)") { $0.bodyPart == "Shoulders" && $0.name.contains("Reverse") }
        let lateralRaise = exercise(named: "Lateral Raise (Dumbbell)") { $0.bodyPart == "Shoulders" && $0.name.contains("Lateral") }

        let bicepCurl = exercise(named: "Bicep Curl (Dumbbell)") { $0.bodyPart == "Arms" && $0.name.contains("Curl") }
        let tricepPushdown = exercise(named: "Triceps Pushdown (Cable - Straight Bar)") { $0.bodyPart == "Arms" && $0.name.contains("Pushdown") }
        let tricepExtension = exercise(named: "Triceps Extension (Cable)") { $0.bodyPart == "Arms" && $0.name.contains("Extension") }
        let dips = exercise(named: "Triceps Dip") { $0.bodyPart == "Arms" && $0.name.contains("Dip") }

        let legExtension = exercise(named: "Leg Extension (Machine)") { $0.bodyPart == "Legs" && $0.name.contains("Extension") }
        
        // Workout 1 - Today: Chest Day with realistic chest exercises
        let workout1 = Workout(title: "Chest Day", date: Date(), duration: 3600, exercises: [])
        context.insert(workout1)
        workout1.exercises = []
        
        let we1 = WorkoutExercise(exercise: benchPress, sets: [])
        context.insert(we1)
        let set1_1 = ExerciseSet(setNumber: 1, reps: 10, weight: 135)
        let set1_2 = ExerciseSet(setNumber: 2, reps: 8, weight: 185)
        let set1_3 = ExerciseSet(setNumber: 3, reps: 5, weight: 205)
        context.insert(set1_1)
        context.insert(set1_2)
        context.insert(set1_3)
        we1.sets = [set1_1, set1_2, set1_3]
        workout1.exercises?.append(we1)
        
        let we2 = WorkoutExercise(exercise: chestFly, sets: [])
        context.insert(we2)
        let set2_1 = ExerciseSet(setNumber: 1, reps: 12, weight: 30)
        let set2_2 = ExerciseSet(setNumber: 2, reps: 10, weight: 35)
        context.insert(set2_1)
        context.insert(set2_2)
        we2.sets = [set2_1, set2_2]
        workout1.exercises?.append(we2)
        
        let we3_chest = WorkoutExercise(exercise: inclineBench, sets: [])
        context.insert(we3_chest)
        let set3c_1 = ExerciseSet(setNumber: 1, reps: 10, weight: 115)
        let set3c_2 = ExerciseSet(setNumber: 2, reps: 8, weight: 135)
        let set3c_3 = ExerciseSet(setNumber: 3, reps: 6, weight: 155)
        context.insert(set3c_1)
        context.insert(set3c_2)
        context.insert(set3c_3)
        we3_chest.sets = [set3c_1, set3c_2, set3c_3]
        workout1.exercises?.append(we3_chest)
        
        let we4_chest = WorkoutExercise(exercise: chestPress, sets: [])
        context.insert(we4_chest)
        let set4c_1 = ExerciseSet(setNumber: 1, reps: 12, weight: 45)
        let set4c_2 = ExerciseSet(setNumber: 2, reps: 10, weight: 50)
        context.insert(set4c_1)
        context.insert(set4c_2)
        we4_chest.sets = [set4c_1, set4c_2]
        workout1.exercises?.append(we4_chest)
        
        // Workout 2 - 3 days ago: Leg Day with leg exercises
        let workout2 = Workout(title: "Leg Day", date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, duration: 4200, exercises: [])
        context.insert(workout2)
        workout2.exercises = []
        
        let we3 = WorkoutExercise(exercise: squatExercise, sets: [])
        context.insert(we3)
        let set3_1 = ExerciseSet(setNumber: 1, reps: 8, weight: 225)
        let set3_2 = ExerciseSet(setNumber: 2, reps: 5, weight: 275)
        let set3_3 = ExerciseSet(setNumber: 3, reps: 3, weight: 315)
        context.insert(set3_1)
        context.insert(set3_2)
        context.insert(set3_3)
        we3.sets = [set3_1, set3_2, set3_3]
        workout2.exercises?.append(we3)
        
        let we4_leg = WorkoutExercise(exercise: legPress, sets: [])
        context.insert(we4_leg)
        let set4l_1 = ExerciseSet(setNumber: 1, reps: 12, weight: 315)
        let set4l_2 = ExerciseSet(setNumber: 2, reps: 10, weight: 365)
        let set4l_3 = ExerciseSet(setNumber: 3, reps: 8, weight: 405)
        context.insert(set4l_1)
        context.insert(set4l_2)
        context.insert(set4l_3)
        we4_leg.sets = [set4l_1, set4l_2, set4l_3]
        workout2.exercises?.append(we4_leg)
        
        let we5_leg = WorkoutExercise(exercise: lunges, sets: [])
        context.insert(we5_leg)
        let set5l_1 = ExerciseSet(setNumber: 1, reps: 12, weight: 40)
        let set5l_2 = ExerciseSet(setNumber: 2, reps: 10, weight: 50)
        context.insert(set5l_1)
        context.insert(set5l_2)
        we5_leg.sets = [set5l_1, set5l_2]
        workout2.exercises?.append(we5_leg)
        
        let we6_leg = WorkoutExercise(exercise: legCurl, sets: [])
        context.insert(we6_leg)
        let set6l_1 = ExerciseSet(setNumber: 1, reps: 12, weight: 80)
        let set6l_2 = ExerciseSet(setNumber: 2, reps: 10, weight: 90)
        let set6l_3 = ExerciseSet(setNumber: 3, reps: 8, weight: 100)
        context.insert(set6l_1)
        context.insert(set6l_2)
        context.insert(set6l_3)
        we6_leg.sets = [set6l_1, set6l_2, set6l_3]
        workout2.exercises?.append(we6_leg)
        
        // Jan 1, 2026 workout - Full Body workout
        let jan1Components = DateComponents(year: 2026, month: 1, day: 1)
        let jan1Date = Calendar.current.date(from: jan1Components)!
        let workout3 = Workout(title: "New Year Full Body", date: jan1Date, duration: 4500, exercises: [])
        context.insert(workout3)
        workout3.exercises = []
        
        // Chest - Bench Press
        let we4 = WorkoutExercise(exercise: benchPress, sets: [])
        context.insert(we4)
        let set4_1 = ExerciseSet(setNumber: 1, reps: 12, weight: 135)
        let set4_2 = ExerciseSet(setNumber: 2, reps: 10, weight: 155)
        let set4_3 = ExerciseSet(setNumber: 3, reps: 8, weight: 185)
        context.insert(set4_1)
        context.insert(set4_2)
        context.insert(set4_3)
        we4.sets = [set4_1, set4_2, set4_3]
        workout3.exercises?.append(we4)
        
        // Back - Rows
        let we5_back = WorkoutExercise(exercise: backRow, sets: [])
        context.insert(we5_back)
        let set5b_1 = ExerciseSet(setNumber: 1, reps: 12, weight: 135)
        let set5b_2 = ExerciseSet(setNumber: 2, reps: 10, weight: 155)
        let set5b_3 = ExerciseSet(setNumber: 3, reps: 8, weight: 175)
        context.insert(set5b_1)
        context.insert(set5b_2)
        context.insert(set5b_3)
        we5_back.sets = [set5b_1, set5b_2, set5b_3]
        workout3.exercises?.append(we5_back)
        
        // Legs - Squats
        let we6_squat = WorkoutExercise(exercise: squatExercise, sets: [])
        context.insert(we6_squat)
        let set6s_1 = ExerciseSet(setNumber: 1, reps: 12, weight: 185)
        let set6s_2 = ExerciseSet(setNumber: 2, reps: 10, weight: 225)
        let set6s_3 = ExerciseSet(setNumber: 3, reps: 8, weight: 245)
        context.insert(set6s_1)
        context.insert(set6s_2)
        context.insert(set6s_3)
        we6_squat.sets = [set6s_1, set6s_2, set6s_3]
        workout3.exercises?.append(we6_squat)
        
        // Shoulders - Shoulder Press
        let we7_shoulder = WorkoutExercise(exercise: shoulderPress, sets: [])
        context.insert(we7_shoulder)
        let set7sh_1 = ExerciseSet(setNumber: 1, reps: 12, weight: 65)
        let set7sh_2 = ExerciseSet(setNumber: 2, reps: 10, weight: 75)
        context.insert(set7sh_1)
        context.insert(set7sh_2)
        we7_shoulder.sets = [set7sh_1, set7sh_2]
        workout3.exercises?.append(we7_shoulder)
        
        // Arms - Bicep Curls
        let we8_bicep = WorkoutExercise(exercise: bicepCurl, sets: [])
        context.insert(we8_bicep)
        let set8b_1 = ExerciseSet(setNumber: 1, reps: 12, weight: 30)
        let set8b_2 = ExerciseSet(setNumber: 2, reps: 10, weight: 35)
        context.insert(set8b_1)
        context.insert(set8b_2)
        we8_bicep.sets = [set8b_1, set8b_2]
        workout3.exercises?.append(we8_bicep)
        
        // Dec 24, 2025 workout - Birthday Full Body workout
        let birthdayComponents = DateComponents(year: 2025, month: 12, day: 24)
        let birthdayDate = Calendar.current.date(from: birthdayComponents)!
        let workout4 = Workout(title: "Birthday Full Body", date: birthdayDate, duration: 4800, exercises: [])
        context.insert(workout4)
        workout4.exercises = []
        
        // Chest - Incline Bench
        let we9_chest = WorkoutExercise(exercise: inclineBench, sets: [])
        context.insert(we9_chest)
        let set9c_1 = ExerciseSet(setNumber: 1, reps: 10, weight: 125)
        let set9c_2 = ExerciseSet(setNumber: 2, reps: 8, weight: 145)
        let set9c_3 = ExerciseSet(setNumber: 3, reps: 6, weight: 165)
        context.insert(set9c_1)
        context.insert(set9c_2)
        context.insert(set9c_3)
        we9_chest.sets = [set9c_1, set9c_2, set9c_3]
        workout4.exercises?.append(we9_chest)
        
        // Back - Rows
        let we10_back = WorkoutExercise(exercise: backRow, sets: [])
        context.insert(we10_back)
        let set10b_1 = ExerciseSet(setNumber: 1, reps: 10, weight: 145)
        let set10b_2 = ExerciseSet(setNumber: 2, reps: 8, weight: 165)
        let set10b_3 = ExerciseSet(setNumber: 3, reps: 6, weight: 185)
        context.insert(set10b_1)
        context.insert(set10b_2)
        context.insert(set10b_3)
        we10_back.sets = [set10b_1, set10b_2, set10b_3]
        workout4.exercises?.append(we10_back)
        
        // Legs - Leg Press
        let we11_legs = WorkoutExercise(exercise: legPress, sets: [])
        context.insert(we11_legs)
        let set11l_1 = ExerciseSet(setNumber: 1, reps: 12, weight: 325)
        let set11l_2 = ExerciseSet(setNumber: 2, reps: 10, weight: 375)
        let set11l_3 = ExerciseSet(setNumber: 3, reps: 8, weight: 425)
        context.insert(set11l_1)
        context.insert(set11l_2)
        context.insert(set11l_3)
        we11_legs.sets = [set11l_1, set11l_2, set11l_3]
        workout4.exercises?.append(we11_legs)
        
        // Shoulders - Shoulder Press
        let we12_shoulder = WorkoutExercise(exercise: shoulderPress, sets: [])
        context.insert(we12_shoulder)
        let set12s_1 = ExerciseSet(setNumber: 1, reps: 10, weight: 70)
        let set12s_2 = ExerciseSet(setNumber: 2, reps: 8, weight: 80)
        context.insert(set12s_1)
        context.insert(set12s_2)
        we12_shoulder.sets = [set12s_1, set12s_2]
        workout4.exercises?.append(we12_shoulder)
        
        // Arms - Bicep Curls
        let we13_bicep = WorkoutExercise(exercise: bicepCurl, sets: [])
        context.insert(we13_bicep)
        let set13b_1 = ExerciseSet(setNumber: 1, reps: 10, weight: 35)
        let set13b_2 = ExerciseSet(setNumber: 2, reps: 8, weight: 40)
        context.insert(set13b_1)
        context.insert(set13b_2)
        we13_bicep.sets = [set13b_1, set13b_2]
        workout4.exercises?.append(we13_bicep)
        
        // Nov 12, 2025 workout - Kristobolic Bday Workout
        let kristobolicComponents = DateComponents(year: 2025, month: 11, day: 12)
        let kristobolicDate = Calendar.current.date(from: kristobolicComponents)!
        let workout5 = Workout(title: "Kristobolic Bday Workout", date: kristobolicDate, duration: 5820, exercises: [])
        context.insert(workout5)
        workout5.exercises = []
        
        // 1. Bench Press - 4 sets
        let we14_bench = WorkoutExercise(exercise: benchPress, sets: [])
        context.insert(we14_bench)
        let set14_1 = ExerciseSet(setNumber: 1, reps: 2, weight: 245)
        let set14_2 = ExerciseSet(setNumber: 2, reps: 2, weight: 245)
        let set14_3 = ExerciseSet(setNumber: 3, reps: 2, weight: 245)
        let set14_4 = ExerciseSet(setNumber: 4, reps: 2, weight: 245)
        context.insert(set14_1)
        context.insert(set14_2)
        context.insert(set14_3)
        context.insert(set14_4)
        we14_bench.sets = [set14_1, set14_2, set14_3, set14_4]
        workout5.exercises?.append(we14_bench)
        
        // 2. Incline Bench Press - 1 set
        let we15_incline = WorkoutExercise(exercise: inclineBench, sets: [])
        context.insert(we15_incline)
        let set15_1 = ExerciseSet(setNumber: 1, reps: 2, weight: 225)
        context.insert(set15_1)
        we15_incline.sets = [set15_1]
        workout5.exercises?.append(we15_incline)
        
        // 3. Triceps Pushdown - 3 sets
        let we16_pushdown = WorkoutExercise(exercise: tricepPushdown, sets: [])
        context.insert(we16_pushdown)
        let set16_1 = ExerciseSet(setNumber: 1, reps: 4, weight: 135)
        let set16_2 = ExerciseSet(setNumber: 2, reps: 4, weight: 135)
        let set16_3 = ExerciseSet(setNumber: 3, reps: 4, weight: 135)
        context.insert(set16_1)
        context.insert(set16_2)
        context.insert(set16_3)
        we16_pushdown.sets = [set16_1, set16_2, set16_3]
        workout5.exercises?.append(we16_pushdown)
        
        // 4. Single Arm Crossover - 2 sets (using chest fly as substitute)
        let we17_cross = WorkoutExercise(exercise: chestFly, sets: [])
        context.insert(we17_cross)
        let set17_1 = ExerciseSet(setNumber: 1, reps: 4, weight: 35)
        let set17_2 = ExerciseSet(setNumber: 2, reps: 4, weight: 35)
        context.insert(set17_1)
        context.insert(set17_2)
        we17_cross.sets = [set17_1, set17_2]
        workout5.exercises?.append(we17_cross)
        
        // 5. Reverse Fly - 1 set
        let we18_fly = WorkoutExercise(exercise: reverseFly, sets: [])
        context.insert(we18_fly)
        let set18_1 = ExerciseSet(setNumber: 1, reps: 5, weight: 200)
        context.insert(set18_1)
        we18_fly.sets = [set18_1]
        workout5.exercises?.append(we18_fly)
        
        // 6. Shrug - 2 sets
        let we19_shrug = WorkoutExercise(exercise: shoulderShrug, sets: [])
        context.insert(we19_shrug)
        let set19_1 = ExerciseSet(setNumber: 1, reps: 4, weight: 350)
        let set19_2 = ExerciseSet(setNumber: 2, reps: 4, weight: 350)
        context.insert(set19_1)
        context.insert(set19_2)
        we19_shrug.sets = [set19_1, set19_2]
        workout5.exercises?.append(we19_shrug)
        
        // 7. Triceps Extension - 1 set
        let we20_extension = WorkoutExercise(exercise: tricepExtension, sets: [])
        context.insert(we20_extension)
        let set20_1 = ExerciseSet(setNumber: 1, reps: 6, weight: 100)
        context.insert(set20_1)
        we20_extension.sets = [set20_1]
        workout5.exercises?.append(we20_extension)
        
        // 8. Pec Deck - 1 set
        let we21_pec = WorkoutExercise(exercise: pecDeck, sets: [])
        context.insert(we21_pec)
        let set21_1 = ExerciseSet(setNumber: 1, reps: 3, weight: 200)
        context.insert(set21_1)
        we21_pec.sets = [set21_1]
        workout5.exercises?.append(we21_pec)
        
        // Create sample templates and folders
        let heavyDutyFolder = TemplateFolder(name: "Heavy Duty", createdDate: Date())
        context.insert(heavyDutyFolder)
        heavyDutyFolder.templates = []
        
        // Template 1: HEAVY DUTY PULL (Back & Biceps) - Mike Mentzer style
        // Low volume, high intensity - compound movements to failure
        let pullTemplate = WorkoutTemplate(
            name: "Heavy Pull",
            templateExercises: [
                TemplateExercise(exercise: deadlift, sets: [
                    TemplateSet(setNumber: 1, reps: 6, weight: 315),
                    TemplateSet(setNumber: 2, reps: 4, weight: 365)
                ], order: 0),
                TemplateExercise(exercise: backRow, sets: [
                    TemplateSet(setNumber: 1, reps: 8, weight: 185),
                    TemplateSet(setNumber: 2, reps: 6, weight: 205)
                ], order: 1),
                TemplateExercise(exercise: pulldown, sets: [
                    TemplateSet(setNumber: 1, reps: 10, weight: 140)
                ], order: 2),
                TemplateExercise(exercise: bicepCurl, sets: [
                    TemplateSet(setNumber: 1, reps: 8, weight: 40)
                ], order: 3)
            ],
            createdDate: Calendar.current.date(from: DateComponents(year: 2023, month: 11, day: 29))!
        )
        context.insert(pullTemplate)
        heavyDutyFolder.templates?.append(pullTemplate)
        
        // Template 2: HEAVY DUTY PUSH (Chest, Shoulders, Triceps) - Mike Mentzer style
        // Brief, intense work to complete failure
        let pushTemplate = WorkoutTemplate(
            name: "Heavy Push",
            templateExercises: [
                TemplateExercise(exercise: benchPress, sets: [
                    TemplateSet(setNumber: 1, reps: 8, weight: 185),
                    TemplateSet(setNumber: 2, reps: 6, weight: 205)
                ], order: 0),
                TemplateExercise(exercise: inclineBench, sets: [
                    TemplateSet(setNumber: 1, reps: 8, weight: 155),
                    TemplateSet(setNumber: 2, reps: 6, weight: 175)
                ], order: 1),
                TemplateExercise(exercise: shoulderPress, sets: [
                    TemplateSet(setNumber: 1, reps: 8, weight: 95)
                ], order: 2),
                TemplateExercise(exercise: lateralRaise, sets: [
                    TemplateSet(setNumber: 1, reps: 12, weight: 25)
                ], order: 3),
                TemplateExercise(exercise: dips, sets: [
                    TemplateSet(setNumber: 1, reps: 10, weight: 0)
                ], order: 4)
            ],
            createdDate: Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 27))!
        )
        context.insert(pushTemplate)
        heavyDutyFolder.templates?.append(pushTemplate)
        
        // Template 3: HEAVY DUTY LEGS - Mike Mentzer style
        // Pre-exhaust with extensions, then compound leg press to failure
        let legsTemplate = WorkoutTemplate(
            name: "Heavy Legs",
            templateExercises: [
                TemplateExercise(exercise: legExtension, sets: [
                    TemplateSet(setNumber: 1, reps: 15, weight: 120)
                ], order: 0),
                TemplateExercise(exercise: legPress, sets: [
                    TemplateSet(setNumber: 1, reps: 12, weight: 360),
                    TemplateSet(setNumber: 2, reps: 10, weight: 400)
                ], order: 1),
                TemplateExercise(exercise: squatExercise, sets: [
                    TemplateSet(setNumber: 1, reps: 8, weight: 225),
                    TemplateSet(setNumber: 2, reps: 6, weight: 275)
                ], order: 2),
                TemplateExercise(exercise: legCurl, sets: [
                    TemplateSet(setNumber: 1, reps: 12, weight: 100)
                ], order: 3)
            ],
            createdDate: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 10))!
        )
        context.insert(legsTemplate)
        heavyDutyFolder.templates?.append(legsTemplate)
        
        // Crossfit folder
        let crossfitFolder = TemplateFolder(name: "Crossfit", createdDate: Calendar.current.date(from: DateComponents(year: 2025, month: 5, day: 15))!)
        context.insert(crossfitFolder)
        crossfitFolder.templates = []
        
        // Murph WOD Template
        // Classic CrossFit Hero WOD: 1 mile run, 100 pull-ups, 200 push-ups, 300 squats, 1 mile run
        // Partitioned into 5 rounds
        let runningExercise = exercises.first(where: { $0.name.contains("Run") || $0.name.contains("Treadmill") }) ?? Exercise(name: "Running", bodyPart: "Cardio", isBuiltIn: true)
        if exercises.first(where: { $0.name.contains("Run") }) == nil {
            context.insert(runningExercise)
        }
        
        let pullUpExercise = exercises.first(where: { $0.name.contains("Pull") && $0.name.contains("Up") && !$0.name.contains("Kipping") }) ?? pulldown
        let pushUpExercise = exercises.first(where: { $0.name.contains("Push") && $0.name.contains("Up") }) ?? benchPress
        
        let murphTemplate = WorkoutTemplate(
            name: "Murph",
            templateExercises: [
                TemplateExercise(exercise: runningExercise, sets: [
                    TemplateSet(setNumber: 1, reps: 1, weight: 0)
                ], order: 0),
                TemplateExercise(exercise: pullUpExercise, sets: [
                    TemplateSet(setNumber: 1, reps: 20, weight: 0),
                    TemplateSet(setNumber: 2, reps: 20, weight: 0),
                    TemplateSet(setNumber: 3, reps: 20, weight: 0),
                    TemplateSet(setNumber: 4, reps: 20, weight: 0),
                    TemplateSet(setNumber: 5, reps: 20, weight: 0)
                ], order: 1),
                TemplateExercise(exercise: pushUpExercise, sets: [
                    TemplateSet(setNumber: 1, reps: 40, weight: 0),
                    TemplateSet(setNumber: 2, reps: 40, weight: 0),
                    TemplateSet(setNumber: 3, reps: 40, weight: 0),
                    TemplateSet(setNumber: 4, reps: 40, weight: 0),
                    TemplateSet(setNumber: 5, reps: 40, weight: 0)
                ], order: 2),
                TemplateExercise(exercise: squatExercise, sets: [
                    TemplateSet(setNumber: 1, reps: 60, weight: 0),
                    TemplateSet(setNumber: 2, reps: 60, weight: 0),
                    TemplateSet(setNumber: 3, reps: 60, weight: 0),
                    TemplateSet(setNumber: 4, reps: 60, weight: 0),
                    TemplateSet(setNumber: 5, reps: 60, weight: 0)
                ], order: 3),
                TemplateExercise(exercise: runningExercise, sets: [
                    TemplateSet(setNumber: 1, reps: 1, weight: 0)
                ], order: 4)
            ],
            createdDate: Calendar.current.date(from: DateComponents(year: 2025, month: 5, day: 25))!
        )
        context.insert(murphTemplate)
        crossfitFolder.templates?.append(murphTemplate)
        
        // Fran Template
        // Classic CrossFit benchmark: 21-15-9 reps of thrusters and pull-ups
        let thrusterExercise = exercises.first(where: { $0.name.contains("Thruster") }) ?? squatExercise
        let franTemplate = WorkoutTemplate(
            name: "Fran",
            templateExercises: [
                TemplateExercise(exercise: thrusterExercise, sets: [
                    TemplateSet(setNumber: 1, reps: 21, weight: 95),
                    TemplateSet(setNumber: 2, reps: 15, weight: 95),
                    TemplateSet(setNumber: 3, reps: 9, weight: 95)
                ], order: 0),
                TemplateExercise(exercise: pullUpExercise, sets: [
                    TemplateSet(setNumber: 1, reps: 21, weight: 0),
                    TemplateSet(setNumber: 2, reps: 15, weight: 0),
                    TemplateSet(setNumber: 3, reps: 9, weight: 0)
                ], order: 1)
            ],
            createdDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 10))!
        )
        context.insert(franTemplate)
        crossfitFolder.templates?.append(franTemplate)
        
        // Bodybuilding folder
        let bodybuildingFolder = TemplateFolder(name: "Bodybuilding", createdDate: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 15))!)
        context.insert(bodybuildingFolder)
        bodybuildingFolder.templates = []
        
        // Bodybuilding: Chest Day
        let chestDayTemplate = WorkoutTemplate(
            name: "Chest Day",
            templateExercises: [
                TemplateExercise(exercise: benchPress, sets: [
                    TemplateSet(setNumber: 1, reps: 8, weight: 185),
                    TemplateSet(setNumber: 2, reps: 8, weight: 185),
                    TemplateSet(setNumber: 3, reps: 8, weight: 185),
                    TemplateSet(setNumber: 4, reps: 8, weight: 185)
                ], order: 0),
                TemplateExercise(exercise: inclineBench, sets: [
                    TemplateSet(setNumber: 1, reps: 10, weight: 135),
                    TemplateSet(setNumber: 2, reps: 10, weight: 135),
                    TemplateSet(setNumber: 3, reps: 10, weight: 135)
                ], order: 1),
                TemplateExercise(exercise: chestFly, sets: [
                    TemplateSet(setNumber: 1, reps: 12, weight: 35),
                    TemplateSet(setNumber: 2, reps: 12, weight: 35),
                    TemplateSet(setNumber: 3, reps: 12, weight: 35)
                ], order: 2),
                TemplateExercise(exercise: dips, sets: [
                    TemplateSet(setNumber: 1, reps: 12, weight: 0),
                    TemplateSet(setNumber: 2, reps: 12, weight: 0),
                    TemplateSet(setNumber: 3, reps: 12, weight: 0)
                ], order: 3)
            ],
            createdDate: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 20))!
        )
        context.insert(chestDayTemplate)
        bodybuildingFolder.templates?.append(chestDayTemplate)
        
        // Bodybuilding: Back Day
        let backDayTemplate = WorkoutTemplate(
            name: "Back Day",
            templateExercises: [
                TemplateExercise(exercise: pulldown, sets: [
                    TemplateSet(setNumber: 1, reps: 10, weight: 140),
                    TemplateSet(setNumber: 2, reps: 10, weight: 140),
                    TemplateSet(setNumber: 3, reps: 10, weight: 140)
                ], order: 0),
                TemplateExercise(exercise: backRow, sets: [
                    TemplateSet(setNumber: 1, reps: 10, weight: 135),
                    TemplateSet(setNumber: 2, reps: 10, weight: 135),
                    TemplateSet(setNumber: 3, reps: 10, weight: 135)
                ], order: 1),
                TemplateExercise(exercise: deadlift, sets: [
                    TemplateSet(setNumber: 1, reps: 5, weight: 225),
                    TemplateSet(setNumber: 2, reps: 5, weight: 225),
                    TemplateSet(setNumber: 3, reps: 5, weight: 225)
                ], order: 2),
                TemplateExercise(exercise: bicepCurl, sets: [
                    TemplateSet(setNumber: 1, reps: 12, weight: 35),
                    TemplateSet(setNumber: 2, reps: 12, weight: 35),
                    TemplateSet(setNumber: 3, reps: 12, weight: 35)
                ], order: 3)
            ],
            createdDate: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 22))!
        )
        context.insert(backDayTemplate)
        bodybuildingFolder.templates?.append(backDayTemplate)
        
        // Bodybuilding: Leg Day
        let legDayTemplate = WorkoutTemplate(
            name: "Leg Day",
            templateExercises: [
                TemplateExercise(exercise: squatExercise, sets: [
                    TemplateSet(setNumber: 1, reps: 8, weight: 225),
                    TemplateSet(setNumber: 2, reps: 8, weight: 225),
                    TemplateSet(setNumber: 3, reps: 8, weight: 225),
                    TemplateSet(setNumber: 4, reps: 8, weight: 225)
                ], order: 0),
                TemplateExercise(exercise: legPress, sets: [
                    TemplateSet(setNumber: 1, reps: 12, weight: 360),
                    TemplateSet(setNumber: 2, reps: 12, weight: 360),
                    TemplateSet(setNumber: 3, reps: 12, weight: 360)
                ], order: 1),
                TemplateExercise(exercise: legExtension, sets: [
                    TemplateSet(setNumber: 1, reps: 15, weight: 100),
                    TemplateSet(setNumber: 2, reps: 15, weight: 100),
                    TemplateSet(setNumber: 3, reps: 15, weight: 100)
                ], order: 2),
                TemplateExercise(exercise: legCurl, sets: [
                    TemplateSet(setNumber: 1, reps: 12, weight: 90),
                    TemplateSet(setNumber: 2, reps: 12, weight: 90),
                    TemplateSet(setNumber: 3, reps: 12, weight: 90)
                ], order: 3)
            ],
            createdDate: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 24))!
        )
        context.insert(legDayTemplate)
        bodybuildingFolder.templates?.append(legDayTemplate)
        
        // Powerlifting folder
        let powerliftingFolder = TemplateFolder(name: "Powerlifting", createdDate: Calendar.current.date(from: DateComponents(year: 2024, month: 8, day: 10))!)
        context.insert(powerliftingFolder)
        powerliftingFolder.templates = []
        
        // Powerlifting: Squat Day
        let squatDayTemplate = WorkoutTemplate(
            name: "Squat Day",
            templateExercises: [
                TemplateExercise(exercise: squatExercise, sets: [
                    TemplateSet(setNumber: 1, reps: 5, weight: 225),
                    TemplateSet(setNumber: 2, reps: 5, weight: 275),
                    TemplateSet(setNumber: 3, reps: 5, weight: 315),
                    TemplateSet(setNumber: 4, reps: 3, weight: 335),
                    TemplateSet(setNumber: 5, reps: 1, weight: 365)
                ], order: 0),
                TemplateExercise(exercise: legPress, sets: [
                    TemplateSet(setNumber: 1, reps: 8, weight: 400),
                    TemplateSet(setNumber: 2, reps: 8, weight: 400),
                    TemplateSet(setNumber: 3, reps: 8, weight: 400)
                ], order: 1),
                TemplateExercise(exercise: legCurl, sets: [
                    TemplateSet(setNumber: 1, reps: 10, weight: 100),
                    TemplateSet(setNumber: 2, reps: 10, weight: 100)
                ], order: 2)
            ],
            createdDate: Calendar.current.date(from: DateComponents(year: 2024, month: 8, day: 15))!
        )
        context.insert(squatDayTemplate)
        powerliftingFolder.templates?.append(squatDayTemplate)
        
        // Powerlifting: Bench Day
        let benchDayTemplate = WorkoutTemplate(
            name: "Bench Day",
            templateExercises: [
                TemplateExercise(exercise: benchPress, sets: [
                    TemplateSet(setNumber: 1, reps: 5, weight: 185),
                    TemplateSet(setNumber: 2, reps: 5, weight: 205),
                    TemplateSet(setNumber: 3, reps: 5, weight: 225),
                    TemplateSet(setNumber: 4, reps: 3, weight: 245),
                    TemplateSet(setNumber: 5, reps: 1, weight: 275)
                ], order: 0),
                TemplateExercise(exercise: inclineBench, sets: [
                    TemplateSet(setNumber: 1, reps: 8, weight: 155),
                    TemplateSet(setNumber: 2, reps: 8, weight: 155),
                    TemplateSet(setNumber: 3, reps: 8, weight: 155)
                ], order: 1),
                TemplateExercise(exercise: tricepPushdown, sets: [
                    TemplateSet(setNumber: 1, reps: 10, weight: 100),
                    TemplateSet(setNumber: 2, reps: 10, weight: 100)
                ], order: 2)
            ],
            createdDate: Calendar.current.date(from: DateComponents(year: 2024, month: 8, day: 17))!
        )
        context.insert(benchDayTemplate)
        powerliftingFolder.templates?.append(benchDayTemplate)
        
        // Powerlifting: Deadlift Day
        let deadliftDayTemplate = WorkoutTemplate(
            name: "Deadlift Day",
            templateExercises: [
                TemplateExercise(exercise: deadlift, sets: [
                    TemplateSet(setNumber: 1, reps: 5, weight: 275),
                    TemplateSet(setNumber: 2, reps: 5, weight: 315),
                    TemplateSet(setNumber: 3, reps: 5, weight: 365),
                    TemplateSet(setNumber: 4, reps: 3, weight: 405),
                    TemplateSet(setNumber: 5, reps: 1, weight: 455)
                ], order: 0),
                TemplateExercise(exercise: backRow, sets: [
                    TemplateSet(setNumber: 1, reps: 8, weight: 185),
                    TemplateSet(setNumber: 2, reps: 8, weight: 185),
                    TemplateSet(setNumber: 3, reps: 8, weight: 185)
                ], order: 1),
                TemplateExercise(exercise: bicepCurl, sets: [
                    TemplateSet(setNumber: 1, reps: 10, weight: 40),
                    TemplateSet(setNumber: 2, reps: 10, weight: 40)
                ], order: 2)
            ],
            createdDate: Calendar.current.date(from: DateComponents(year: 2024, month: 8, day: 19))!
        )
        context.insert(deadliftDayTemplate)
        
        // Template 4: Full Body Workout (unorganized)
        let fullBodyTemplate = WorkoutTemplate(
            name: "Full Body Workout",
            exercises: [benchPress, squatExercise, pulldown, shoulderPress, bicepCurl],
            createdDate: Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 3))!
        )
        context.insert(fullBodyTemplate)

        // Preserve the display order of exercises within each sample workout.
        for workout in (try? context.fetch(FetchDescriptor<Workout>())) ?? [] {
            for (index, workoutExercise) in (workout.exercises ?? []).enumerated() {
                workoutExercise.order = index
            }
        }
    }

    /// A session in the middle of the sample "Heavy Push" workout, for previews of the active workout screens.
    static func liveWorkoutSession() -> LiveWorkoutSession {
        let session = LiveWorkoutSession(store: nil, resume: false)
        let templates = (try? shared.context.fetch(FetchDescriptor<WorkoutTemplate>())) ?? []
        session.start(LiveWorkoutBridge.start(from: templates.first { $0.name == "Heavy Push" }))
        return session
    }
}
