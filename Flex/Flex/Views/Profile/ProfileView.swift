import SwiftUI
import SwiftData
import Charts

struct WeeklyWorkoutData: Identifiable {
    let id = UUID()
    let weekStart: String
    let count: Int
}

struct DailyWorkoutData: Identifiable {
    let id = UUID()
    let day: String
    let count: Int
}

struct ProfileView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(PreferencesManager.self) private var preferencesManager
    @Query private var workouts: [Workout]
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showSetTarget = false
    @State private var showSetDailyTarget = false

    private var userName: String {
        // Priority: userName (user set) > userFullName (from Apple) > default
        if let customName = preferencesManager.userName, !customName.isEmpty {
            return customName
        } else if let appleName = authManager.userFullName, !appleName.isEmpty {
            return appleName
        } else {
            return "User"
        }
    }

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday
        return calendar
    }

    /// Workouts logged so far this week (Sunday–today).
    var currentWeekWorkouts: Int {
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        return workouts.filter { $0.date >= startOfWeek && $0.date <= now }.count
    }

    var todayWorkouts: Int {
        workouts.filter { calendar.isDateInToday($0.date) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    profileHeader

                    Text("Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    dailyWidget
                    weeklyWidget
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.blue)
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("open-settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .overlay {
                if showSetTarget {
                    targetOverlay {
                        SetWorkoutTargetView(isPresented: $showSetTarget)
                    } dismiss: {
                        showSetTarget = false
                    }
                }

                if showSetDailyTarget {
                    targetOverlay {
                        SetDailyTargetView(isPresented: $showSetDailyTarget)
                    } dismiss: {
                        showSetDailyTarget = false
                    }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSetTarget)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSetDailyTarget)
        }
    }

    // MARK: - Sections

    private var profileHeader: some View {
        Button(action: { showEditProfile = true }) {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(userName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("\(workouts.count) workout\(workouts.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.blue)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("edit-profile")
    }

    private var dailyWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Workouts This Week")
                        .font(.headline)
                    Text("Goal: \(preferencesManager.dailyTarget) per day")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: { showSetDailyTarget = true }) {
                    Image(systemName: "target")
                        .foregroundStyle(.blue)
                }
                .accessibilityLabel("Set daily target")
                .accessibilityIdentifier("set-daily-target")
            }

            HStack {
                Spacer()
                Text("\(currentWeekWorkouts)")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .accessibilityLabel("\(currentWeekWorkouts) workouts this week")
            }

            let dailyData = dailyWorkoutData()
            if dailyData.contains(where: { $0.count > 0 }) {
                Chart(dailyData) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Workouts", data.count)
                    )
                    .foregroundStyle(.blue)
                    .cornerRadius(4)

                    RuleMark(y: .value("Goal", preferencesManager.dailyTarget))
                        .foregroundStyle(Color.blue.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .trailing, alignment: .center) {
                            Text("\(preferencesManager.dailyTarget)")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let stringValue = value.as(String.self) {
                                Text(stringValue)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 100)
            } else {
                Text("No workouts this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 100)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var weeklyWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Workouts Per Week")
                        .font(.headline)
                    Text("Goal: \(preferencesManager.workoutTarget) per week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: { showSetTarget = true }) {
                    Image(systemName: "target")
                        .foregroundStyle(.blue)
                }
                .accessibilityLabel("Set weekly target")
                .accessibilityIdentifier("set-weekly-target")
            }

            HStack {
                Spacer()
                Text("\(currentWeekWorkouts) / \(preferencesManager.workoutTarget)")
                    .font(.title3)
                    .foregroundStyle(currentWeekWorkouts >= preferencesManager.workoutTarget ? .green : .blue)
                    .accessibilityLabel("\(currentWeekWorkouts) of \(preferencesManager.workoutTarget) this week")
            }

            let weeklyData = weeklyWorkoutData()
            if weeklyData.contains(where: { $0.count > 0 }) {
                Chart(weeklyData) { data in
                    BarMark(
                        x: .value("Week", data.weekStart),
                        y: .value("Workouts", data.count)
                    )
                    .foregroundStyle(.blue)
                    .cornerRadius(4)

                    RuleMark(y: .value("Goal", preferencesManager.workoutTarget))
                        .foregroundStyle(Color.blue.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .trailing, alignment: .center) {
                            Text("\(preferencesManager.workoutTarget)")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let stringValue = value.as(String.self) {
                                Text(stringValue)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 120)
            } else {
                Text("No workout data available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 120)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func targetOverlay<Content: View>(@ViewBuilder content: () -> Content, dismiss: @escaping () -> Void) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: dismiss)

            content()
                .frame(width: 350)
                .padding(.horizontal, 32)
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Chart data

    /// One entry per day of the current week (Sunday–Saturday).
    func dailyWorkoutData(now: Date = Date()) -> [DailyWorkoutData] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "M/d"

        return (0..<7).compactMap { dayOffset in
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekInterval.start) else { return nil }
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let count = workouts.filter { $0.date >= dayStart && $0.date < dayEnd }.count
            return DailyWorkoutData(day: dayFormatter.string(from: day), count: count)
        }
    }

    /// One entry per week for the last 8 weeks, oldest first.
    func weeklyWorkoutData(now: Date = Date()) -> [WeeklyWorkoutData] {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"

        return (0..<8).reversed().compactMap { weekOffset in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                  let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else { return nil }
            let count = workouts.filter { $0.date >= weekInterval.start && $0.date < weekInterval.end }.count
            return WeeklyWorkoutData(weekStart: formatter.string(from: weekInterval.start), count: count)
        }
    }
}

#Preview {
    ProfileView()
        .environment(ThemeManager())
        .environment(AuthenticationManager())
        .environment(PreferencesManager())
        .modelContainer(PreviewData.shared.modelContainer)
}
