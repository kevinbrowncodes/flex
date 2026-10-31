import SwiftUI
import WatchKit

/// How the Digital Crown moves a value: weight in 2.5 lb steps, reps one at a time, never below 0.
enum CrownAdjust {
    static let weightStep: Double = 2.5
    static let repsStep: Double = 1

    static func snapped(_ value: Double, step: Double) -> Double {
        max(0, (value / step).rounded() * step)
    }
}

/// The workout in progress on the wrist: one vertical page per exercise, then Finish (STORY_006).
struct WatchWorkoutView: View {
    @Environment(LiveWorkoutSession.self) private var session
    @Environment(WatchDelivery.self) private var delivery
    var onFinished: (FinishedWorkout) -> Void

    @State private var page = 0
    @State private var restsFinished = 0

    var body: some View {
        if let workout = session.workout {
            TabView(selection: $page) {
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                    WatchExercisePage(exercise: exercise, workout: workout) {
                        page = min(index + 1, workout.exercises.count)
                    }
                    .tag(index)
                }
                WatchFinishPage(workout: workout, onFinish: finish)
                    .tag(workout.exercises.count)
            }
            .tabViewStyle(.verticalPage)
            // One success tap when the running rest reaches zero (STORY_003's rule, on the wrist).
            .task(id: session.workout?.rest?.endsAt) {
                guard let endsAt = session.workout?.rest?.endsAt else { return }
                let delay = endsAt.timeIntervalSinceNow
                guard delay > 0 else { return }
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled, session.workout?.rest?.endsAt == endsAt else { return }
                restsFinished += 1
                WKInterfaceDevice.current().play(.success)
            }
        }
    }

    private func finish() {
        guard let finished = session.finish() else { return }
        delivery.enqueue(finished)
        onFinished(finished)
    }
}

/// One exercise: the clock, the rest bar, the current set's weight and reps for the Crown, Done and Add Set.
struct WatchExercisePage: View {
    @Environment(LiveWorkoutSession.self) private var session
    let exercise: LiveExercise
    let workout: LiveWorkout
    var onAdvance: () -> Void

    private enum Field { case weight, reps }
    @State private var field: Field = .weight
    @State private var crown: Double = 0
    @FocusState private var crownFocused: Bool

