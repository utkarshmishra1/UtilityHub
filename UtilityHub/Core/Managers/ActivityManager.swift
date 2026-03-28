//
//  ActivityManager.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData

struct ActivityManager {
    func log(_ title: String, type: String, context: ModelContext) {
        context.insert(UHActivity(title: title, type: type))
        try? context.save()
    }

    func recent(limit: Int = 5, context: ModelContext) -> [UHActivity] {
        var descriptor = FetchDescriptor<UHActivity>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    func count(from startDate: Date, to endDate: Date, type: String? = nil, context: ModelContext) -> Int {
        let activities = (try? context.fetch(FetchDescriptor<UHActivity>())) ?? []
        return activities.filter { item in
            let inRange = item.timestamp >= startDate && item.timestamp <= endDate
            if let type {
                return inRange && item.type == type
            }
            return inRange
        }.count
    }
}
