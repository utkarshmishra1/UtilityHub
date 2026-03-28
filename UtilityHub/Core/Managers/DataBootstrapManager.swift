//
//  DataBootstrapManager.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData

struct DataBootstrapManager {
    private let seededKey = "utilityhub.seeded.v9"

    func seedIfNeeded(context _: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        // Intentionally no mock data seeding on startup.
        UserDefaults.standard.set(true, forKey: seededKey)
    }
}

struct DataResetManager {
    func resetAll(context: ModelContext) {
        deleteAll(UHTask.self, context: context)
        deleteAll(UHHabitCompletion.self, context: context)
        deleteAll(UHHabit.self, context: context)
        deleteAll(UHExpense.self, context: context)
        deleteAll(UHBill.self, context: context)
        deleteAll(UHSchedule.self, context: context)
        deleteAll(UHActivity.self, context: context)
        deleteAll(UHFocusSession.self, context: context)
        deleteAll(UHAttendance.self, context: context)
        deleteAll(UHAttendanceSubject.self, context: context)
        deleteAll(UHAttendanceEvent.self, context: context)
        deleteAll(UHGrade.self, context: context)
        deleteAll(UHGroceryItem.self, context: context)
        deleteAll(UHVehicleRecord.self, context: context)
        deleteAll(UHDocument.self, context: context)
        deleteAll(UHNote.self, context: context)
        try? context.save()
        UserDefaults.standard.set(false, forKey: "utilityhub.seeded.v3")
        UserDefaults.standard.set(false, forKey: "utilityhub.seeded.v4")
        UserDefaults.standard.set(false, forKey: "utilityhub.seeded.v5")
        UserDefaults.standard.set(false, forKey: "utilityhub.seeded.v6")
        UserDefaults.standard.set(false, forKey: "utilityhub.seeded.v7")
        UserDefaults.standard.set(false, forKey: "utilityhub.seeded.v8")
        UserDefaults.standard.set(false, forKey: "utilityhub.seeded.v9")
        UserDefaults.standard.set(false, forKey: AppPreferenceKeys.hasStudentRoleSelection)
        UserDefaults.standard.removeObject(forKey: AppPreferenceKeys.isStudentModeEnabled)
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type, context: ModelContext) {
        let items = (try? context.fetch(FetchDescriptor<T>())) ?? []
        for item in items {
            context.delete(item)
        }
    }
}