    private var currentIndex: Int? { exercise.currentSetIndex }
    private var currentSet: LiveSet? { currentIndex.map { exercise.sets[$0] } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                header

                Text(exercise.name)
                    .font(.headline)
                    .lineLimit(2)

                if let index = currentIndex, let set = currentSet {
                    Text("Set \(index + 1) of \(exercise.sets.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("watch-set-label")
                    Text("last \(Formatting.compactSetSummary(weight: exercise.previousSet(at: index)?.weight, reps: exercise.previousSet(at: index)?.reps, time: exercise.previousSet(at: index)?.time) ?? "—")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if exercise.isCardio {
                        Text(set.time ?? "—")
                            .font(.title2)
                            .monospacedDigit()
                            .accessibilityIdentifier("watch-time")
                    } else {
                        valueRow(set)
                    }

                    Button {
                        complete(set)
                    } label: {
                        Label(set.isCompleted ? "Done ✓" : "Done", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .accessibilityIdentifier("watch-done")

                    Button {
                        session.apply(.addSet(exerciseID: exercise.id, set: LiveSet(reps: set.reps, weight: set.weight)))
                    } label: {
                        Label("Add Set", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .accessibilityIdentifier("watch-add-set")
                } else {
                    Text("No sets")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .focusable()
        .focused($crownFocused)
        .digitalCrownRotation(
            $crown,
            from: 0,
            through: field == .weight ? 2000 : 500,
            by: field == .weight ? CrownAdjust.weightStep : CrownAdjust.repsStep,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onAppear {
            crownFocused = true
            syncCrown()
        }
        .onChange(of: currentSet?.id) { _, _ in syncCrown() }
        .onChange(of: field) { _, _ in syncCrown() }
        .onChange(of: crown) { _, value in applyCrown(value) }
    }

    private var header: some View {
        HStack {
            TimelineView(.periodic(from: workout.startedAt, by: 1)) { context in
                Text(Formatting.timer(context.date.timeIntervalSince(workout.startedAt)))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let rest = workout.rest {
                TimelineView(.periodic(from: rest.startedAt, by: 1)) { context in
                    if let remaining = rest.remaining(at: context.date) {
                        HStack(spacing: 4) {
                            Image(systemName: "hourglass")
                            Text(Formatting.timer(remaining.rounded(.up)))
                                .monospacedDigit()
                                .accessibilityIdentifier("watch-rest")
                            Button("Skip") { session.apply(.skipRest) }
                                .buttonStyle(.plain)
                                .foregroundStyle(.orange)
                                .accessibilityIdentifier("watch-rest-skip")
                        }
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    /// Weight and reps side by side; the highlighted one is what the Crown changes.
    private func valueRow(_ set: LiveSet) -> some View {
        HStack(spacing: 8) {
            Button { field = .weight } label: {
                VStack(spacing: 0) {
                    Text(set.weight.map { Formatting.weight($0) } ?? "—")
                        .font(.title3)
                        .monospacedDigit()
                        .accessibilityIdentifier("watch-weight")
                    Text("lb").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(field == .weight ? .blue : .gray)
            .accessibilityLabel("Weight")
            .accessibilityValue(set.weight.map { Formatting.weight($0) } ?? "empty")

            Button { field = .reps } label: {
                VStack(spacing: 0) {
                    Text(set.reps.map { String($0) } ?? "—")
                        .font(.title3)
                        .monospacedDigit()
                        .accessibilityIdentifier("watch-reps")
                    Text("reps").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(field == .reps ? .blue : .gray)
            .accessibilityLabel("Reps")
            .accessibilityValue(set.reps.map { String($0) } ?? "empty")
        }
    }

    private func syncCrown() {
        guard let set = currentSet else { return }
        switch field {
        case .weight: crown = set.weight ?? 0
        case .reps: crown = Double(set.reps ?? 0)
        }
    }

    private func applyCrown(_ value: Double) {
        guard let set = currentSet else { return }
        switch field {
        case .weight:
            let weight = CrownAdjust.snapped(value, step: CrownAdjust.weightStep)
            if weight != (set.weight ?? 0) {
                session.apply(.setWeight(setID: set.id, weight: weight))
            }
        case .reps:
            let reps = Int(CrownAdjust.snapped(value, step: CrownAdjust.repsStep))
            if reps != (set.reps ?? 0) {
                session.apply(.setReps(setID: set.id, reps: reps))
            }
        }
    }

    private func complete(_ set: LiveSet) {
        session.apply(.setCompleted(setID: set.id, isCompleted: true))
        // Move on when this exercise has nothing left to log.
        if session.workout?.exercise(withID: exercise.id)?.allSetsCompleted == true {
            onAdvance()
        }
    }
}

/// The last page: what was done, Finish, Discard.
struct WatchFinishPage: View {
    @Environment(LiveWorkoutSession.self) private var session
    let workout: LiveWorkout
    var onFinish: () -> Void

    @State private var isConfirmingDiscard = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(workout.title)
                    .font(.headline)
                    .lineLimit(2)
                TimelineView(.periodic(from: workout.startedAt, by: 1)) { context in
                    Text(Formatting.timer(context.date.timeIntervalSince(workout.startedAt)))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Text("\(workout.completedSetCount) of \(workout.loggedSetCount) sets")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("watch-finish-sets")
                Text(Formatting.weightWithUnit(workout.totalVolume))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button(action: onFinish) {
                    Label("Finish", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .accessibilityIdentifier("watch-finish")

                Button(role: .destructive) {
                    isConfirmingDiscard = true
                } label: {
                    Text("Discard")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("watch-discard")
            }
        }
        .alert("Discard Workout?", isPresented: $isConfirmingDiscard) {
            Button("Discard Workout", role: .destructive) { session.discard() }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your logged sets will be lost.")
        }
    }
}

/// After Finish: what was done and where it is going.
struct WatchFinishedView: View {
    @Environment(WatchDelivery.self) private var delivery
    let finished: FinishedWorkout
    var onDone: () -> Void

    private var isDelivered: Bool {
        delivery.status(of: finished.workout.id) == .delivered
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("Finished")
                    .font(.headline)
                    .accessibilityIdentifier("watch-finished")
                Text("\(Formatting.duration(finished.duration)) · \(Formatting.weightWithUnit(finished.workout.totalVolume))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Label(
                    isDelivered ? "Saved to iPhone" : "Will save when your iPhone is nearby",
                    systemImage: isDelivered ? "checkmark.icloud" : "applewatch.radiowaves.left.and.right"
                )
                .font(.footnote)
                .foregroundStyle(isDelivered ? .green : .secondary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("watch-finished-status")
                Button("Done", action: onDone)
                    .accessibilityIdentifier("watch-finished-done")
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#if DEBUG
#Preview("Workout") {
    let session = LiveWorkoutSession(store: nil, resume: false)
    session.start(LiveWorkout(from: WatchSnapshot.sample.allTemplates[0], restSeconds: 90))
    return WatchWorkoutView { _ in }
        .environment(session)
        .environment(WatchDelivery(outbox: WatchOutbox(store: nil)))
}
#endif
