//
//  FocusManager.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData

struct FocusManager {
    func fetchAll(context: ModelContext) -> [UHFocusSession] {
        let descriptor = FetchDescriptor<UHFocusSession>(sortBy: [SortDescriptor(\.completedAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func addSession(durationSeconds: Int = 1500, context: ModelContext) {
        context.insert(UHFocusSession(durationSeconds: durationSeconds))
        try? context.save()
    }

    func sessionsToday(context: ModelContext) -> Int {
        let dayStart = Date().uhDayStart
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? Date()
        return fetchAll(context: context).filter { $0.completedAt >= dayStart && $0.completedAt < dayEnd }.count
    }
}
