//
//  HabitsBoardViewModel.swift
//  UtilityHub
//
//  Created by Codex on 04/03/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
final class HabitsBoardViewModel: ObservableObject {
    @Published var habits: [UHHabit] = []
    @Published var selectedHabit: UHHabit?
    @Published var detailMonth: Date = Date().uhDayStart

    private let habitManager = HabitManager()
    private let activityManager = ActivityManager()
    private var completionMap: [UUID: Set<Date>] = [:]
    private var streakMap: [UUID: [HabitStreakRange]] = [:]
    private let palette: [Color] = [
        Color(red: 0.36, green: 0.76, blue: 1.0),
        Color(red: 0.98, green: 0.56, blue: 0.74),
        Color(red: 0.98, green: 0.82, blue: 0.44),
        Color(red: 0.62, green: 0.72, blue: 1.0),
        Color(red: 0.50, green: 0.89, blue: 0.64),
        Color(red: 0.78, green: 0.66, blue: 1.0),
        Color(red: 1.0, green: 0.69, blue: 0.51)
    ]

    var weekDates: [Date] {
        let today = Date().uhDayStart
        return (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: today)?.uhDayStart
        }
    }

    func weeklyCompletedDays(for habit: UHHabit) -> Int {
        weekDates.filter { didComplete(habit, on: $0) }.count
    }

    func weeklyProgress(for habit: UHHabit) -> Double {
        Double(weeklyCompletedDays(for: habit)) / Double(max(weekDates.count, 1))
    }

    func overallWeekCompletion() -> (completed: Int, total: Int) {
        let totalCells = habits.count * weekDates.count
        guard totalCells > 0 else { return (0, 0) }
        let completedCells = habits.reduce(into: 0) { result, habit in
            result += weeklyCompletedDays(for: habit)
        }
        return (completed: completedCells, total: totalCells)
    }

    func overallWeekProgress() -> Double {
        let completion = overallWeekCompletion()
        guard completion.total > 0 else { return 0 }
        return Double(completion.completed) / Double(completion.total)
    }

    /// Days in the current month where every habit was completed, over total days in the month.
    func monthlyPerfectDaysCompletion() -> (completed: Int, total: Int) {
        let calendar = Calendar.current
        let today = Date().uhDayStart
        guard let interval = calendar.dateInterval(of: .month, for: today),
              let daysRange = calendar.range(of: .day, in: .month, for: today) else {
            return (0, 0)
        }
        let totalDays = daysRange.count
        guard !habits.isEmpty else { return (0, totalDays) }

        var perfect = 0
        var cursor = interval.start
        while cursor < interval.end {
            if cursor <= today {
                let allDone = habits.allSatisfy { didComplete($0, on: cursor) }
                if allDone { perfect += 1 }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return (perfect, totalDays)
    }

    struct DailyCompletion: Identifiable {
        let id: Date
        let date: Date
        let completed: Int
        let total: Int
        var ratio: Double { total > 0 ? Double(completed) / Double(total) : 0 }
    }

    /// Per-day completion counts for the last `count` days (oldest → newest).
    func dailyCompletionTrend(days count: Int = 14) -> [DailyCompletion] {
        let calendar = Calendar.current
        let today = Date().uhDayStart
        let total = habits.count
        return (0..<count).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today)?.uhDayStart else {
                return nil
            }
            let done = habits.filter { didComplete($0, on: day) }.count
            return DailyCompletion(id: day, date: day, completed: done, total: total)
        }
    }

    func monthlyPerfectDaysProgress() -> Double {
        let c = monthlyPerfectDaysCompletion()
        guard c.total > 0 else { return 0 }
        return Double(c.completed) / Double(c.total)
    }

    func refresh(context: ModelContext) {
        habits = habitManager.fetchAll(context: context)
        completionMap = Dictionary(
            uniqueKeysWithValues: habits.map { habit in
                (habit.id, habitManager.completionDays(for: habit, context: context))
            }
        )
        streakMap = Dictionary(
            uniqueKeysWithValues: habits.map { habit in
                (habit.id, habitManager.bestStreaks(for: habit, context: context))
            }
        )
    }

    @discardableResult
    func addHabit(title: String, context: ModelContext) -> Bool {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return false }
        habitManager.create(title: cleaned, targetPerDay: 1, context: context)
        activityManager.log("Added habit \(cleaned)", type: "habit", context: context)
        HapticService.success()
        refresh(context: context)
        return true
    }

    func toggleToday(for habit: UHHabit, context: ModelContext) {
        habitManager.toggleToday(habit, context: context)
        let done = habitManager.isCompletedToday(habit, context: context)
        let title = done ? "Completed habit \(habit.title)" : "Marked \(habit.title) pending"
        activityManager.log(title, type: "habit", context: context)
        HapticService.tap()
        refresh(context: context)
    }

    func setCompletion(_ completed: Bool, for habit: UHHabit, on day: Date, context: ModelContext) {
        habitManager.setCompleted(completed, for: habit, on: day, context: context)
        let dayStr = day.formatted(date: .abbreviated, time: .omitted)
        let title = completed
            ? "Marked \(habit.title) done on \(dayStr)"
            : "Cleared \(habit.title) on \(dayStr)"
        activityManager.log(title, type: "habit", context: context)
        HapticService.tap()
        refresh(context: context)
    }

    /// Consecutive completed days ending on (and including) `day`. 0 if `day` itself is not completed.
    func streakLength(for habit: UHHabit, endingOn day: Date) -> Int {
        guard didComplete(habit, on: day) else { return 0 }
        let calendar = Calendar.current
        var count = 0
        var cursor = day.uhDayStart
        while didComplete(habit, on: cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev.uhDayStart
        }
        return count
    }

    func deleteHabit(_ habit: UHHabit, context: ModelContext) {
        habitManager.delete(habit, context: context)
        activityManager.log("Deleted habit \(habit.title)", type: "habit", context: context)
        HapticService.warning()
        if selectedHabit?.id == habit.id {
            selectedHabit = nil
        }
        refresh(context: context)
    }

    func didComplete(_ habit: UHHabit, on day: Date) -> Bool {
        completionMap[habit.id]?.contains(day.uhDayStart) ?? false
    }

    func isToday(_ day: Date) -> Bool {
        Calendar.current.isDateInToday(day)
    }

    func color(for habit: UHHabit) -> Color {
        let seed = abs(habit.id.uuidString.hashValue)
        return palette[seed % palette.count]
    }

    func openDetail(for habit: UHHabit) {
        detailMonth = Date().uhDayStart
        selectedHabit = habit
    }

    func closeDetail() {
        selectedHabit = nil
    }

    func shiftDetailMonth(by offset: Int) {
        let shifted = Calendar.current.date(byAdding: .month, value: offset, to: detailMonth) ?? detailMonth
        detailMonth = monthStart(for: shifted)
    }

    func monthTitle() -> String {
        detailMonth.formatted(.dateTime.month(.wide).year())
    }

    func monthGrid(for month: Date? = nil) -> [Date?] {
        let targetMonth = month ?? detailMonth
        var calendar = Calendar.current
        calendar.firstWeekday = 2

        guard let interval = calendar.dateInterval(of: .month, for: targetMonth),
              let daysRange = calendar.range(of: .day, in: .month, for: targetMonth) else {
            return []
        }

        let firstDay = interval.start
        let leadingPadding = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingPadding)
        for day in daysRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    func completionCount(in month: Date, for habit: UHHabit) -> Int {
        guard let interval = Calendar.current.dateInterval(of: .month, for: month) else { return 0 }
        return completionMap[habit.id]?.filter { $0 >= interval.start && $0 < interval.end }.count ?? 0
    }

    func daysInMonth(for month: Date) -> Int {
        Calendar.current.range(of: .day, in: .month, for: month)?.count ?? 0
    }

    func streaks(for habit: UHHabit) -> [HabitStreakRange] {
        streakMap[habit.id] ?? []
    }

    func maxStreakLength(for habit: UHHabit) -> Int {
        max(streaks(for: habit).map(\.length).max() ?? 0, 1)
    }

    private func monthStart(for date: Date) -> Date {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        return Calendar.current.date(from: components)?.uhDayStart ?? Date().uhDayStart
    }
}
