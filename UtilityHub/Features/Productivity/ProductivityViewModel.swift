//
//  ProductivityViewModel.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class ProductivityViewModel: ObservableObject {
    struct DayProductivity: Identifiable {
        let id = UUID()
        let label: String
        let score: Int
    }

    struct HabitSummary {
        var completedToday: Int = 0
        var total: Int = 0
        var longestStreak: Int = 0
    }

    @Published var taskFilter: TaskFilter = .all
    @Published var tasks: [UHTask] = []
    @Published var habits: [UHHabit] = []
    @Published var habitSummary = HabitSummary()
    @Published var weeklyScores: [DayProductivity] = []
    @Published var focusSessionsToday: Int = 0

    private let taskManager = TaskManager()
    private let habitManager = HabitManager()
    private let focusManager = FocusManager()
    private let activityManager = ActivityManager()

    var filteredTasks: [UHTask] {
        switch taskFilter {
        case .all:
            return tasks
        case .pending:
            return tasks.filter { !$0.isCompleted }
        case .completed:
            return tasks.filter(\.isCompleted)
        }
    }

    func refresh(context: ModelContext) {
        tasks = taskManager.fetchAll(context: context)
        habits = habitManager.fetchAll(context: context)
        let summary = habitManager.summary(context: context)
        habitSummary = HabitSummary(
            completedToday: summary.completed,
            total: summary.total,
            longestStreak: habitManager.longestStreak(context: context)
        )
        weeklyScores = buildWeeklyScores(context: context)
        focusSessionsToday = focusManager.sessionsToday(context: context)
    }

    func addTask(title: String, reminderAt: Date? = nil, context: ModelContext) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let task = taskManager.create(title: trimmed, dueDate: Date(), reminderAt: reminderAt, context: context)
        if let reminderAt {
            NotificationService.shared.scheduleTaskReminder(id: task.id, title: trimmed, fireAt: reminderAt)
        }
        activityManager.log("Added task \(trimmed)", type: "task", context: context)
        HapticService.tap()
        refresh(context: context)
    }

    func toggleTask(_ task: UHTask, context: ModelContext) {
        taskManager.toggle(task, context: context)
        if task.isCompleted {
            NotificationService.shared.cancelTaskReminder(for: task.id)
        } else if let reminderAt = task.reminderAt, reminderAt > Date() {
            NotificationService.shared.scheduleTaskReminder(id: task.id, title: task.title, fireAt: reminderAt)
        }
        let action = task.isCompleted ? "Completed" : "Marked pending"
        activityManager.log("\(action) \(task.title)", type: "task", context: context)
        HapticService.tap()
        refresh(context: context)
    }

    func deleteTask(_ task: UHTask, context: ModelContext) {
        NotificationService.shared.cancelTaskReminder(for: task.id)
        taskManager.delete(task, context: context)
        activityManager.log("Deleted task \(task.title)", type: "task", context: context)
        refresh(context: context)
    }

    func updateReminder(_ date: Date?, for task: UHTask, context: ModelContext) {
        taskManager.setReminder(date, for: task, context: context)
        if let date, date > Date() {
            NotificationService.shared.scheduleTaskReminder(id: task.id, title: task.title, fireAt: date)
        } else {
            NotificationService.shared.cancelTaskReminder(for: task.id)
        }
        let label = date == nil ? "Removed reminder for \(task.title)" : "Set reminder for \(task.title)"
        activityManager.log(label, type: "task", context: context)
        HapticService.tap()
        refresh(context: context)
    }

    func addHabit(title: String, context: ModelContext) {
        habitManager.create(title: title, targetPerDay: 1, context: context)
        activityManager.log("Added habit \(title)", type: "habit", context: context)
        refresh(context: context)
    }

    func markHabitDone(_ habit: UHHabit, context: ModelContext) {
        habitManager.markToday(habit, context: context)
        activityManager.log("Completed habit \(habit.title)", type: "habit", context: context)
        HapticService.success()
        refresh(context: context)
    }

    func completionCountToday(for habit: UHHabit, context: ModelContext) -> Int {
        habitManager.completionCountToday(for: habit, context: context)
    }

    func habitStreak(for habit: UHHabit, context: ModelContext) -> Int {
        habitManager.streak(for: habit, context: context)
    }

    func recordFocusCompletion(durationSeconds: Int, context: ModelContext) {
        focusManager.addSession(durationSeconds: durationSeconds, context: context)
        activityManager.log("Completed Pomodoro session", type: "focus", context: context)
        HapticService.success()
        refresh(context: context)
    }

    private func buildWeeklyScores(context: ModelContext) -> [DayProductivity] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -6 + offset, to: Date()) ?? Date()
            let start = date.uhDayStart
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
            let activityCount = activityManager.count(from: start, to: end, context: context)
            let taskCompletions = taskManager.completionCount(on: date, context: context)
            let score = min(max((activityCount * 8) + (taskCompletions * 12), 10), 100)
            return DayProductivity(label: formatter.string(from: date), score: score)
        }
    }
}
