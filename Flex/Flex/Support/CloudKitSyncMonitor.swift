//
//  CloudKitSyncMonitor.swift
//  Flex
//
//  Created by Kevin Brown on 2/11/26.
//

import SwiftUI
import SwiftData
import CloudKit

@Observable
class CloudKitSyncMonitor {
    var isSyncing: Bool = false
    var syncStatus: SyncStatus = .unknown
    var lastSyncDate: Date?
    var lastError: String?
    var accountStatus: CKAccountStatus = .couldNotDetermine

    enum SyncStatus {
        case unknown
        case syncing
        case synced
        case failed
        case accountUnavailable
        case networkUnavailable
    }

    private let container: CKContainer?
    private var checkTimer: Timer?

    init() {
        self.container = CKContainer(identifier: "iCloud.kevinbrowncodes.Flex")
        setupMonitoring()
        checkAccountStatus()
    }

    /// A monitor that never talks to CloudKit and reports a fixed status (previews, demos and UI tests).
    init(simulatedStatus: SyncStatus) {
        self.container = nil
        self.syncStatus = simulatedStatus
        self.accountStatus = simulatedStatus == .synced ? .available : .noAccount
        self.lastSyncDate = simulatedStatus == .synced ? Date() : nil
    }

    deinit {
        checkTimer?.invalidate()
    }

    private func setupMonitoring() {
        // SwiftData doesn't expose detailed CloudKit events, so poll account status and connectivity.
        checkTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.checkCloudKitStatus()
            }
        }
    }

    func checkAccountStatus() {
        guard let container else { return }
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.accountStatus = status

                switch status {
                case .available:
                    if self.syncStatus == .accountUnavailable || self.syncStatus == .unknown {
                        self.syncStatus = .unknown
                        self.checkCloudKitStatus()
                    }
                case .noAccount:
                    self.syncStatus = .accountUnavailable
                    self.lastError = "No iCloud account"
                case .restricted:
                    self.syncStatus = .accountUnavailable
                    self.lastError = "iCloud account restricted"
                case .couldNotDetermine:
                    self.lastError = "Could not determine iCloud status"
                case .temporarilyUnavailable:
                    self.syncStatus = .networkUnavailable
                    self.lastError = "iCloud temporarily unavailable"
                @unknown default:
                    self.lastError = "Unknown iCloud account status"
                }

                if let error {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func checkCloudKitStatus() {
        guard let container, accountStatus == .available else { return }

        // Test CloudKit connectivity by fetching zones
        container.privateCloudDatabase.fetchAllRecordZones { [weak self] _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    self.syncStatus = .failed
                    self.handleCloudKitError(error)
                } else if self.syncStatus != .synced {
                    self.syncStatus = .synced
                    self.lastSyncDate = Date()
                    self.lastError = nil
                }
            }
        }
    }

    private func handleCloudKitError(_ error: Error) {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                syncStatus = .accountUnavailable
                lastError = "Not signed in to iCloud"
            case .networkUnavailable, .networkFailure:
                syncStatus = .networkUnavailable
                lastError = "Network unavailable"
            case .quotaExceeded:
                syncStatus = .failed
                lastError = "iCloud storage full"
            case .badDatabase:
                syncStatus = .failed
                lastError = "CloudKit configuration error"
            case .internalError:
                syncStatus = .failed
                lastError = "CloudKit internal error"
            default:
                syncStatus = .failed
                lastError = "CloudKit error: \(ckError.localizedDescription)"
            }
        } else {
            syncStatus = .failed
            lastError = error.localizedDescription
        }
    }

    func forceSyncRefresh() {
        guard container != nil else { return }
        syncStatus = .unknown
        checkAccountStatus()

        // Give the account check a moment to complete before probing the database.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkCloudKitStatus()
        }
    }

    var statusDescription: String {
        switch syncStatus {
        case .unknown:
            return "Checking iCloud status..."
        case .syncing:
            return "Syncing with iCloud..."
        case .synced:
            if let date = lastSyncDate {
                return "Last checked \(formatRelativeTime(date))"
            } else {
                return "Connected to iCloud"
            }
        case .failed:
            return lastError ?? "Sync failed"
        case .accountUnavailable:
            return "Sign in to iCloud in Settings"
        case .networkUnavailable:
            return "No internet connection"
        }
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
