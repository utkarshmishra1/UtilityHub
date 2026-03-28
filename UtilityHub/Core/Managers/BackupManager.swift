//
//  BackupManager.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData

struct BackupManager {
    struct BackupPayload: Codable {
        let exportedAt: Date
        let tasks: [TaskDTO]
        let habits: [HabitDTO]
        let habitCompletions: [HabitCompletionDTO]
        let expenses: [ExpenseDTO]
        let bills: [BillDTO]
        let schedules: [ScheduleDTO]
        let activities: [ActivityDTO]
        let focusSessions: [FocusSessionDTO]
        let attendance: [AttendanceDTO]
        let grades: [GradeDTO]
        let groceryItems: [GroceryItemDTO]
        let vehicleRecords: [VehicleDTO]
        let documents: [DocumentDTO]
    }

    struct TaskDTO: Codable {
        let id: UUID
        let title: String
        let notes: String
        let category: String
        let isCompleted: Bool
        let dueDate: Date?
        let createdAt: Date
        let completedAt: Date?
    }

    struct HabitDTO: Codable {
        let id: UUID
        let title: String
        let targetPerDay: Int
        let createdAt: Date
    }

    struct HabitCompletionDTO: Codable {
        let id: UUID
        let habitID: UUID
        let date: Date
    }

    struct ExpenseDTO: Codable {
        let id: UUID
        let amount: Double
        let category: String
        let note: String
        let createdAt: Date
    }

    struct BillDTO: Codable {
        let id: UUID
        let title: String
        let amount: Double
        let dueDate: Date
        let isRecurring: Bool
        let isPaid: Bool
        let createdAt: Date
    }

    struct ScheduleDTO: Codable {
        let id: UUID
        let weekday: Int
        let startHour: Int
        let startMinute: Int
        let endHour: Int
        let endMinute: Int
        let subject: String
        let location: String
        let createdAt: Date
    }

    struct ActivityDTO: Codable {
        let id: UUID
        let title: String
        let type: String
        let timestamp: Date
    }

    struct FocusSessionDTO: Codable {
        let id: UUID
        let durationSeconds: Int
        let completedAt: Date
    }

    struct AttendanceDTO: Codable {
        let id: UUID
        let totalClasses: Int
        let attendedClasses: Int
        let updatedAt: Date
    }

    struct GradeDTO: Codable {
        let id: UUID
        let subject: String
        let credits: Double
        let gradePoint: Double
        let createdAt: Date
    }

    struct GroceryItemDTO: Codable {
        let id: UUID
        let title: String
        let isChecked: Bool
        let createdAt: Date
    }

    struct VehicleDTO: Codable {
        let id: UUID
        let title: String
        let serviceDate: Date
        let insuranceExpiry: Date
        let createdAt: Date
    }

    struct DocumentDTO: Codable {
        let id: UUID
        let fileName: String
        let filePath: String
        let isLocked: Bool
        let createdAt: Date
    }

