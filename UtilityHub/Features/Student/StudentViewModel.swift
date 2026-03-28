//
//  StudentViewModel.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

struct AttendanceDaySummary {
    var present: Int = 0
    var absent: Int = 0

    var total: Int {
        present + absent
    }
}

@MainActor
final class StudentViewModel: ObservableObject {
    @Published var attendanceRecord: UHAttendance?
    @Published var subjects: [UHAttendanceSubject] = []
    @Published var schedules: [UHSchedule] = []
    @Published var selectedWeekday: Int = Calendar.current.component(.weekday, from: Date())
    @Published var reportMonth: Date = Date()
    @Published var reportSelectedDate: Date = Date()
    @Published var reportEvents: [UHAttendanceEvent] = []
    @Published var activeReportSubjectID: UUID?

    private let scheduleManager = ScheduleManager()
    private let attendanceManager = AttendanceManager()
    private let activityManager = ActivityManager()

    func refresh(context: ModelContext) {
        attendanceRecord = attendanceManager.fetchOrCreate(context: context)
        subjects = attendanceManager.fetchSubjects(context: context)
        schedules = scheduleManager.fetchAll(context: context)
        syncReportSelection(context: context)
    }

    func targetPercentage() -> Int {
        let value = attendanceRecord?.targetPercentage ?? 75
        return min(max(value, 50), 95)
    }

    func totalAttendancePercent() -> Int {
        guard let attendanceRecord else { return 0 }
        return attendanceManager.percentage(for: attendanceRecord)
    }

    func totalAttendancePercentText() -> String {
        "\(totalAttendancePercent())%"
    }

    func overallProgressColor() -> Color {
        let percent = totalAttendancePercent()
        let target = targetPercentage()
        if percent >= target { return .green }
        if percent >= target - 10 { return .orange }
        return .red
    }

    func summaryDateText() -> String {
        Date().formatted(date: .abbreviated, time: .omitted)
    }

    @discardableResult
    func addSubject(name: String, attended: Int, total: Int, context: ModelContext) -> Bool {
        guard attendanceManager.addSubject(name: name, attended: attended, total: total, context: context) != nil else {
            return false
        }
        activityManager.log("Added subject \(name)", type: "attendance", context: context)
        HapticService.success()
        refresh(context: context)
        return true
    }

    func markPresent(for subject: UHAttendanceSubject, context: ModelContext) {
        attendanceManager.mark(subject: subject, present: true, context: context)
        activityManager.log("Marked \(subject.name) present", type: "attendance", context: context)
        HapticService.tap()
        refresh(context: context)
    }

    func markAbsent(for subject: UHAttendanceSubject, context: ModelContext) {
        attendanceManager.mark(subject: subject, present: false, context: context)
        activityManager.log("Marked \(subject.name) absent", type: "attendance", context: context)
        HapticService.warning()
        refresh(context: context)
    }

    func updateTarget(_ target: Int, context: ModelContext) {
        attendanceManager.setTarget(target, context: context)
        activityManager.log("Updated target to \(target)%", type: "attendance", context: context)
        HapticService.success()
        refresh(context: context)
    }

    func updateSubject(
        _ subject: UHAttendanceSubject,
        name: String,
        attended: Int,
        total: Int,
        context: ModelContext
    ) {
        attendanceManager.updateSubject(subject, name: name, attended: attended, total: total, context: context)
        activityManager.log("Edited \(name) attendance", type: "attendance", context: context)
        HapticService.tap()
        refresh(context: context)
    }

    func resetSubject(_ subject: UHAttendanceSubject, context: ModelContext) {
        attendanceManager.resetSubject(subject, context: context)
        activityManager.log("Reset \(subject.name) attendance", type: "attendance", context: context)
        HapticService.warning()
        refresh(context: context)
    }

    func deleteSubject(_ subject: UHAttendanceSubject, context: ModelContext) {
        attendanceManager.deleteSubject(subject, context: context)
        activityManager.log("Deleted \(subject.name)", type: "attendance", context: context)
        HapticService.warning()
        refresh(context: context)
    }

    func attendanceCountText(for subject: UHAttendanceSubject) -> String {
        "\(subject.attendedClasses)/\(subject.totalClasses)"
    }

    func percentage(for subject: UHAttendanceSubject) -> Int {
        attendanceManager.percentage(for: subject)
    }

    func statusText(for subject: UHAttendanceSubject) -> String {
        attendanceManager.statusText(for: subject, target: targetPercentage())
    }

    func progressColor(for subject: UHAttendanceSubject) -> Color {
        let percent = percentage(for: subject)
        let target = targetPercentage()
        if percent >= target { return .green }
        if percent >= target - 10 { return .orange }
        return .red
    }

