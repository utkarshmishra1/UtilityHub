//
//  NotificationService.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleBillReminder(for bill: UHBill) {
        let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: bill.dueDate) ?? bill.dueDate
        guard reminderDate > Date() else { return }

        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        components.second = 0

        let content = UNMutableNotificationContent()
        content.title = "Bill due tomorrow"
        content.body = "\(bill.title) • ₹\(Int(bill.amount)) is due soon."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: notificationID(for: bill.id), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelBillReminder(for billID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID(for: billID)])
    }

    private func notificationID(for billID: UUID) -> String {
        "bill-reminder-\(billID.uuidString)"
    }
}
