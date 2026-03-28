//
//  AttendanceManager.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData

struct AttendanceManager {
    private let defaultTarget = 75
    private let minimumTarget = 50
    private let maximumTarget = 95
    private let subjectAccentPalette = [
        "#2AF598",
        "#00D1C2",
        "#00B2FF",
        "#7AD3FF",
        "#7BF178",
        "#25C6FC",
        "#84FAB0",
        "#A6FFCB",
        "#47D1A8"
    ]

    func fetchOrCreate(context: ModelContext) -> UHAttendance {
        if let existing = (try? context.fetch(FetchDescriptor<UHAttendance>()))?.first {
            if !(minimumTarget...maximumTarget).contains(existing.targetPercentage) {
                existing.targetPercentage = defaultTarget
                try? context.save()
            }
            return existing
        }
        let record = UHAttendance(totalClasses: 0, attendedClasses: 0, targetPercentage: defaultTarget)
        context.insert(record)
        try? context.save()
        return record
    }

    func fetchSubjects(context: ModelContext) -> [UHAttendanceSubject] {
        migrateLegacyRecordIfNeeded(context: context)
        let descriptor = FetchDescriptor<UHAttendanceSubject>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func addSubject(name: String, attended: Int = 0, total: Int = 0, context: ModelContext) -> UHAttendanceSubject? {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        let safeTotal = max(total, 0)
        let safeAttended = max(min(attended, safeTotal), 0)
        let subject = UHAttendanceSubject(
            name: cleaned,
            attendedClasses: safeAttended,
            totalClasses: safeTotal,
            accentHex: subjectAccentPalette.randomElement() ?? "#00D1C2"
        )
        context.insert(subject)
        syncAggregateAttendance(context: context)
        return subject
    }

    func updateSubject(
        _ subject: UHAttendanceSubject,
        name: String,
        attended: Int,
        total: Int,
        context: ModelContext
    ) {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        let safeTotal = max(total, 0)
        let safeAttended = max(min(attended, safeTotal), 0)
        subject.name = cleaned
        subject.totalClasses = safeTotal
        subject.attendedClasses = safeAttended
        subject.updatedAt = Date()
        syncAggregateAttendance(context: context)
    }

    func deleteSubject(_ subject: UHAttendanceSubject, context: ModelContext) {
        let allEvents = (try? context.fetch(FetchDescriptor<UHAttendanceEvent>())) ?? []
        for event in allEvents where event.subjectID == subject.id {
            context.delete(event)
        }
        context.delete(subject)
        syncAggregateAttendance(context: context)
    }

    func resetSubject(_ subject: UHAttendanceSubject, context: ModelContext) {
        subject.totalClasses = 0
        subject.attendedClasses = 0
        subject.updatedAt = Date()

        let allEvents = (try? context.fetch(FetchDescriptor<UHAttendanceEvent>())) ?? []
        for event in allEvents where event.subjectID == subject.id {
            context.delete(event)
        }
        syncAggregateAttendance(context: context)
    }

    func mark(subject: UHAttendanceSubject, present: Bool, on date: Date = Date(), context: ModelContext) {
        subject.totalClasses += 1
        if present {
            subject.attendedClasses += 1
        }
        subject.updatedAt = Date()
        context.insert(
            UHAttendanceEvent(
                subjectID: subject.id,
                date: date.uhDayStart,
                isPresent: present
            )
        )
        syncAggregateAttendance(context: context)
    }

    func setTarget(_ target: Int, context: ModelContext) {
        let record = fetchOrCreate(context: context)
        record.targetPercentage = min(max(target, minimumTarget), maximumTarget)
        record.updatedAt = Date()
        try? context.save()
    }

    func events(for subjectID: UUID, context: ModelContext) -> [UHAttendanceEvent] {
        let descriptor = FetchDescriptor<UHAttendanceEvent>(sortBy: [
            SortDescriptor(\.date, order: .forward),
            SortDescriptor(\.createdAt, order: .forward)
        ])
        return ((try? context.fetch(descriptor)) ?? []).filter { $0.subjectID == subjectID }
    }

    func update(total: Int, attended: Int, context: ModelContext) {
        let record = fetchOrCreate(context: context)
        record.totalClasses = max(total, 0)
        record.attendedClasses = max(min(attended, total), 0)
        record.updatedAt = Date()
        try? context.save()
    }

    func percentage(for record: UHAttendance) -> Int {
        guard record.totalClasses > 0 else { return 0 }
        return Int((Double(record.attendedClasses) / Double(record.totalClasses)) * 100)
    }

    func percentage(for subject: UHAttendanceSubject) -> Int {
        guard subject.totalClasses > 0 else { return 0 }
        return Int((Double(subject.attendedClasses) / Double(subject.totalClasses)) * 100)
    }

    func classesNeededToReach75(for record: UHAttendance) -> Int {
        classesNeeded(attended: record.attendedClasses, total: record.totalClasses, target: 75)
    }

    func classesCanMissMaintaining75(for record: UHAttendance) -> Int {
        classesCanMiss(attended: record.attendedClasses, total: record.totalClasses, target: 75)
    }

    func classesNeeded(for subject: UHAttendanceSubject, target: Int) -> Int {
        classesNeeded(attended: subject.attendedClasses, total: subject.totalClasses, target: target)
    }

    func classesCanMiss(for subject: UHAttendanceSubject, target: Int) -> Int {
        classesCanMiss(attended: subject.attendedClasses, total: subject.totalClasses, target: target)
    }

    func statusText(for subject: UHAttendanceSubject, target: Int) -> String {
        guard subject.totalClasses > 0 else {
            return "No classes tracked yet. Start marking attendance."
        }

        let percent = percentage(for: subject)
        if percent >= target {
            let missable = classesCanMiss(for: subject, target: target)
            if missable == 0 {
                return "On track, you can't miss the next class."
            }
            if missable == 1 {
                return "On track, you can miss 1 class."
            }
            return "On track, you can miss next \(missable) classes."
        }

        let needed = classesNeeded(for: subject, target: target)
        if needed <= 1 {
            return "Attend the next class to get back on track."
        }
        return "Attend next \(needed) classes to get back on track."
    }

    private func classesNeeded(attended: Int, total: Int, target: Int) -> Int {
        let targetRatio = Double(min(max(target, minimumTarget), maximumTarget)) / 100
        let safeAttended = Double(max(attended, 0))
        let safeTotal = Double(max(total, 0))
        let numerator = (targetRatio * safeTotal) - safeAttended
        guard numerator > 0 else { return 0 }
        return Int(ceil(numerator / max(1 - targetRatio, 0.01)))
    }

    private func classesCanMiss(attended: Int, total: Int, target: Int) -> Int {
        let targetRatio = Double(min(max(target, minimumTarget), maximumTarget)) / 100
        let safeAttended = max(attended, 0)
        let safeTotal = max(total, 0)
        guard safeAttended > 0 else { return 0 }
        let maxTotalAllowed = Int((Double(safeAttended) / targetRatio).rounded(.down))
        return max(maxTotalAllowed - safeTotal, 0)
    }

    private func syncAggregateAttendance(context: ModelContext) {
        let subjects = (try? context.fetch(FetchDescriptor<UHAttendanceSubject>())) ?? []
        let aggregateTotal = subjects.reduce(0) { $0 + max($1.totalClasses, 0) }
        let aggregateAttended = subjects.reduce(0) { $0 + max(min($1.attendedClasses, $1.totalClasses), 0) }

        let record = fetchOrCreate(context: context)
        record.totalClasses = aggregateTotal
        record.attendedClasses = aggregateAttended
        record.updatedAt = Date()
        if !(minimumTarget...maximumTarget).contains(record.targetPercentage) {
            record.targetPercentage = defaultTarget
        }
        try? context.save()
    }

    private func migrateLegacyRecordIfNeeded(context: ModelContext) {
        let subjects = (try? context.fetch(FetchDescriptor<UHAttendanceSubject>())) ?? []
        guard subjects.isEmpty else { return }

        let record = fetchOrCreate(context: context)
        guard record.totalClasses > 0 else { return }

        let migrated = UHAttendanceSubject(
            name: "General",
            attendedClasses: record.attendedClasses,
            totalClasses: record.totalClasses,
            accentHex: subjectAccentPalette.first ?? "#00D1C2"
        )
        context.insert(migrated)
        try? context.save()
    }
}
