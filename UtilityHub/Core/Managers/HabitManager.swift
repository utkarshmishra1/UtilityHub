//
//  HabitManager.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData

struct HabitStreakRange: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let length: Int
}

struct HabitManager {
    func fetchAll(context: ModelContext) -> [UHHabit] {
        let descriptor = FetchDescriptor<UHHabit>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func create(
        title: String,
        targetPerDay: Int = 1,
        iconID: String? = nil,
        colorHex: String? = nil,
        context: ModelContext
    ) {
        context.insert(
            UHHabit(
                title: title,
                targetPerDay: max(targetPerDay, 1),
                iconID: iconID,
                colorHex: colorHex
            )
        )
        try? context.save()
    }

    func update(
        _ habit: UHHabit,
        title: String? = nil,
        iconID: String? = nil,
        colorHex: String? = nil,
        context: ModelContext
    ) {
        if let title {
            let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                habit.title = cleaned
            }
        }
        if let iconID { habit.iconID = iconID }
        if let colorHex { habit.colorHex = colorHex }
        try? context.save()
    }

    func markToday(_ habit: UHHabit, context: ModelContext) {
        let completion = UHHabitCompletion(habitID: habit.id, date: Date())
        context.insert(completion)
        try? context.save()
    }

    func setCompleted(_ completed: Bool, for habit: UHHabit, on day: Date = Date(), context: ModelContext) {
        let dayStart = day.uhDayStart
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        let dayCompletions = completions(for: habit, context: context).filter { $0.date >= dayStart && $0.date < dayEnd }

        if completed {
            if dayCompletions.isEmpty {
                let completionDate = Calendar.current.isDateInToday(day) ? Date() : dayStart
                context.insert(UHHabitCompletion(habitID: habit.id, date: completionDate))
            }
        } else {
            for completion in dayCompletions {
                context.delete(completion)
            }
        }
        try? context.save()
    }

    func toggleToday(_ habit: UHHabit, context: ModelContext) {
        let isCompleted = isCompleted(habit, on: Date(), context: context)
        setCompleted(!isCompleted, for: habit, on: Date(), context: context)
    }

    func delete(_ habit: UHHabit, context: ModelContext) {
        let habitCompletions = completions(for: habit, context: context)
        for completion in habitCompletions {
            context.delete(completion)
        }
        context.delete(habit)
        try? context.save()
    }

    func completionCountToday(for habit: UHHabit, context: ModelContext) -> Int {
        let dayStart = Date().uhDayStart
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? Date()
        return completions(for: habit, context: context).filter { $0.date >= dayStart && $0.date < dayEnd }.count
    }

    func isCompletedToday(_ habit: UHHabit, context: ModelContext) -> Bool {
        completionCountToday(for: habit, context: context) >= habit.targetPerDay
    }

    func isCompleted(_ habit: UHHabit, on day: Date, context: ModelContext) -> Bool {
        let dayStart = day.uhDayStart
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        return completions(for: habit, context: context).contains { item in
            item.date >= dayStart && item.date < dayEnd
        }
    }

    func summary(context: ModelContext) -> (completed: Int, total: Int) {
        let habits = fetchAll(context: context)
        let completed = habits.filter { isCompletedToday($0, context: context) }.count
        return (completed, habits.count)
    }

    func streak(for habit: UHHabit, context: ModelContext) -> Int {
        let uniqueDays = Set(completions(for: habit, context: context).map { $0.date.uhDayStart }).sorted(by: >)
        guard !uniqueDays.isEmpty else { return 0 }

        var streak = 0
        var currentDay = Date().uhDayStart
        for day in uniqueDays {
            if day == currentDay {
                streak += 1
                currentDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDay) ?? currentDay
                continue
            }

            if day == Calendar.current.date(byAdding: .day, value: -1, to: currentDay)?.uhDayStart {
                streak += 1
                currentDay = day
                currentDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDay) ?? currentDay
            } else if streak > 0 {
                break
            }
        }
        return streak
    }

    func longestStreak(context: ModelContext) -> Int {
        fetchAll(context: context).map { streak(for: $0, context: context) }.max() ?? 0
    }

    func completionDays(for habit: UHHabit, context: ModelContext) -> Set<Date> {
        Set(completions(for: habit, context: context).map { $0.date.uhDayStart })
    }

    func bestStreaks(for habit: UHHabit, limit: Int = 8, context: ModelContext) -> [HabitStreakRange] {
        let days = completionDays(for: habit, context: context).sorted()
        guard !days.isEmpty else { return [] }

        var streaks: [HabitStreakRange] = []
        var streakStart = days[0]
        var previous = days[0]
        var length = 1

        for day in days.dropFirst() {
            let expectedNext = Calendar.current.date(byAdding: .day, value: 1, to: previous)?.uhDayStart
            if day == expectedNext {
                length += 1
            } else {
                streaks.append(HabitStreakRange(start: streakStart, end: previous, length: length))
                streakStart = day
                length = 1
            }
            previous = day
        }

        streaks.append(HabitStreakRange(start: streakStart, end: previous, length: length))

        return streaks
            .sorted {
                if $0.length == $1.length {
                    return $0.end > $1.end
                }
                return $0.length > $1.length
            }
            .prefix(limit)
            .map { $0 }
    }

    func totalCompletionCount(context: ModelContext) -> Int {
        allCompletions(context: context).count
    }

    /// Returns (current week completed, previous week completed) across all habits.
    /// Each counts distinct habit-day pairs — i.e. how many "check-ins" happened.
    func weekOverWeekCompletions(context: ModelContext) -> (current: Int, previous: Int) {
        let calendar = Calendar.current
        let today = Date().uhDayStart
        guard let startOfThisWeek = calendar.date(byAdding: .day, value: -6, to: today) else {
            return (0, 0)
        }
        let endOfThisWeek = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        guard let startOfLastWeek = calendar.date(byAdding: .day, value: -13, to: today),
              let endOfLastWeek = calendar.date(byAdding: .day, value: -6, to: today) else {
            return (0, 0)
        }

        let completions = allCompletions(context: context)
        let current = completions.filter { $0.date >= startOfThisWeek && $0.date < endOfThisWeek }.count
        let previous = completions.filter { $0.date >= startOfLastWeek && $0.date < endOfLastWeek }.count
        return (current, previous)
    }

    func currentGlobalStreak(context: ModelContext) -> Int {
        let completionDays = Set(allCompletions(context: context).map { $0.date.uhDayStart })
        let today = Date().uhDayStart
        guard completionDays.contains(today) else { return 0 }

        var streak = 0
        var currentDay = today
        while completionDays.contains(currentDay) {
            streak += 1
            currentDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDay) ?? currentDay
        }
        return streak
    }

    private func completions(for habit: UHHabit, context: ModelContext) -> [UHHabitCompletion] {
        allCompletions(context: context).filter { $0.habitID == habit.id }
    }

    private func allCompletions(context: ModelContext) -> [UHHabitCompletion] {
        let descriptor = FetchDescriptor<UHHabitCompletion>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }
}
