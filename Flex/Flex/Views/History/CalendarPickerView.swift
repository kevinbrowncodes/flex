import SwiftUI
import SwiftData

struct CalendarPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    let workouts: [Workout]

    private var workoutsForSelectedDate: [Workout] {
        workouts.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()

                    if workoutsForSelectedDate.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 50))
                                .foregroundStyle(.gray)
                            Text("No workout on this date")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 24)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(workoutsForSelectedDate.count == 1 ? "Workout on this date" : "Workouts on this date")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(workoutsForSelectedDate) { workout in
                                WorkoutHistoryCard(workout: workout, allWorkouts: workouts)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Workout Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let context = PreviewData.shared.context
    let workouts = (try? context.fetch(FetchDescriptor<Workout>())) ?? []
    return CalendarPickerView(selectedDate: .constant(Date()), workouts: workouts)
        .modelContainer(PreviewData.shared.modelContainer)
}
