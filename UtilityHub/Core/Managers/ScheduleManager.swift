//
//  ScheduleManager.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData

struct ScheduleManager {
    func fetchAll(context: ModelContext) -> [UHSchedule] {
        let descriptor = FetchDescriptor<UHSchedule>(sortBy: [
            SortDescriptor(\.weekday, order: .forward),
            SortDescriptor(\.startHour, order: .forward),
            SortDescriptor(\.startMinute, order: .forward)
        ])
        return (try? context.fetch(descriptor)) ?? []
    }

    func add(
        weekday: Int,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        subject: String,
        location: String,
        context: ModelContext
    ) {
        let item = UHSchedule(
            weekday: max(min(weekday, 7), 1),
            startHour: max(min(startHour, 23), 0),
            startMinute: max(min(startMinute, 59), 0),
            endHour: max(min(endHour, 23), 0),
            endMinute: max(min(endMinute, 59), 0),
            subject: subject,
            location: location
        )
        context.insert(item)
        try? context.save()
    }

    func delete(_ item: UHSchedule, context: ModelContext) {
        context.delete(item)
        try? context.save()
    }

    func todayClasses(context: ModelContext) -> [UHSchedule] {
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        return fetchAll(context: context)
            .filter { $0.weekday == todayWeekday }
            .sorted {
                if $0.startHour == $1.startHour {
                    return $0.startMinute < $1.startMinute
                }
                return $0.startHour < $1.startHour
            }
    }

    func nextClass(context: ModelContext) -> UHSchedule? {
        let schedules = fetchAll(context: context)
        let now = Date()
        return schedules.min(by: { nextOccurrence(for: $0, from: now) < nextOccurrence(for: $1, from: now) })
    }

    func nextOccurrence(for item: UHSchedule, from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)
        let currentMinutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        let itemMinutes = item.startHour * 60 + item.startMinute

        var dayOffset = item.weekday - currentWeekday
        if dayOffset < 0 {
            dayOffset += 7
        } else if dayOffset == 0 && itemMinutes <= currentMinutes {
            dayOffset = 7
        }

        let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: date) ?? date
        return calendar.date(
            bySettingHour: item.startHour,
            minute: item.startMinute,
            second: 0,
            of: baseDate
        ) ?? date
    }
}
