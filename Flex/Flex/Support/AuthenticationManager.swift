//
//  AuthenticationManager.swift
//  Flex
//
//  Created by Kevin Brown on 2/7/26.
//

import SwiftUI
import AuthenticationServices

@Observable
class AuthenticationManager {
    private let store = NSUbiquitousKeyValueStore.default
    private let userDefaults = UserDefaults.standard

    var isAuthenticated: Bool = false
    var userIdentifier: String?
    var userEmail: String?
    var userFullName: String?

    // Keys for iCloud storage
    private enum Keys {
        static let userIdentifier = "auth_userIdentifier"
        static let userEmail = "auth_userEmail"
        static let userFullName = "auth_userFullName"
        static let hasMigratedAuth = "auth_hasMigratedToiCloud"
    }

    init() {
        // Migrate from UserDefaults to iCloud on first launch
        migrateFromUserDefaults()

        // Sync with iCloud immediately
        store.synchronize()

        // Check if user was previously authenticated (from iCloud)
        if let savedUserId = store.string(forKey: Keys.userIdentifier) {
            self.userIdentifier = savedUserId
            self.isAuthenticated = true
            self.userEmail = store.string(forKey: Keys.userEmail)
            self.userFullName = store.string(forKey: Keys.userFullName)
        }

        // Listen for iCloud changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleiCloudStoreChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleiCloudStoreChange(_ notification: Notification) {
        // Reload authentication state from iCloud if changed externally
        if let savedUserId = store.string(forKey: Keys.userIdentifier) {
            self.userIdentifier = savedUserId
            self.isAuthenticated = true
            self.userEmail = store.string(forKey: Keys.userEmail)
            self.userFullName = store.string(forKey: Keys.userFullName)
        }
    }

    private func migrateFromUserDefaults() {
        // Only migrate once
        guard !userDefaults.bool(forKey: Keys.hasMigratedAuth) else { return }

        if let userIdentifier = userDefaults.string(forKey: "userIdentifier") {
            store.set(userIdentifier, forKey: Keys.userIdentifier)
        }
        if let userEmail = userDefaults.string(forKey: "userEmail") {
            store.set(userEmail, forKey: Keys.userEmail)
        }
        if let userFullName = userDefaults.string(forKey: "userFullName") {
            store.set(userFullName, forKey: Keys.userFullName)
        }

        store.synchronize()
        userDefaults.set(true, forKey: Keys.hasMigratedAuth)

        userDefaults.removeObject(forKey: "userIdentifier")
        userDefaults.removeObject(forKey: "userEmail")
        userDefaults.removeObject(forKey: "userFullName")
    }

    /// Joins whichever name components Apple provided ("Kevin", "Brown", or "Kevin Brown").
    static func displayName(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        let parts = [components.givenName, components.familyName]
            .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                return
            }
            let userId = appleIDCredential.user

            // Apple only sends the email and name on the very first authorization for this account,
            // so keep whatever was stored previously when they are missing.
            let email = appleIDCredential.email ?? store.string(forKey: Keys.userEmail)
            let fullName = Self.displayName(from: appleIDCredential.fullName) ?? store.string(forKey: Keys.userFullName)

            self.userIdentifier = userId
            self.userEmail = email
            self.userFullName = fullName

            store.set(userId, forKey: Keys.userIdentifier)
            if let email {
                store.set(email, forKey: Keys.userEmail)
            }
            if let fullName {
                store.set(fullName, forKey: Keys.userFullName)

                // Also set as userName in PreferencesManager if it doesn't exist yet
                if store.string(forKey: "userName") == nil {
                    store.set(fullName, forKey: "userName")
                }
            }

            store.synchronize()
            self.isAuthenticated = true

        case .failure:
            break
        }
    }

    func signOut() {
        self.isAuthenticated = false
        self.userIdentifier = nil
        self.userEmail = nil
        self.userFullName = nil

        store.removeObject(forKey: Keys.userIdentifier)
        store.removeObject(forKey: Keys.userEmail)
        store.removeObject(forKey: Keys.userFullName)
        store.synchronize()
    }
}
