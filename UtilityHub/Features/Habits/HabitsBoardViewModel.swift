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
