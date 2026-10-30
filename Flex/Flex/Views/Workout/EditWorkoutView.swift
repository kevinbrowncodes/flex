import SwiftUI
import SwiftData

/// Edits a saved workout in a scratch context so Cancel discards every change and Save commits them all at once.
struct EditWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var mainContext
    private let workoutID: PersistentIdentifier

    @State private var session: WorkoutEditSession?
    @State private var saveError: String?

    init(workout: Workout) {
        workoutID = workout.persistentModelID
    }

    var body: some View {
        Group {
            if let session {
                EditWorkoutForm(
                    workout: session.workout,
                    onCancel: { dismiss() },
                    onSave: {
                        do {
                            try session.save()
                            dismiss()
                        } catch {
                            saveError = error.localizedDescription
                        }
                    }
                )
                .environment(\.modelContext, session.context)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }
        }
        .task {
            if session == nil {
                session = WorkoutEditSession(container: mainContext.container, workoutID: workoutID)
            }
        }
        .alert("Couldn't Save Workout", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }
}

/// A private editing context for one workout. Nothing reaches the store until `save()` is called.
@MainActor
final class WorkoutEditSession {
    let context: ModelContext
    let workout: Workout

    init?(container: ModelContainer, workoutID: PersistentIdentifier) {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        guard let workout = context.model(for: workoutID) as? Workout else { return nil }
        self.context = context
        self.workout = workout
    }

    func save() throws {
        try context.save()
    }
}

private struct EditWorkoutForm: View {
    @Environment(\.modelContext) private var context
    @Bindable var workout: Workout
    let onCancel: () -> Void
    let onSave: () -> Void

    @State private var showingExerciseList = false
    @State private var editingTitle = false
    @State private var editedTitle = ""
    @State private var showNumberPicker = false
    @State private var numberPickerType: NumberPickerType = .weight
    @State private var selectedNumber: Binding<Double?>?
    @State private var currentExerciseName: String?
    @State private var currentBarType: BarType?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(workout.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .lineLimit(2)

                        Button(action: {
                            editedTitle = workout.title
                            editingTitle = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundStyle(.blue)
                                .padding(8)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Edit Workout Name")

                        Spacer()
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                        DatePicker("Workout Date", selection: $workout.date, displayedComponents: [.date])
                            .labelsHidden()
                    }
                    .font(.body)

                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text(Formatting.duration(workout.duration))
                            .foregroundStyle(.secondary)
                    }
                    .font(.body)
                }
                .padding()
                .background(Color(.systemGray6))

                if workout.orderedExercises.isEmpty {
                    Spacer()
                    Text("No exercises")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(workout.orderedExercises) { workoutExercise in
                                ExerciseSetView(
                                    workoutExercise: workoutExercise,
                                    showNumberPicker: $showNumberPicker,
                                    numberPickerType: $numberPickerType,
                                    selectedNumber: $selectedNumber,
                                    currentExerciseName: $currentExerciseName,
                                    currentBarType: $currentBarType,
                                    onRemove: { remove(workoutExercise) }
                                )
                            }
                        }
                        .padding()
                        .padding(.bottom, showNumberPicker ? 280 : 0)
                    }
                }

                Button(action: { showingExerciseList = true }) {
                    Text("Add Exercises")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .accessibilityIdentifier("add-exercises")
                .padding()
            }
            .overlay(alignment: .bottom) {
                if showNumberPicker, let numberBinding = selectedNumber {
                    NumberPickerView(
                        type: numberPickerType,
                        value: numberBinding,
                        isPresented: $showNumberPicker,
                        exerciseName: currentExerciseName,
                        barType: currentBarType,
                        onDone: {
                            showNumberPicker = false
                            selectedNumber = nil
                        }
                    )
                    .id("\(numberPickerType)")
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityIdentifier("edit-workout-cancel")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("edit-workout-save")
                }
            }
            .sheet(isPresented: $showingExerciseList) {
                AddExerciseToWorkoutView { exercises in
                    var order = (workout.exercises ?? []).map { $0.order }.max().map { $0 + 1 } ?? 0
                    for exercise in exercises {
                        let workoutExercise = WorkoutExercise(exercise: exercise, sets: [ExerciseSet(setNumber: 1)], order: order)
                        order += 1
                        context.insert(workoutExercise)
                        workout.exercises = (workout.exercises ?? []) + [workoutExercise]
                    }
                }
            }
            .alert("Edit Workout Name", isPresented: $editingTitle) {
                TextField("Workout Name", text: $editedTitle)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    let name = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        workout.title = name
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }

    private func remove(_ workoutExercise: WorkoutExercise) {
        workout.exercises = (workout.exercises ?? []).filter { $0.id != workoutExercise.id }
        context.delete(workoutExercise)
    }
}

#Preview {
    let context = PreviewData.shared.context
    let workout = (try? context.fetch(FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.date, order: .reverse)])))?.first
        ?? Workout(title: "Sample Workout", date: Date(), duration: 3600, exercises: [])
    return EditWorkoutView(workout: workout)
        .modelContainer(PreviewData.shared.modelContainer)
}
