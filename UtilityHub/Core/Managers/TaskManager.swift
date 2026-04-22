//
//  TaskManager.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData

struct TaskManager {
    func fetchAll(context: ModelContext) -> [UHTask] {
        let descriptor = FetchDescriptor<UHTask>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    @discardableResult
    func create(
        title: String,
        category: String = "General",
        dueDate: Date? = nil,
        reminderAt: Date? = nil,
        context: ModelContext
    ) -> UHTask {
        let task = UHTask(title: title, category: category, dueDate: dueDate, reminderAt: reminderAt)
        context.insert(task)
        try? context.save()
        return task
    }

    func setReminder(_ date: Date?, for task: UHTask, context: ModelContext) {
        task.reminderAt = date
        try? context.save()
    }

    func fetchForDay(_ day: Date = Date(), context: ModelContext) -> [UHTask] {
        let dayStart = day.uhDayStart
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

        return fetchAll(context: context)
            .filter { task in
                let referenceDate = task.dueDate ?? task.createdAt
                return referenceDate >= dayStart && referenceDate < dayEnd
            }
            .sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted {
                    return !lhs.isCompleted && rhs.isCompleted
                }
                let lhsDate = lhs.dueDate ?? lhs.createdAt
                let rhsDate = rhs.dueDate ?? rhs.createdAt
                return lhsDate > rhsDate
            }
    }

    func toggle(_ task: UHTask, context: ModelContext) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
        try? context.save()
    }

    func delete(_ task: UHTask, context: ModelContext) {
        context.delete(task)
        try? context.save()
    }

    func summary(context: ModelContext) -> (completed: Int, total: Int) {
        let tasks = fetchAll(context: context)
        return (tasks.filter(\.isCompleted).count, tasks.count)
    }

    func completionCount(on day: Date, context: ModelContext) -> Int {
        let dayStart = day.uhDayStart
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? day
        return fetchAll(context: context).filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt >= dayStart && completedAt < dayEnd
        }.count
    }
}
