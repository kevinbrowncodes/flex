//
//  PreferencesManager.swift
//  Flex
//
//  Created by Kevin Brown on 2/8/26.
//

import Foundation

@Observable
class PreferencesManager {
    /// Posted after any preference is set here, so the watch snapshot can follow (STORY_005).
    static let didChange = Notification.Name("PreferencesManager.didChange")

    private let store = NSUbiquitousKeyValueStore.default
    private let userDefaults = UserDefaults.standard
    private var useICloud: Bool = true
    
    // Stored properties to ensure SwiftUI observation works
    var hasSeenWelcome: Bool = false
    var userName: String? = nil
    var workoutTarget: Int = 3
    var dailyTarget: Int = 1
    /// Rest after each completed set, in seconds; 0 is off (STORY_003).
    var restSeconds: TimeInterval = RestTimer.defaultSeconds

    // Keys
    private enum Keys {
        static let userName = "userName"
        static let workoutTarget = "workoutTarget"
        static let dailyTarget = "dailyTarget"
        static let restSeconds = "restSeconds"
        static let hasSeenWelcome = "hasSeenWelcome"
        static let hasMigratedToiCloud = "hasMigratedToiCloud"
    }
    
    init() {
        // Check if iCloud is available
        checkiCloudAvailability()
        
        // Migrate from UserDefaults to iCloud on first launch (if iCloud is available)
        if useICloud {
            migrateFromUserDefaults()
            
            // Sync with iCloud immediately
            store.synchronize()
            
            // Listen for iCloud changes
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleiCloudStoreChange),
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: store
            )
        }
        
        // Load stored properties from storage
        loadFromStorage()
        
        print("📱 PreferencesManager: useICloud = \(useICloud)")
        print("📱 PreferencesManager: hasSeenWelcome = \(hasSeenWelcome)")
        print("📱 PreferencesManager: userName = \(userName ?? "nil")")
    }
    
    private func checkiCloudAvailability() {
        // Test if iCloud KVS is working by trying to read
        _ = store.dictionaryRepresentation
        
        // Enable iCloud KVS for both simulator and device
        // If user is signed into iCloud, it should work
        useICloud = true
        print("📱 iCloud KVS enabled for preferences")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func loadFromStorage() {
        if useICloud {
            userName = store.string(forKey: Keys.userName)
            let targetValue = store.longLong(forKey: Keys.workoutTarget)
            workoutTarget = targetValue > 0 ? Int(targetValue) : 3
            let dailyValue = store.longLong(forKey: Keys.dailyTarget)
            dailyTarget = dailyValue > 0 ? Int(dailyValue) : 1
            restSeconds = RestTimer.seconds(stored: store.object(forKey: Keys.restSeconds))
        } else {
            userName = userDefaults.string(forKey: Keys.userName)
            let targetValue = userDefaults.integer(forKey: Keys.workoutTarget)
            workoutTarget = targetValue > 0 ? targetValue : 3
            let dailyValue = userDefaults.integer(forKey: Keys.dailyTarget)
            dailyTarget = dailyValue > 0 ? dailyValue : 1
            restSeconds = RestTimer.seconds(stored: userDefaults.object(forKey: Keys.restSeconds))
        }
        // hasSeenWelcome is always from UserDefaults (device-specific)
        hasSeenWelcome = userDefaults.bool(forKey: Keys.hasSeenWelcome)
    }
    
    @objc private func handleiCloudStoreChange(_ notification: Notification) {
        // Sync happened - reload values from storage
        loadFromStorage()
        changed()
    }

    private func changed() {
        NotificationCenter.default.post(name: Self.didChange, object: self)
    }
    
    private func migrateFromUserDefaults() {
        // Only migrate once
        guard !userDefaults.bool(forKey: Keys.hasMigratedToiCloud) else { 
            // Remove hasSeenWelcome from iCloud if it exists (cleanup from previous version)
            store.removeObject(forKey: Keys.hasSeenWelcome)
            store.synchronize()
            return 
        }
        
        // Migrate userName
        if let userName = userDefaults.string(forKey: Keys.userName) {
            store.set(userName, forKey: Keys.userName)
        }
        
        // Migrate workoutTarget
        let workoutTarget = userDefaults.integer(forKey: Keys.workoutTarget)
        if workoutTarget > 0 {
            store.set(Int64(workoutTarget), forKey: Keys.workoutTarget)
        }
        
        // Migrate dailyTarget
        let dailyTarget = userDefaults.integer(forKey: Keys.dailyTarget)
        if dailyTarget > 0 {
            store.set(Int64(dailyTarget), forKey: Keys.dailyTarget)
        }
        
        // Do NOT migrate hasSeenWelcome to iCloud - keep it device-specific
        // This ensures WelcomeView is shown on fresh installs
        
        // Remove hasSeenWelcome from iCloud if it was previously stored there
        store.removeObject(forKey: Keys.hasSeenWelcome)
        
        store.synchronize()
        userDefaults.set(true, forKey: Keys.hasMigratedToiCloud)
    }
    
    // MARK: - Public Methods to Update Properties
    
    func setUserName(_ value: String?) {
        userName = value
        if useICloud {
            if let value = value {
                store.set(value, forKey: Keys.userName)
            } else {
                store.removeObject(forKey: Keys.userName)
            }
            store.synchronize()
        } else {
            userDefaults.set(value, forKey: Keys.userName)
        }
        changed()
    }

    func setWorkoutTarget(_ value: Int) {
        workoutTarget = value
        if useICloud {
            store.set(Int64(value), forKey: Keys.workoutTarget)
            store.synchronize()
        } else {
            userDefaults.set(value, forKey: Keys.workoutTarget)
        }
        changed()
    }

    func setDailyTarget(_ value: Int) {
        dailyTarget = value
        if useICloud {
            store.set(Int64(value), forKey: Keys.dailyTarget)
            store.synchronize()
        } else {
            userDefaults.set(value, forKey: Keys.dailyTarget)
        }
        changed()
    }

    func setRestSeconds(_ value: TimeInterval) {
        restSeconds = max(0, value)
        if useICloud {
            store.set(Int64(restSeconds), forKey: Keys.restSeconds)
            store.synchronize()
        } else {
            userDefaults.set(Int64(restSeconds), forKey: Keys.restSeconds)
        }
        changed()
    }

    /// Delete Account (STORY_015): every preference back to a fresh install's (the defaults
    /// `loadFromStorage` falls back to), in iCloud and on this device, and the welcome shown again.
    func reset() {
        for key in [Keys.userName, Keys.workoutTarget, Keys.dailyTarget, Keys.restSeconds] {
            store.removeObject(forKey: key)
            userDefaults.removeObject(forKey: key)
        }
        store.synchronize()
        userName = nil
        workoutTarget = 3
        dailyTarget = 1
        restSeconds = RestTimer.defaultSeconds
        setHasSeenWelcome(false)
        changed()
    }

    // Method to update hasSeenWelcome and persist to UserDefaults
    func setHasSeenWelcome(_ value: Bool) {
        print("📱 Setting hasSeenWelcome to: \(value)")
        hasSeenWelcome = value
        userDefaults.set(value, forKey: Keys.hasSeenWelcome)
        print("📱 hasSeenWelcome saved to UserDefaults: \(value)")
    }
}
