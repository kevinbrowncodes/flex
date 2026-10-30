import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let template: WorkoutTemplate?

    @State private var workoutTitle: String
    @State private var editingTitle = false
    @State private var editedTitle = ""
    @State private var showingExerciseList = false
    @State private var workoutExercises: [WorkoutExercise] = []
    @State private var startTime: Date
    @State private var hasLoadedTemplate = false
    @State private var showNumberPicker = false
    @State private var numberPickerType: NumberPickerType = .weight
    @State private var selectedNumber: Binding<Double?>?
    @State private var currentExerciseName: String?
    @State private var currentBarType: BarType?
    @State private var isConfirmingFinish = false
    @State private var isConfirmingDiscard = false
    @State private var finishedWorkout: Workout?

    init(template: WorkoutTemplate? = nil) {
        self.template = template
        var start = Date()
        #if DEBUG
        start = start.addingTimeInterval(DemoMode.current?.workoutStartOffset ?? 0)
        #endif
        _startTime = State(initialValue: start)
        _workoutTitle = State(initialValue: template?.name ?? ActiveWorkoutView.defaultTitle(for: start))
    }

    /// "Morning Workout", "Afternoon Workout" or "Evening Workout" depending on the start time.
    static func defaultTitle(for date: Date, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 4..<12: return "Morning Workout"
        case 12..<17: return "Afternoon Workout"
        default: return "Evening Workout"
        }
    }

    private var loggedSetCount: Int {
        workoutExercises.flatMap { $0.sets ?? [] }.filter { !$0.isEmpty }.count
    }

    private var completedSetCount: Int {
        workoutExercises.flatMap { $0.sets ?? [] }.filter { $0.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                if !workoutExercises.isEmpty {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(workoutExercises) { workoutExercise in
                                ExerciseSetView(
                                    workoutExercise: workoutExercise,
                                    showNumberPicker: $showNumberPicker,
                                    numberPickerType: $numberPickerType,
                                    selectedNumber: $selectedNumber,
                                    currentExerciseName: $currentExerciseName,
                                    currentBarType: $currentBarType
                                ) {
                                    remove(workoutExercise)
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, showNumberPicker ? 280 : 0)
                    }
                } else {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Add an exercise to get started")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Button(action: { showingExerciseList = true }) {
                    Text("Add Exercises")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                .accessibilityIdentifier("add-exercises")
                .padding()
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: cancelTapped) {
                        Text("Cancel")
                            .foregroundStyle(.red)
                    }
                    .accessibilityIdentifier("cancel-workout")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isConfirmingFinish = true }) {
                        Text("Finish")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("finish-workout")
                }
            }
            .alert("Edit Workout Name", isPresented: $editingTitle) {
                TextField("Workout Name", text: $editedTitle)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    let name = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        workoutTitle = name
                    }
                }
            }
            // Alerts, not confirmation dialogs: iOS 26 anchors a dialog to its source on iPhone and drops
            // the cancel button, so "Keep Going" vanished (BUG_001).
            .alert("Finish Workout?", isPresented: $isConfirmingFinish) {
                Button("Finish Workout") { finishWorkout() }
                Button("Keep Going", role: .cancel) {}
            } message: {
                Text(finishMessage)
            }
            .alert("Discard Workout?", isPresented: $isConfirmingDiscard) {
                Button("Discard Workout", role: .destructive) { discardWorkout() }
                Button("Keep Going", role: .cancel) {}
            } message: {
                Text("Your logged sets will be lost.")
            }
            .onAppear(perform: loadTemplateIfNeeded)
            .sheet(isPresented: $showingExerciseList) {
                AddExerciseToWorkoutView(onAddExercises: { exercises in
                    for exercise in exercises {
                        workoutExercises.append(WorkoutExercise(exercise: exercise, sets: [ExerciseSet(setNumber: 1)], order: workoutExercises.count))
                    }
                })
            }
            .sheet(item: $finishedWorkout, onDismiss: { dismiss() }) { workout in
                WorkoutSummaryView(workout: workout)
            }
        }
        .interactiveDismissDisabled()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(workoutTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .lineLimit(2)

                Spacer()

                Menu {
                    Button(action: {
                        editedTitle = workoutTitle
                        editingTitle = true
                    }) {
                        Label("Edit Workout Name", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .accessibilityLabel("Workout options")
            }

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                Text(startTime.formatted(date: .abbreviated, time: .omitted))
                    .foregroundStyle(.secondary)
            }
            .font(.body)

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                TimelineView(.periodic(from: startTime, by: 1)) { context in
                    Text(Formatting.timer(context.date.timeIntervalSince(startTime)))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .font(.body)
        }
        .padding()
    }

    private var finishMessage: String {
        if loggedSetCount == 0 {
            return "No sets have been logged yet. The workout will be saved without any exercises."
        }
        var message = "\(completedSetCount) of \(loggedSetCount) logged sets marked complete."
        if workoutExercises.flatMap({ $0.sets ?? [] }).contains(where: { $0.isEmpty }) {
            message += " Empty sets will be removed."
        }
        return message
    }

    // MARK: - Actions

    private func loadTemplateIfNeeded() {
        guard !hasLoadedTemplate, let template else { return }
        hasLoadedTemplate = true
        workoutTitle = template.name

        workoutExercises = template.templateExercisesArray
            .sorted { $0.order < $1.order }
            .enumerated()
            .compactMap { index, templateExercise -> WorkoutExercise? in
                guard let exercise = templateExercise.exercise else { return nil }

                let templateSets = templateExercise.setsArray.sorted { $0.setNumber < $1.setNumber }
                let sets: [ExerciseSet]
                if templateSets.isEmpty {
                    sets = [ExerciseSet(setNumber: 1)]
                } else {
                    sets = templateSets.enumerated().map { setIndex, templateSet in
                        ExerciseSet(setNumber: setIndex + 1, reps: templateSet.reps, weight: templateSet.weight)
                    }
                }
                return WorkoutExercise(exercise: exercise, sets: sets, order: index)
            }
    }

    private func remove(_ workoutExercise: WorkoutExercise) {
        workoutExercises.removeAll { $0.id == workoutExercise.id }
        for (index, remaining) in workoutExercises.enumerated() {
            remaining.order = index
        }
        discard(workoutExercise)
    }

    private func cancelTapped() {
        if loggedSetCount == 0 {
            discardWorkout()
        } else {
            isConfirmingDiscard = true
        }
    }

    private func discardWorkout() {
        for workoutExercise in workoutExercises {
            discard(workoutExercise)
        }
        workoutExercises = []
        try? modelContext.save()
        dismiss()
    }

    private func finishWorkout() {
        let duration = Date().timeIntervalSince(startTime)
        var kept: [WorkoutExercise] = []

        for workoutExercise in workoutExercises {
            let loggedSets = workoutExercise.orderedSets.filter { !$0.isEmpty }
            let emptySets = (workoutExercise.sets ?? []).filter { $0.isEmpty }

            guard !loggedSets.isEmpty else {
                discard(workoutExercise)
                continue
            }

            for (index, set) in loggedSets.enumerated() {
                set.setNumber = index + 1
            }
            workoutExercise.sets = loggedSets
            for emptySet in emptySets {
                discard(emptySet)
            }
            kept.append(workoutExercise)
        }

        let workout = Workout(title: workoutTitle, date: startTime, duration: duration, exercises: kept)
        modelContext.insert(workout)
        try? modelContext.save()
        workoutExercises = []
        finishedWorkout = workout
    }

    /// Deletes a model that SwiftData may have auto-inserted when it was linked to a saved exercise.
    private func discard(_ model: some PersistentModel) {
        if model.modelContext != nil {
            modelContext.delete(model)
        }
    }
}

#Preview {
    ActiveWorkoutView()
        .modelContainer(PreviewData.shared.modelContainer)
}
