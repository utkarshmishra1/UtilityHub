//
//  UtilityHubApp.swift
//  UtilityHub
//
//  Created by utkarsh mishra on 21/02/26.
//

import SwiftUI
import SwiftData

@main
struct UtilityHubApp: App {
    @AppStorage(AppAccent.storageKey) private var selectedAccentRaw = AppAccent.indigo.rawValue

    private var selectedAccent: AppAccent {
        AppAccent(rawValue: selectedAccentRaw) ?? .indigo
    }

    var body: some Scene {
        WindowGroup {
            AppStartupView()
                .tint(selectedAccent.tintColor)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            UHTask.self,
            UHHabit.self,
            UHHabitCompletion.self,
            UHExpense.self,
            UHBill.self,
            UHSchedule.self,
            UHActivity.self,
            UHFocusSession.self,
            UHAttendance.self,
            UHAttendanceSubject.self,
            UHAttendanceEvent.self,
            UHGrade.self,
            UHGroceryItem.self,
            UHVehicleRecord.self,
            UHDocument.self,
            UHNote.self
        ])
    }
}
