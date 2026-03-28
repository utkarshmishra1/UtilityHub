//
//  Date+UtilityHub.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation

extension Date {
    var uhHeaderDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    var uhShortTime: String {
        formatted(date: .omitted, time: .shortened)
    }

    var uhDayStart: Date {
        Calendar.current.startOfDay(for: self)
    }

    var uhBackupFileStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: self)
    }
}

extension Int {
    var asPercentageText: String {
        "\(self)%"
    }
}
