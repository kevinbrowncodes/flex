import SwiftUI
import SwiftData

/// The workout in progress. Reads and edits the `LiveWorkout` held by `LiveWorkoutSession`;
/// nothing here is a SwiftData model until Finish saves it (STORY_002).
struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(LiveWorkoutSession.self) private var session
    @Environment(PhoneMirrorHost.self) private var mirrorHost

    @State private var editingTitle = false
    @State private var editedTitle = ""
    @State private var showingExerciseList = false
    @State private var showNumberPicker = false
    @State private var numberPickerType: NumberPickerType = .weight
    @State private var selectedNumber: Binding<Double?>?
    @State private var currentExerciseName: String?
    @State private var currentBarType: BarType?
    @State private var isConfirmingFinish = false
    @State private var isConfirmingDiscard = false
    @State private var finishedWorkout: Workout?
    @State private var saveError: String?
    /// The last workout shown, kept so the screen stays put under the summary after the session ends.
    @State private var lastShown: LiveWorkout?
    /// Bumped when a rest reaches zero, for the success haptic (STORY_003).
    @State private var restsFinished = 0
    /// True while Finish or Discard here ends the session, so the remote-ended check stays quiet.
    @State private var isEndingLocally = false

    private var workout: LiveWorkout? {
        session.workout ?? lastShown
    }

    var body: some View {
        NavigationStack {
            Group {
                if let workout {
                    content(workout)
                } else {
                    Color(.systemBackground)
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
                    session.apply(.rename(editedTitle))
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
            .alert("Couldn't Save Workout", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
            .sheet(isPresented: $showingExerciseList) {
                AddExerciseToWorkoutView(onAddExercises: addExercises)
            }
            .sheet(item: $finishedWorkout, onDismiss: { dismiss() }) { workout in
                WorkoutSummaryView(workout: workout)
            }
            .onAppear { lastShown = session.workout }
            .onChange(of: session.workout) { _, newValue in
                if let newValue { lastShown = newValue }
            }
            // The watch finished or discarded the workout (STORY_009): the phone's copy is saved or
            // gone already, so this screen closes.
            .onChange(of: session.isActive) { _, isActive in
                if !isActive && !isEndingLocally && finishedWorkout == nil { dismiss() }
            }
            // One success tap when the running rest reaches zero. A rest that ended while the app
            // was away gets no tap; it just is not shown.
            .task(id: session.workout?.rest?.endsAt) {
                guard let endsAt = session.workout?.rest?.endsAt else { return }
                let delay = endsAt.timeIntervalSinceNow
                guard delay > 0 else { return }
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled, session.workout?.rest?.endsAt == endsAt else { return }
                restsFinished += 1
            }
            .sensoryFeedback(.success, trigger: restsFinished)
        }
        .interactiveDismissDisabled()
    }

    private func content(_ workout: LiveWorkout) -> some View {
        VStack(spacing: 0) {
            header(workout)

            if !workout.exercises.isEmpty {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(workout.exercises) { exercise in
                            LiveExerciseSetView(
                                exercise: exercise,
                                showNumberPicker: $showNumberPicker,
                                numberPickerType: $numberPickerType,
                                selectedNumber: $selectedNumber,
                                currentExerciseName: $currentExerciseName,
                                currentBarType: $currentBarType
                            ) {
                                session.apply(.removeExercise(exerciseID: exercise.id))
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
    }

    private func header(_ workout: LiveWorkout) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(workout.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .lineLimit(2)

                Spacer()

                Menu {
                    Button(action: {
                        editedTitle = workout.title
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
                Text(workout.startedAt.formatted(date: .abbreviated, time: .omitted))
                    .foregroundStyle(.secondary)
            }
            .font(.body)

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                TimelineView(.periodic(from: workout.startedAt, by: 1)) { context in
                    Text(Formatting.timer(context.date.timeIntervalSince(workout.startedAt)))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                if mirrorHost.isLinked {
                    Spacer(minLength: 12)
                    if let heartRate = mirrorHost.watchHeartRate {
                        // Names its source, as guideline 2.5.1 asks (STORY_016, BUG_004).
                        Label("\(Int(heartRate.rounded())) · Apple Health", systemImage: "heart.fill")
                            .foregroundStyle(.red)
                            .monospacedDigit()
                            .lineLimit(1)
                            .accessibilityLabel("Heart rate \(Int(heartRate.rounded())), from Apple Health")
                            .accessibilityIdentifier("live-heart-rate")
                    }
                    Label("On watch", systemImage: "applewatch")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("live-on-watch")
                }
            }
            .font(.body)

            if let rest = workout.rest {
                TimelineView(.periodic(from: rest.startedAt, by: 1)) { context in
                    if let remaining = rest.remaining(at: context.date) {
                        restCard(remaining)
                    }
                }
            }
        }
        .padding()
    }

    /// The rest countdown with its nudges, shown while a rest is running (STORY_003).
    private func restCard(_ remaining: TimeInterval) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "hourglass")
                .foregroundStyle(.orange)
            Text("Rest")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(Formatting.timer(remaining.rounded(.up)))
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
                .accessibilityIdentifier("rest-timer")

            Spacer()

            Button("−15s") { session.apply(.adjustRest(by: -15)) }
                .accessibilityIdentifier("rest-minus")
            Button("+15s") { session.apply(.adjustRest(by: 15)) }
                .accessibilityIdentifier("rest-plus")
            Button("Skip") { session.apply(.skipRest) }
                .accessibilityIdentifier("rest-skip")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(12)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("rest-card")
    }

    private var finishMessage: String {
        guard let workout else { return "" }
        if workout.loggedSetCount == 0 {
            return "No sets have been logged yet. The workout will be saved without any exercises."
        }
        var message = "\(workout.completedSetCount) of \(workout.loggedSetCount) logged sets marked complete."
        if workout.hasEmptySets {
            message += " Empty sets will be removed."
        }
        return message
    }

    // MARK: - Actions

    private func addExercises(_ exercises: [Exercise]) {
        let startedAt = session.workout?.startedAt ?? Date()
        for exercise in exercises {
            session.apply(.addExercise(LiveWorkoutBridge.liveExercise(for: exercise, before: startedAt)))
        }
    }

    private func cancelTapped() {
        if (session.workout?.loggedSetCount ?? 0) == 0 {
            discardWorkout()
        } else {
            isConfirmingDiscard = true
        }
    }

    private func discardWorkout() {
        isEndingLocally = true
        session.discard()
        dismiss()
    }

    private func finishWorkout() {
        isEndingLocally = true
        do {
            finishedWorkout = try session.finish(into: modelContext)
        } catch {
            isEndingLocally = false
            saveError = error.localizedDescription
        }
    }
}

#Preview {
    let session = PreviewData.liveWorkoutSession()
    return ActiveWorkoutView()
        .modelContainer(PreviewData.shared.modelContainer)
        .environment(session)
        .environment(PhoneMirrorHost(session: session, healthStore: nil))
}
