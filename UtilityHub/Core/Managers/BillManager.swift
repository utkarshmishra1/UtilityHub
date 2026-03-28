//
//  BillManager.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData

struct BillManager {
    func fetchAll(context: ModelContext) -> [UHBill] {
        let descriptor = FetchDescriptor<UHBill>(sortBy: [SortDescriptor(\.dueDate, order: .forward)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func add(title: String, amount: Double, dueDate: Date, recurring: Bool, context: ModelContext) {
        let bill = UHBill(title: title, amount: max(amount, 0), dueDate: dueDate, isRecurring: recurring)
        context.insert(bill)
        try? context.save()
        NotificationService.shared.scheduleBillReminder(for: bill)
    }

    func togglePaid(_ bill: UHBill, context: ModelContext) {
        bill.isPaid.toggle()
        if bill.isPaid {
            NotificationService.shared.cancelBillReminder(for: bill.id)
        } else {
            NotificationService.shared.scheduleBillReminder(for: bill)
        }
        try? context.save()
    }

    func delete(_ bill: UHBill, context: ModelContext) {
        NotificationService.shared.cancelBillReminder(for: bill.id)
        context.delete(bill)
        try? context.save()
    }

    func upcomingUnpaid(context: ModelContext) -> UHBill? {
        fetchAll(context: context)
            .filter { !$0.isPaid && $0.dueDate >= Date() }
            .sorted { $0.dueDate < $1.dueDate }
            .first
    }
}
