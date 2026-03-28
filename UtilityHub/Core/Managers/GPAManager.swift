//
//  GPAManager.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData

struct GPAManager {
    func fetchAll(context: ModelContext) -> [UHGrade] {
        let descriptor = FetchDescriptor<UHGrade>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func add(subject: String, credits: Double, gradePoint: Double, context: ModelContext) {
        guard !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let item = UHGrade(
            subject: subject,
            credits: max(credits, 0),
            gradePoint: max(min(gradePoint, 10), 0)
        )
        context.insert(item)
        try? context.save()
    }

    func delete(_ grade: UHGrade, context: ModelContext) {
        context.delete(grade)
        try? context.save()
    }

    func currentGPA(context: ModelContext) -> Double {
        let grades = fetchAll(context: context)
        let totalCredits = grades.reduce(0) { $0 + $1.credits }
        guard totalCredits > 0 else { return 0 }
        let weighted = grades.reduce(0) { $0 + ($1.gradePoint * $1.credits) }
        return weighted / totalCredits
    }
}
