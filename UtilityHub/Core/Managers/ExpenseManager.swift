//
//  ExpenseManager.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData

struct ExpenseManager {
    func fetchAll(context: ModelContext) -> [UHExpense] {
        let descriptor = FetchDescriptor<UHExpense>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func add(
        amount: Double,
        category: String = "General",
        note: String = "",
        createdAt: Date = Date(),
        context: ModelContext
    ) {
        let normalizedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "General" : category
        context.insert(
            UHExpense(
                amount: amount,
                category: normalizedCategory,
                note: note,
                createdAt: createdAt
            )
        )
        try? context.save()
    }

    func delete(_ expense: UHExpense, context: ModelContext) {
        context.delete(expense)
        try? context.save()
    }

    func monthlyTotal(date: Date = Date(), context: ModelContext) -> Double {
        let allExpenses = fetchAll(context: context)
        let calendar = Calendar.current
        return allExpenses
            .filter { calendar.isDate($0.createdAt, equalTo: date, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
}
