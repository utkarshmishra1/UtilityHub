//
//  SettingsViewModel.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    private let resetManager = DataResetManager()
    private let backupManager = BackupManager()
    private let activityManager = ActivityManager()
    @Published var backupFileURL: URL?
    @Published var backupMessage: String?

    func createBackup(context: ModelContext) {
        do {
            let url = try backupManager.createBackup(context: context)
            backupFileURL = url
            backupMessage = "Backup created: \(url.lastPathComponent)"
            activityManager.log("Created local backup", type: "settings", context: context)
        } catch {
            backupMessage = "Backup failed. Please try again."
        }
    }

    func resetAllData(context: ModelContext) {
        resetManager.resetAll(context: context)
        backupFileURL = nil
        activityManager.log("Reset all local data", type: "settings", context: context)
    }
}
