//
//  OfflineModels.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData

@Model
final class UHTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String
    var category: String
    var isCompleted: Bool
    var dueDate: Date?
    var createdAt: Date
    var completedAt: Date?
    var reminderAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        category: String = "General",
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        reminderAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.category = category
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.reminderAt = reminderAt
    }
}

@Model
final class UHHabit {
    @Attribute(.unique) var id: UUID
    var title: String
    var targetPerDay: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        targetPerDay: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.targetPerDay = targetPerDay
        self.createdAt = createdAt
    }
}

@Model
final class UHHabitCompletion {
    @Attribute(.unique) var id: UUID
    var habitID: UUID
    var date: Date

    init(id: UUID = UUID(), habitID: UUID, date: Date = Date()) {
        self.id = id
        self.habitID = habitID
        self.date = date
    }
}

@Model
final class UHExpense {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var category: String
    var note: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        amount: Double,
        category: String = "General",
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.note = note
        self.createdAt = createdAt
    }
}

@Model
final class UHBill {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: Double
    var dueDate: Date
    var isRecurring: Bool
    var isPaid: Bool
    var createdAt: Date
    var notificationIdentifier: String

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        dueDate: Date,
        isRecurring: Bool = false,
        isPaid: Bool = false,
        createdAt: Date = Date(),
        notificationIdentifier: String = ""
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.dueDate = dueDate
        self.isRecurring = isRecurring
        self.isPaid = isPaid
        self.createdAt = createdAt
        self.notificationIdentifier = notificationIdentifier
    }
}

@Model
final class UHSchedule {
    @Attribute(.unique) var id: UUID
    var weekday: Int
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var subject: String
    var location: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        weekday: Int,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        subject: String,
        location: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.weekday = weekday
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.subject = subject
        self.location = location
        self.createdAt = createdAt
    }
}

@Model
final class UHActivity {
    @Attribute(.unique) var id: UUID
    var title: String
    var type: String
    var timestamp: Date

    init(
        id: UUID = UUID(),
        title: String,
        type: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.timestamp = timestamp
    }
}

@Model
final class UHFocusSession {
    @Attribute(.unique) var id: UUID
    var durationSeconds: Int
    var completedAt: Date

    init(
        id: UUID = UUID(),
        durationSeconds: Int = 1500,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.durationSeconds = durationSeconds
        self.completedAt = completedAt
    }
}

@Model
final class UHAttendance {
    @Attribute(.unique) var id: UUID
    var totalClasses: Int
    var attendedClasses: Int
    var targetPercentage: Int
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        totalClasses: Int = 0,
        attendedClasses: Int = 0,
        targetPercentage: Int = 75,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.totalClasses = totalClasses
        self.attendedClasses = attendedClasses
        self.targetPercentage = targetPercentage
        self.updatedAt = updatedAt
    }
}

@Model
final class UHAttendanceSubject {
    @Attribute(.unique) var id: UUID
    var name: String
    var attendedClasses: Int
    var totalClasses: Int
    var accentHex: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        attendedClasses: Int = 0,
        totalClasses: Int = 0,
        accentHex: String = "#00D1C2",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.attendedClasses = attendedClasses
        self.totalClasses = totalClasses
        self.accentHex = accentHex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class UHAttendanceEvent {
    @Attribute(.unique) var id: UUID
    var subjectID: UUID
    var date: Date
    var isPresent: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        subjectID: UUID,
        date: Date = Date(),
        isPresent: Bool,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.subjectID = subjectID
        self.date = date
        self.isPresent = isPresent
        self.createdAt = createdAt
    }
}

@Model
final class UHGrade {
    @Attribute(.unique) var id: UUID
    var subject: String
    var credits: Double
    var gradePoint: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        subject: String,
        credits: Double,
        gradePoint: Double,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.subject = subject
        self.credits = credits
        self.gradePoint = gradePoint
        self.createdAt = createdAt
    }
}

@Model
final class UHGroceryItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var isChecked: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        isChecked: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isChecked = isChecked
        self.createdAt = createdAt
    }
}

@Model
final class UHVehicleRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var serviceDate: Date
    var insuranceExpiry: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String = "Personal Vehicle",
        serviceDate: Date,
        insuranceExpiry: Date,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.serviceDate = serviceDate
        self.insuranceExpiry = insuranceExpiry
        self.createdAt = createdAt
    }
}

@Model
final class UHDocument {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var filePath: String
    var isLocked: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        fileName: String,
        filePath: String,
        isLocked: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.filePath = filePath
        self.isLocked = isLocked
        self.createdAt = createdAt
    }
}

enum UHNoteKind: String, Codable, CaseIterable {
    case normal
    case checklist
    case image
}

@Model
final class UHNote {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var colorTag: String
    var kindRawValue: String?
    var isPinned: Bool
    @Attribute(.externalStorage) var imageData: Data?
    var extraImageData: [Data]?
    var createdAt: Date
    var updatedAt: Date

    var noteKind: UHNoteKind {
        get { UHNoteKind(rawValue: kindRawValue ?? "") ?? .normal }
        set { kindRawValue = newValue.rawValue }
    }

    var hasImageAttachment: Bool {
        imageAttachmentCount > 0
    }

    var imageAttachmentCount: Int {
        imageAttachments.count
    }

    var imageAttachments: [Data] {
        var items: [Data] = []
        if let imageData, !imageData.isEmpty {
            items.append(imageData)
        }
        if let extraImageData {
            items.append(contentsOf: extraImageData.filter { !$0.isEmpty })
        }
        return items
    }

    func setImageAttachments(_ items: [Data]) {
        let cleaned = items.filter { !$0.isEmpty }
        guard let first = cleaned.first else {
            imageData = nil
            extraImageData = nil
            return
        }

        imageData = first
        let extras = Array(cleaned.dropFirst())
        extraImageData = extras.isEmpty ? nil : extras
    }

    func appendImageAttachment(_ item: Data) {
        guard !item.isEmpty else { return }
        var current = imageAttachments
        current.append(item)
        setImageAttachments(current)
    }

    func removeImageAttachment(at index: Int) {
        guard imageAttachments.indices.contains(index) else { return }
        var current = imageAttachments
        current.remove(at: index)
        setImageAttachments(current)
    }

    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        colorTag: String = "mist",
        noteKind: UHNoteKind = .normal,
        isPinned: Bool = false,
        imageData: Data? = nil,
        extraImageData: [Data]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.colorTag = colorTag
        self.kindRawValue = noteKind.rawValue
        self.isPinned = isPinned
        self.imageData = imageData
        self.extraImageData = extraImageData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
