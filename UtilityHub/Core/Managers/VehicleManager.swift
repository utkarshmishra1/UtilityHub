//
//  VehicleManager.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData

struct VehicleManager {
    func fetchOrCreate(context: ModelContext) -> UHVehicleRecord {
        if let existing = (try? context.fetch(FetchDescriptor<UHVehicleRecord>()))?.first {
            return existing
        }

        let record = UHVehicleRecord(
            serviceDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            insuranceExpiry: Calendar.current.date(byAdding: .day, value: 120, to: Date()) ?? Date()
        )
        context.insert(record)
        try? context.save()
        return record
    }

    func update(serviceDate: Date, insuranceExpiry: Date, context: ModelContext) {
        let record = fetchOrCreate(context: context)
        record.serviceDate = serviceDate
        record.insuranceExpiry = insuranceExpiry
        try? context.save()
    }

    func daysUntilService(_ record: UHVehicleRecord) -> Int {
        let days = Calendar.current.dateComponents([.day], from: Date().uhDayStart, to: record.serviceDate.uhDayStart).day ?? 0
        return max(days, 0)
    }

    func daysUntilInsuranceExpiry(_ record: UHVehicleRecord) -> Int {
        let days = Calendar.current.dateComponents([.day], from: Date().uhDayStart, to: record.insuranceExpiry.uhDayStart).day ?? 0
        return max(days, 0)
    }
}