    func classesCanMiss(for subject: UHAttendanceSubject) -> Int {
        attendanceManager.classesCanMiss(for: subject, target: targetPercentage())
    }

    func classesNeeded(for subject: UHAttendanceSubject) -> Int {
        attendanceManager.classesNeeded(for: subject, target: targetPercentage())
    }

    func classes(for weekday: Int) -> [UHSchedule] {
        schedules
            .filter { $0.weekday == weekday }
            .sorted {
                if $0.startHour == $1.startHour {
                    return $0.startMinute < $1.startMinute
                }
                return $0.startHour < $1.startHour
            }
    }

    func addSchedule(
        weekday: Int,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        subject: String,
        location: String,
        context: ModelContext
    ) {
        let cleanedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedSubject.isEmpty else { return }
        scheduleManager.add(
            weekday: weekday,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            subject: cleanedSubject,
            location: location,
            context: context
        )
        activityManager.log("Added class \(cleanedSubject)", type: "schedule", context: context)
        HapticService.success()
        refresh(context: context)
    }

    func deleteSchedule(_ item: UHSchedule, context: ModelContext) {
        scheduleManager.delete(item, context: context)
        activityManager.log("Deleted \(item.subject) class", type: "schedule", context: context)
        HapticService.warning()
        refresh(context: context)
    }

    func startTimeText(for item: UHSchedule) -> String {
        let date = Calendar.current.date(bySettingHour: item.startHour, minute: item.startMinute, second: 0, of: Date()) ?? Date()
        return date.uhShortTime
    }

    func endTimeText(for item: UHSchedule) -> String {
        let date = Calendar.current.date(bySettingHour: item.endHour, minute: item.endMinute, second: 0, of: Date()) ?? Date()
        return date.uhShortTime
    }

    func weekdayName(_ weekday: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        let index = max(min(weekday - 1, symbols.count - 1), 0)
        return symbols[index]
    }

    func shortWeekdayName(_ weekday: Int) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols
        let index = max(min(weekday - 1, symbols.count - 1), 0)
        return symbols[index]
    }

    func openReport(for subjectID: UUID, context: ModelContext) {
        activeReportSubjectID = subjectID
        reportEvents = attendanceManager.events(for: subjectID, context: context)
        reportMonth = monthStart(for: Date())
        reportSelectedDate = Date().uhDayStart
    }

    func shiftReportMonth(by monthOffset: Int) {
        reportMonth = monthStart(
            for: Calendar.current.date(byAdding: .month, value: monthOffset, to: reportMonth) ?? reportMonth
        )
        alignSelectedReportDateWithMonth()
    }

    func selectReportDate(_ date: Date) {
        reportSelectedDate = date.uhDayStart
    }

    func monthSummaryMap(for month: Date) -> [Date: AttendanceDaySummary] {
        var summaryMap: [Date: AttendanceDaySummary] = [:]
        let calendar = Calendar.current
        for event in reportEvents {
            guard calendar.isDate(event.date, equalTo: month, toGranularity: .month) else { continue }
            let key = event.date.uhDayStart
            var current = summaryMap[key] ?? AttendanceDaySummary()
            if event.isPresent {
                current.present += 1
            } else {
                current.absent += 1
            }
            summaryMap[key] = current
        }
        return summaryMap
    }

    func summary(for date: Date) -> AttendanceDaySummary {
        let day = date.uhDayStart
        var result = AttendanceDaySummary()
        for event in reportEvents where Calendar.current.isDate(event.date, inSameDayAs: day) {
            if event.isPresent {
                result.present += 1
            } else {
                result.absent += 1
            }
        }
        return result
    }

    private func syncReportSelection(context: ModelContext) {
        reportMonth = monthStart(for: reportMonth)
        reportSelectedDate = reportSelectedDate.uhDayStart

        if let activeReportSubjectID, subjects.contains(where: { $0.id == activeReportSubjectID }) {
            reportEvents = attendanceManager.events(for: activeReportSubjectID, context: context)
        } else if let firstSubject = subjects.first {
            activeReportSubjectID = firstSubject.id
            reportEvents = attendanceManager.events(for: firstSubject.id, context: context)
        } else {
            activeReportSubjectID = nil
            reportEvents = []
        }

        if !(1...7).contains(selectedWeekday) {
            selectedWeekday = Calendar.current.component(.weekday, from: Date())
        }
        alignSelectedReportDateWithMonth()
    }

    private func monthStart(for date: Date) -> Date {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        return Calendar.current.date(from: components)?.uhDayStart ?? Date().uhDayStart
    }

    private func alignSelectedReportDateWithMonth() {
        guard let interval = Calendar.current.dateInterval(of: .month, for: reportMonth) else { return }
        if reportSelectedDate < interval.start || reportSelectedDate >= interval.end {
            reportSelectedDate = interval.start.uhDayStart
        }
    }
}
