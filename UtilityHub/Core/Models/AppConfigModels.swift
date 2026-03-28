//
//  AppConfigModels.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import SwiftUI

enum AppTab: Hashable {
    case home
    case productivity
    case student
    case settings
}

struct AppPreferenceKeys {
    static let hasStudentRoleSelection = "has_student_role_selection"
    static let isStudentModeEnabled = "is_student_mode_enabled"
}

enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case pending = "Pending"
    case completed = "Completed"

    var id: String { rawValue }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum AppAccent: String, CaseIterable, Identifiable {
    case indigo = "Indigo"
    case ocean = "Ocean"
    case emerald = "Emerald"
    case sunset = "Sunset"

    static let storageKey = "selected_accent"

    var id: String { rawValue }

    var tintColor: Color {
        switch self {
        case .indigo:
            return Color(red: 0.34, green: 0.45, blue: 0.94)
        case .ocean:
            return Color(red: 0.08, green: 0.55, blue: 0.74)
        case .emerald:
            return Color(red: 0.16, green: 0.63, blue: 0.43)
        case .sunset:
            return Color(red: 0.90, green: 0.45, blue: 0.21)
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .indigo:
            return LinearGradient(
                colors: [Color(red: 0.43, green: 0.38, blue: 0.92), Color(red: 0.18, green: 0.52, blue: 0.93)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .ocean:
            return LinearGradient(
                colors: [Color(red: 0.00, green: 0.61, blue: 0.78), Color(red: 0.22, green: 0.40, blue: 0.86)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .emerald:
            return LinearGradient(
                colors: [Color(red: 0.13, green: 0.70, blue: 0.48), Color(red: 0.29, green: 0.51, blue: 0.90)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sunset:
            return LinearGradient(
                colors: [Color(red: 0.98, green: 0.58, blue: 0.30), Color(red: 0.89, green: 0.29, blue: 0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static var current: AppAccent {
        let raw = UserDefaults.standard.string(forKey: AppAccent.storageKey) ?? AppAccent.indigo.rawValue
        return AppAccent(rawValue: raw) ?? .indigo
    }
}