    func createBackup(context: ModelContext) throws -> URL {
        let payload = BackupPayload(
            exportedAt: Date(),
            tasks: fetchTasks(context: context),
            habits: fetchHabits(context: context),
            habitCompletions: fetchHabitCompletions(context: context),
            expenses: fetchExpenses(context: context),
            bills: fetchBills(context: context),
            schedules: fetchSchedules(context: context),
            activities: fetchActivities(context: context),
            focusSessions: fetchFocusSessions(context: context),
            attendance: fetchAttendance(context: context),
            grades: fetchGrades(context: context),
            groceryItems: fetchGroceryItems(context: context),
            vehicleRecords: fetchVehicleRecords(context: context),
            documents: fetchDocuments(context: context)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)

        let fileName = "UtilityHubBackup-\(Date().uhBackupFileStamp).json"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private func fetchTasks(context: ModelContext) -> [TaskDTO] {
        let descriptor = FetchDescriptor<UHTask>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let items = (try? context.fetch(descriptor)) ?? []
        return items.map {
            TaskDTO(
                id: $0.id,
                title: $0.title,
                notes: $0.notes,
                category: $0.category,
                isCompleted: $0.isCompleted,
                dueDate: $0.dueDate,
                createdAt: $0.createdAt,
                completedAt: $0.completedAt
            )
        }
    }

    private func fetchHabits(context: ModelContext) -> [HabitDTO] {
        let descriptor = FetchDescriptor<UHHabit>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let items = (try? context.fetch(descriptor)) ?? []
        return items.map { HabitDTO(id: $0.id, title: $0.title, targetPerDay: $0.targetPerDay, createdAt: $0.createdAt) }
    }

    private func fetchHabitCompletions(context: ModelContext) -> [HabitCompletionDTO] {
        let descriptor = FetchDescriptor<UHHabitCompletion>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let items = (try? context.fetch(descriptor)) ?? []
        return items.map { HabitCompletionDTO(id: $0.id, habitID: $0.habitID, date: $0.date) }
    }

    private func fetchExpenses(context: ModelContext) -> [ExpenseDTO] {
        let descriptor = FetchDescriptor<UHExpense>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let items = (try? context.fetch(descriptor)) ?? []
        return items.map { ExpenseDTO(id: $0.id, amount: $0.amount, category: $0.category, note: $0.note, createdAt: $0.createdAt) }
    }

    private func fetchBills(context: ModelContext) -> [BillDTO] {
        let descriptor = FetchDescriptor<UHBill>(sortBy: [SortDescriptor(\.dueDate, order: .forward)])
        let items = (try? context.fetch(descriptor)) ?? []
        return items.map {
            BillDTO(
                id: $0.id,
                title: $0.title,
                amount: $0.amount,
                dueDate: $0.dueDate,
                isRecurring: $0.isRecurring,
                isPaid: $0.isPaid,
                createdAt: $0.createdAt
            )
        }
    }

    private func fetchSchedules(context: ModelContext) -> [ScheduleDTO] {
        let descriptor = FetchDescriptor<UHSchedule>(sortBy: [SortDescriptor(\.weekday, order: .forward)])
        let items = (try? context.fetch(descriptor)) ?? []
        return items.map {
            ScheduleDTO(
                id: $0.id,
                weekday: $0.weekday,
                startHour: $0.startHour,
                startMinute: $0.startMinute,
                endHour: $0.endHour,
                endMinute: $0.endMinute,
                subject: $0.subject,
                location: $0.location,
                createdAt: $0.createdAt
            )
        }
    }

    private func fetchActivities(context: ModelContext) -> [ActivityDTO] {
        let descriptor = FetchDescriptor<UHActivity>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let items = (try? context.fetch(descriptor)) ?? []
        return items.map { ActivityDTO(id: $0.id, title: $0.title, type: $0.type, timestamp: $0.timestamp) }
    }

    private func fetchFocusSessions(context: ModelContext) -> [FocusSessionDTO] {
        let descriptor = FetchDescriptor<UHFocusSession>(sortBy: [SortDescriptor(\.completedAt, order: .reverse)])
        let items = (try? context.fetch(descriptor)) ?? []
        return items.map { FocusSessionDTO(id: $0.id, durationSeconds: $0.durationSeconds, completedAt: $0.completedAt) }
    }

    private func fetchAttendance(context: ModelContext) -> [AttendanceDTO] {
        let descriptor = FetchDescriptor<UHAttendance>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        let items = (try? context.fetch(descriptor)) ?? []
        return items.map { AttendanceDTO(id: $0.id, totalClasses: $0.totalClasses, attendedClasses: $0.attendedClasses, updatedAt: $0.updatedAt) }
    }

    private func fetchGrades(context: ModelContext) -> [GradeDTO] {
        let descriptor = FetchDescriptor<UHGrade>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let items = (try? context.fetch(descriptor)) ?? []
        return items.map { GradeDTO(id: $0.id, subject: $0.subject, credits: $0.credits, gradePoint: $0.gradePoint, createdAt: $0.createdAt) }
    }

    private func fetchGroceryItems(context: ModelContext) -> [GroceryItemDTO] {
        let descriptor = FetchDescriptor<UHGroceryItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let items = (try? context.fetch(descriptor)) ?? []
        return items.map { GroceryItemDTO(id: $0.id, title: $0.title, isChecked: $0.isChecked, createdAt: $0.createdAt) }
    }

    private func fetchVehicleRecords(context: ModelContext) -> [VehicleDTO] {
        let descriptor = FetchDescriptor<UHVehicleRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let items = (try? context.fetch(descriptor)) ?? []
        return items.map {
            VehicleDTO(
                id: $0.id,
                title: $0.title,
                serviceDate: $0.serviceDate,
                insuranceExpiry: $0.insuranceExpiry,
                createdAt: $0.createdAt
            )
        }
    }

    private func fetchDocuments(context: ModelContext) -> [DocumentDTO] {
        let descriptor = FetchDescriptor<UHDocument>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let items = (try? context.fetch(descriptor)) ?? []
        return items.map { DocumentDTO(id: $0.id, fileName: $0.fileName, filePath: $0.filePath, isLocked: $0.isLocked, createdAt: $0.createdAt) }
    }
}
