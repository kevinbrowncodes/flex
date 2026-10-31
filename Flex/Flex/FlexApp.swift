import AppIntents
import SwiftUI
import SwiftData
import HealthKit
import os

@main
struct FlexKeyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var themeManager: ThemeManager
    @State private var authManager: AuthenticationManager
    @State private var preferencesManager: PreferencesManager
    @State private var syncMonitor: CloudKitSyncMonitor
    @State private var liveWorkoutSession: LiveWorkoutSession
    /// Sends the watch its snapshot; nil in demo launches and previews (STORY_005).
    @State private var watchLink: PhoneWatchLink?
    /// The live link to a watch showing the same workout; inert without HealthKit (STORY_009).
    @State private var mirrorHost: PhoneMirrorHost

    private let modelContainer: ModelContainer
    private let isDemo: Bool

    private static let logger = Logger(subsystem: "kevinbrowncodes.Flex", category: "App")

    static let schema = Schema([
        Exercise.self,
        Workout.self,
        WorkoutExercise.self,
        ExerciseSet.self,
        WorkoutTemplate.self,
        TemplateFolder.self,
        TemplateExercise.self,
        TemplateSet.self
    ])

    init() {
        let auth = AuthenticationManager()
        let preferences = PreferencesManager()
        let theme: ThemeManager
        let sync: CloudKitSyncMonitor
        let container: ModelContainer
        let live: LiveWorkoutSession
        let mirror: PhoneMirrorHost
        var link: PhoneWatchLink?
        var demoActive = false

        #if DEBUG
        if let demo = DemoMode.current {
            do {
                container = try demo.makeModelContainer(schema: Self.schema)
            } catch {
                fatalError("Could not create demo ModelContainer: \(error)")
            }
            demo.apply(auth: auth, preferences: preferences)
            theme = ThemeManager(initialTheme: demo.theme, persists: false)
            sync = CloudKitSyncMonitor(simulatedStatus: .synced)
            live = LiveWorkoutSession(store: .default(), resume: demo.resumesLiveWorkout)
            mirror = PhoneMirrorHost(session: live, healthStore: nil)
            demoActive = true
        } else {
            container = Self.makeModelContainer()
            theme = ThemeManager()
            sync = CloudKitSyncMonitor()
            live = LiveWorkoutSession(store: .default())
            mirror = Self.makeMirrorHost(session: live, container: container)
            link = Self.makeWatchLink(container: container, preferences: preferences)
        }
        #else
        container = Self.makeModelContainer()
        theme = ThemeManager()
        sync = CloudKitSyncMonitor()
        live = LiveWorkoutSession(store: .default())
        mirror = Self.makeMirrorHost(session: live, container: container)
        link = Self.makeWatchLink(container: container, preferences: preferences)
        #endif

        modelContainer = container
        isDemo = demoActive
        _themeManager = State(initialValue: theme)
        _authManager = State(initialValue: auth)
        _preferencesManager = State(initialValue: preferences)
        _syncMonitor = State(initialValue: sync)
        _liveWorkoutSession = State(initialValue: live)
        _watchLink = State(initialValue: link)
        _mirrorHost = State(initialValue: mirror)

        // What Siri's intent reaches for on this device (STORY_010).
        let catalog: any WorkoutCatalog = PhoneWorkoutCatalog(container: container, session: live, preferences: preferences)
        AppDependencyManager.shared.add(dependency: live)
        AppDependencyManager.shared.add(key: SiriDependencies.catalog, dependency: catalog)

        if !demoActive {
            Self.synchronizeExerciseLibrary(in: container)
        }
    }

    /// CloudKit-backed store when available, otherwise a local store; in-memory for Xcode previews.
    private static func makeModelContainer() -> ModelContainer {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview {
            let previewConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            do {
                return try ModelContainer(for: schema, configurations: [previewConfig])
            } catch {
                fatalError("Could not create preview ModelContainer: \(error)")
            }
        }

        let cloudConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
        do {
            let container = try ModelContainer(for: schema, configurations: [cloudConfig])
            logger.info("CloudKit-backed store ready")
            return container
        } catch {
            logger.error("CloudKit store unavailable, falling back to local storage: \(error.localizedDescription)")
        }

        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    /// The live link to the watch. A finish or discard arriving from the watch ends the phone's
    /// workout the way the Finish and Discard buttons do; the save is the same idempotent one.
    private static func makeMirrorHost(session: LiveWorkoutSession, container: ModelContainer) -> PhoneMirrorHost {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        let host = PhoneMirrorHost(session: session, healthStore: isPreview || !HKHealthStore.isHealthDataAvailable() ? nil : HKHealthStore())
        host.peer.onRemoteFinish = { endedAt in
            do {
                try session.finish(into: container.mainContext, at: endedAt)
            } catch {
                logger.error("Could not save the workout the watch finished: \(error.localizedDescription)")
            }
        }
        host.peer.onRemoteDiscard = { session.discard() }
        return host
    }

    /// The WatchConnectivity sender, building each snapshot from the live store and preferences.
    /// Not in Xcode previews, which have no session to talk to.
    private static func makeWatchLink(container: ModelContainer, preferences: PreferencesManager) -> PhoneWatchLink? {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return nil }
        let link = PhoneWatchLink(
            makeSnapshot: {
                try WatchSnapshotBuilder.make(
                    context: container.mainContext,
                    weeklyTarget: preferences.workoutTarget,
                    restSeconds: preferences.restSeconds,
                    userName: preferences.userName
                )
            },
            saveFinished: { try LiveWorkoutBridge.save($0, into: container.mainContext) }
        )
        link.activate()
        return link
    }

    private static func synchronizeExerciseLibrary(in container: ModelContainer) {
        do {
            let result = try ExerciseLibrary.synchronize(context: container.mainContext)
            if result.inserted > 0 || result.duplicatesMerged > 0 {
                logger.info("Exercise library synchronized: inserted \(result.inserted), merged \(result.duplicatesMerged) duplicates")
            }
        } catch {
            logger.error("Exercise library synchronization failed: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated && preferencesManager.hasSeenWelcome {
                    ContentView()
                } else {
                    WelcomeView()
                }
            }
            .preferredColorScheme(themeManager.colorScheme)
        }
        .modelContainer(modelContainer)
        .environment(themeManager)
        .environment(authManager)
        .environment(preferencesManager)
        .environment(syncMonitor)
        .environment(liveWorkoutSession)
        .environment(mirrorHost)
        .onChange(of: scenePhase) { _, newPhase in
            // CloudKit can deliver a second copy of the seeded library from another device while
            // the app is in the background; merge whenever we come back to the foreground.
            guard newPhase == .active, !isDemo else { return }
            watchLink?.scheduleSend()
            do {
                let merged = try ExerciseLibrary.mergeDuplicates(context: modelContainer.mainContext)
                if merged > 0 {
                    Self.logger.info("Merged \(merged) duplicate exercises after foreground")
                }
            } catch {
                Self.logger.error("Duplicate merge failed: \(error.localizedDescription)")
            }
        }
    }
}
