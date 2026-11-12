import HealthKit
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(CloudKitSyncMonitor.self) private var syncMonitor
    @Environment(PreferencesManager.self) private var preferences
    @Environment(LiveWorkoutSession.self) private var liveSession
    @Environment(\.modelContext) private var modelContext
    @State private var showLogOutAlert = false
    @State private var showDeleteAlert = false
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("iCloud Sync", systemImage: "icloud")
                        Spacer()
                        syncStatusBadge
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        syncMonitor.forceSyncRefresh()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("Refreshes the sync status")

                    Text(syncMonitor.statusDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let error = syncMonitor.lastError,
                       syncMonitor.syncStatus == .failed || syncMonitor.syncStatus == .accountUnavailable {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.top, 2)
                    }
                } header: {
                    Text("Data & Sync")
                } footer: {
                    Text("Tap to refresh sync status. Make sure you're signed into iCloud in Settings and have enabled iCloud for this app.")
                        .font(.caption)
                }

                Section {
                    Picker("Rest Timer", selection: Binding(
                        get: { preferences.restSeconds },
                        set: { preferences.setRestSeconds($0) }
                    )) {
                        ForEach(RestTimer.options, id: \.self) { seconds in
                            Text(RestTimer.label(seconds)).tag(seconds)
                        }
                    }
                    .accessibilityIdentifier("rest-timer-default")
                } header: {
                    Text("Workout")
                } footer: {
                    Text("Ticking a set starts a rest countdown. Change it mid-workout from the timer itself.")
                        .font(.caption)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("Apple Health")
                                .font(.headline)
                        } icon: {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                        }
                        Text(Self.healthExplanation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("apple-health-info")

                    if HKHealthStore.isHealthDataAvailable(), let health = URL(string: "x-apple-health://") {
                        Link(destination: health) {
                            Label("Open Health", systemImage: "arrow.up.forward.app")
                        }
                        .accessibilityIdentifier("open-health")
                    }
                } header: {
                    Text("Apple Health")
                }

                Section("Appearance") {
                    NavigationLink(destination: ThemeSelectionView()) {
                        HStack {
                            Text("Theme")
                            Spacer()
                            Text(themeManager.selectedTheme)
                                .foregroundStyle(.blue)
                        }
                    }
                }

                Section("Support") {
                    Link(destination: AppLinks.support) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    Link(destination: AppLinks.issues) {
                        Label("Report a Problem", systemImage: "exclamationmark.bubble")
                    }
                }

                Section("Legal") {
                    Link(destination: AppLinks.privacyPolicy) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    NavigationLink(destination: TermsOfServiceView()) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }

                Section("About") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Made by two fitness freaks 💪")
                            .font(.headline)
                        Text(AppLinks.creators)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("about-creators")
                }

                Section {
                    Button("Log Out") {
                        showLogOutAlert = true
                    }
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("log-out")
                    Button("Delete Account") {
                        showDeleteAlert = true
                    }
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("delete-account")
                } header: {
                    Text("Account")
                } footer: {
                    VStack(spacing: 8) {
                        Text("Deleting erases your data from this device and iCloud.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Flex \(AppLinks.versionDescription)")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .alert("Log Out", isPresented: $showLogOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    authManager.signOut()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to log out? Your workouts stay in iCloud.")
            }
            .alert("Delete Account?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Account", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text(Self.deleteWarning)
            }
            .alert("Couldn't Delete Account", isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteError ?? "")
            }
        }
    }

    /// What Flex does with Apple Health, in the words App Review looks for (STORY_016, BUG_004).
    static let healthExplanation = "Flex works with Apple Health. A workout you do with Flex on Apple Watch is saved to Apple Health with your heart rate and active calories, if you allow it. Flex reads heart rate only during a watch workout and never copies Health data into its own storage."

    static let deleteWarning = "Every workout, template and custom exercise is erased from this device and iCloud, your preferences are reset, and you're signed out. This can't be undone. Workouts already in Apple Health stay there."

    /// Delete Account (STORY_015, BUG_003). A failed erase signs nobody out.
    private func deleteAccount() {
        do {
            try AccountEraser.eraseAccount(context: modelContext, session: liveSession,
                                           preferences: preferences, auth: authManager)
            dismiss()
        } catch {
            deleteError = error.localizedDescription
        }
    }

    @ViewBuilder
    private var syncStatusBadge: some View {
        switch syncMonitor.syncStatus {
        case .syncing:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Syncing...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .synced:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                if let lastSync = syncMonitor.lastSyncDate {
                    Text("Synced \(lastSync, format: .relative(presentation: .named))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        case .failed:
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Failed")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        case .accountUnavailable:
            HStack(spacing: 4) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .foregroundStyle(.red)
                Text("Sign In Required")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        case .networkUnavailable:
            HStack(spacing: 4) {
                Image(systemName: "wifi.slash")
                    .foregroundStyle(.gray)
                Text("Offline")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        case .unknown:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Checking...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ThemeSelectionView: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        List {
            ForEach(ThemeManager.options, id: \.self) { theme in
                Button(action: { themeManager.selectedTheme = theme }) {
                    HStack {
                        Text(theme)
                            .foregroundStyle(.primary)
                        Spacer()
                        if themeManager.selectedTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .accessibilityAddTraits(themeManager.selectedTheme == theme ? .isSelected : [])
            }
        }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environment(ThemeManager())
        .environment(AuthenticationManager())
        .environment(CloudKitSyncMonitor(simulatedStatus: .synced))
        .environment(PreferencesManager())
        .environment(LiveWorkoutSession(store: nil))
        .modelContainer(PreviewData.shared.modelContainer)
}
