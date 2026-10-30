import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showCalendar = false
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if workouts.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 60))
                                .foregroundStyle(.gray)
                            Text("No workouts yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Complete your first workout to see it here")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                        .padding()
                    } else {
                        ForEach(monthSections, id: \.title) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(section.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                                    .padding(.top, 8)

                                ForEach(section.workouts) { workout in
                                    WorkoutHistoryCard(workout: workout, allWorkouts: workouts)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showCalendar = true }) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.blue)
                    }
                    .accessibilityLabel("Workout Calendar")
                    .accessibilityIdentifier("history-calendar")
                }
            }
            .sheet(isPresented: $showCalendar) {
                CalendarPickerView(selectedDate: $selectedDate, workouts: workouts)
            }
        }
    }

    private struct MonthSection {
        let title: String
        let workouts: [Workout]
    }

    /// Workouts grouped by month, newest month first (workouts are already sorted newest first).
    private var monthSections: [MonthSection] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var sections: [MonthSection] = []
        var index: [String: Int] = [:]
        for workout in workouts {
            let title = formatter.string(from: workout.date).uppercased()
            if let existing = index[title] {
                sections[existing] = MonthSection(title: title, workouts: sections[existing].workouts + [workout])
            } else {
                index[title] = sections.count
                sections.append(MonthSection(title: title, workouts: [workout]))
            }
        }
        return sections
    }
}

#Preview {
    HistoryView()
        .modelContainer(PreviewData.shared.modelContainer)
}
