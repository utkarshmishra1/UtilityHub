//
//  HomeViewModel.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    struct Snapshot {
        var tasksDone: Int = 0
        var tasksTotal: Int = 0
        var habitsDone: Int = 0
        var habitsTotal: Int = 0
        var nextClassText: String = "No classes scheduled"
    }

    struct Analytics {
        var productivityPercent: Int = 0
        var attendancePercent: Int = 0
        var longestHabitStreak: Int = 0
    }

    struct PrioritySuggestion {
        var title: String
        var detail: String
        var tab: AppTab?
    }

    @Published var snapshot = Snapshot()
    @Published var analytics = Analytics()
    @Published var attendanceTarget: Int = 75
    @Published var todayTodos: [UHTask] = []
    @Published var homeHabits: [UHHabit] = []
    @Published var streakDays: Int = 0
    @Published var prioritySuggestion = PrioritySuggestion(
        title: "You're all caught up",
        detail: "No urgent action right now. Keep your momentum.",
        tab: nil
    )

    private let taskManager = TaskManager()
    private let habitManager = HabitManager()
    private let scheduleManager = ScheduleManager()
    private let attendanceManager = AttendanceManager()
    private let activityManager = ActivityManager()
    private var homeHabitCompletionMap: [UUID: Bool] = [:]

    func refresh(context: ModelContext) {
        let allTasks = taskManager.fetchAll(context: context)
        let taskSummary = taskManager.summary(context: context)
        let habitSummary = habitManager.summary(context: context)
        let attendanceRecord = attendanceManager.fetchOrCreate(context: context)
        let attendanceTarget = attendanceRecord.targetPercentage

        snapshot.tasksDone = taskSummary.completed
        snapshot.tasksTotal = taskSummary.total
        snapshot.habitsDone = habitSummary.completed
        snapshot.habitsTotal = habitSummary.total
        self.attendanceTarget = min(max(attendanceTarget, 50), 95)
        todayTodos = taskManager.fetchForDay(Date(), context: context)
        homeHabits = habitManager.fetchAll(context: context)
        homeHabitCompletionMap = Dictionary(
            uniqueKeysWithValues: homeHabits.map { habit in
                (habit.id, habitManager.isCompletedToday(habit, context: context))
            }
        )

        if let nextClass = scheduleManager.nextClass(context: context) {
            let occurrence = scheduleManager.nextOccurrence(for: nextClass)
            snapshot.nextClassText = "\(nextClass.subject) at \(occurrence.uhShortTime)"
        } else {
            snapshot.nextClassText = "No classes scheduled"
        }

        let totalItems = taskSummary.total + habitSummary.total
        let completedItems = taskSummary.completed + habitSummary.completed
        analytics.productivityPercent = totalItems > 0 ? Int((Double(completedItems) / Double(totalItems)) * 100) : 0
        analytics.attendancePercent = attendanceManager.percentage(for: attendanceRecord)
        analytics.longestHabitStreak = habitManager.longestStreak(context: context)

        streakDays = habitManager.currentGlobalStreak(context: context)
        prioritySuggestion = buildPrioritySuggestion(
            tasks: allTasks,
            attendancePercent: analytics.attendancePercent,
            attendanceTarget: attendanceTarget,
            taskSummary: taskSummary,
            habitSummary: habitSummary
        )
    }

    func overallAttendanceColor() -> Color {
        let percent = analytics.attendancePercent
        if percent >= attendanceTarget { return .green }
        if percent >= attendanceTarget - 10 { return .orange }
        return .red
    }

    var todayTodoCompletedCount: Int {
        todayTodos.filter(\.isCompleted).count
    }

    var todayHabitCompletedCount: Int {
        homeHabits.filter { homeHabitCompletionMap[$0.id] == true }.count
    }

    func isHabitCompletedToday(_ habit: UHHabit) -> Bool {
        homeHabitCompletionMap[habit.id] ?? false
    }

    func toggleHabitForToday(_ habit: UHHabit, context: ModelContext) {
        habitManager.toggleToday(habit, context: context)
        let done = habitManager.isCompletedToday(habit, context: context)
        let action = done ? "Completed habit" : "Marked habit pending"
        activityManager.log("\(action) \(habit.title)", type: "habit", context: context)
        HapticService.tap()
        refresh(context: context)
    }

    func addTodo(title: String, context: ModelContext) {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        taskManager.create(title: cleaned, category: "ToDo", dueDate: Date(), context: context)
        activityManager.log("Added todo \(cleaned)", type: "task", context: context)
        HapticService.tap()
        refresh(context: context)
    }

    func toggleTodo(_ task: UHTask, context: ModelContext) {
        taskManager.toggle(task, context: context)
        let action = task.isCompleted ? "Completed todo" : "Marked todo pending"
        activityManager.log("\(action) \(task.title)", type: "task", context: context)
        HapticService.tap()
        refresh(context: context)
    }

    func deleteTodo(_ task: UHTask, context: ModelContext) {
        taskManager.delete(task, context: context)
        activityManager.log("Deleted todo \(task.title)", type: "task", context: context)
        HapticService.warning()
        refresh(context: context)
    }

    func handleQuickAction(_ action: HomeQuickAction, context: ModelContext) {
        switch action {
        case .addTask:
            taskManager.create(title: "Quick Task", dueDate: Date(), context: context)
            activityManager.log("Added quick task", type: "task", context: context)
            HapticService.tap()
        case .addHabit:
            HapticService.tap()
        case .addExpense:
            HapticService.tap()
        case .notes:
            HapticService.tap()
        }
        refresh(context: context)
    }

    private func buildPrioritySuggestion(
        tasks: [UHTask],
        attendancePercent: Int,
        attendanceTarget: Int,
        taskSummary: (completed: Int, total: Int),
        habitSummary: (completed: Int, total: Int)
    ) -> PrioritySuggestion {
        let overdueTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }

        if !overdueTasks.isEmpty {
            let label = overdueTasks.count == 1 ? "1 overdue task" : "\(overdueTasks.count) overdue tasks"
            return PrioritySuggestion(
                title: "Clear overdue tasks first",
                detail: "You have \(label). Finish pending work to stay on track.",
                tab: .productivity
            )
        }

        if attendancePercent < attendanceTarget {
            return PrioritySuggestion(
                title: "Attendance below target",
                detail: "You're at \(attendancePercent)%. Plan classes to stay above \(attendanceTarget)%.",
                tab: .student
            )
        }

        if taskSummary.total == 0 && habitSummary.total == 0 {
            return PrioritySuggestion(
                title: "Start your day setup",
                detail: "Add one task or habit to activate your dashboard.",
                tab: .productivity
            )
        }

        return PrioritySuggestion(
            title: "You're all caught up",
            detail: "No urgent action right now. Keep your momentum.",
            tab: nil
        )
    }
}

enum HomeQuickAction: String, CaseIterable, Identifiable {
    case addTask
    case addHabit
    case addExpense
    case notes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .addTask: return "ToDo"
        case .addHabit: return "Add Habit"
        case .addExpense: return "Expenses"
        case .notes: return "Notes"
        }
    }

    var symbol: String {
        switch self {
        case .addTask: return "checklist"
        case .addHabit: return "arrow.triangle.2.circlepath"
        case .addExpense: return "creditcard.and.123"
        case .notes: return "note.text"
        }
    }

    var tint: Color {
        switch self {
        case .addTask:
            return Color(red: 0.30, green: 0.45, blue: 0.92)
        case .addHabit:
            return Color(red: 0.28, green: 0.72, blue: 0.99)
        case .addExpense:
            return Color(red: 0.12, green: 0.73, blue: 0.69)
        case .notes:
            return Color(red: 0.95, green: 0.62, blue: 0.34)
        }
    }
}
