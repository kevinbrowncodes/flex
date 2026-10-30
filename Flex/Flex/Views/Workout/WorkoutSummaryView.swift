import SwiftUI
import SwiftData

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var rotation: Double
    var scale: CGFloat
}

/// Celebration screen shown after a workout has been saved.
struct WorkoutSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    let workout: Workout

    @State private var animateStars = false
    @State private var animateText = false
    @State private var rotationAngles: [Double] = [0, 0, 0]
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var animateConfetti = false
    @State private var screenWidth: CGFloat = 0

    private var prCount: Int {
        workout.calculatePRCount(comparedTo: allWorkouts)
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            confetti

            ScrollView {
                VStack(spacing: 32) {
                    celebrationHeader
                    summaryCard
                }
            }

            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .padding()
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("summary-close")

                    Spacer()

                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .padding()
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()
            }
        }
    }

    private var confetti: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear { screenWidth = geometry.size.width }

            ForEach(confettiPieces) { piece in
                Circle()
                    .fill(piece.color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(piece.scale)
                    .rotationEffect(.degrees(piece.rotation))
                    .position(x: piece.x, y: animateConfetti ? geometry.size.height + 50 : piece.y)
                    .animation(
                        .easeIn(duration: Double.random(in: 1.5...3.0)).delay(Double.random(in: 0...0.3)),
                        value: animateConfetti
                    )
            }
        }
        .allowsHitTesting(false)
    }

    private var celebrationHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(0..<3) { index in
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: index == 1 ? 60 : 50))
                        .scaleEffect(animateStars ? 1.0 : 0.1)
                        .rotationEffect(.degrees(animateStars ? rotationAngles[index] : 360))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1), value: animateStars)
                }
            }

            Text("Great Job!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .scaleEffect(animateText ? 1.0 : 0.5)
                .opacity(animateText ? 1.0 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: animateText)

            Text("You completed your workout!")
                .font(.title3)
                .foregroundStyle(.secondary)
                .opacity(animateText ? 1.0 : 0)
                .animation(.easeIn(duration: 0.4).delay(0.7), value: animateText)
        }
        .padding(.top, 40)
        .onAppear {
            confettiPieces = (0..<50).map { _ in
                ConfettiPiece(
                    x: CGFloat.random(in: 0...max(screenWidth, 400)),
                    y: CGFloat.random(in: -100...100),
                    color: [.red, .blue, .green, .yellow, .orange, .pink, .purple].randomElement()!,
                    rotation: Double.random(in: 0...360),
                    scale: CGFloat.random(in: 0.5...1.5)
                )
            }
            animateStars = true
            animateText = true
            rotationAngles = [720, 1080, 720]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateConfetti = true
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(workout.title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(workout.date.formatted(date: .complete, time: .omitted))
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                    Text(Formatting.duration(workout.duration))
                }
                HStack(spacing: 8) {
                    Image(systemName: "dumbbell.fill")
                    Text(Formatting.weightWithUnit(workout.totalVolume))
                }
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                    Text("\(prCount) PR\(prCount == 1 ? "" : "s")")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Divider()
                .padding(.vertical, 4)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercise")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(workout.orderedExercises) { workoutExercise in
                        Text("\((workoutExercise.sets ?? []).count) × \(workoutExercise.exercise?.name ?? "Unknown Exercise")")
                            .font(.body)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Best Set")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(workout.orderedExercises) { workoutExercise in
                        let best = workoutExercise.bestSet ?? workoutExercise.orderedSets.first
                        Text(Formatting.setSummary(weight: best?.weight, reps: best?.reps, time: best?.time) ?? "—")
                            .font(.body)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var shareText: String {
        let exercises = workout.orderedExercises
        let totalSets = exercises.reduce(0) { $0 + ($1.sets ?? []).count }

        var text = "💪 \(workout.title)\n"
        text += "\(workout.date.formatted(date: .complete, time: .shortened))\n\n"
        text += "⏱️ Duration: \(Formatting.duration(workout.duration))\n"
        text += "🏋️ Total Volume: \(Formatting.weightWithUnit(workout.totalVolume))\n"
        text += "🏆 \(prCount) PR\(prCount == 1 ? "" : "s")\n"
        text += "📊 \(exercises.count) Exercise\(exercises.count == 1 ? "" : "s") • \(totalSets) Set\(totalSets == 1 ? "" : "s")\n\n"

        for workoutExercise in exercises {
            guard let name = workoutExercise.exercise?.name else { continue }
            text += "\(name)\n"
            for set in workoutExercise.orderedSets {
                if let summary = Formatting.setSummary(weight: set.weight, reps: set.reps, time: set.time) {
                    text += "Set \(set.setNumber): \(summary)\n"
                }
            }
            text += "\n"
        }

        text += "Flex App 💪"
        return text
    }
}

#Preview {
    let context = PreviewData.shared.context
    let workout = (try? context.fetch(FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.date, order: .reverse)])))?.first
        ?? Workout(title: "Afternoon Workout", date: Date(), duration: 3021, exercises: [])
    return WorkoutSummaryView(workout: workout)
        .modelContainer(PreviewData.shared.modelContainer)
}
