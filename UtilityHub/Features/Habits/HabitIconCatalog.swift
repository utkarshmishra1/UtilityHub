//
//  HabitIconCatalog.swift
//  UtilityHub
//
//  Created by Codex on 24/04/26.
//

import SwiftUI

struct HabitIcon: Identifiable, Hashable {
    let id: String
    let systemName: String
    let label: String
}

struct HabitSwatch: Identifiable, Hashable {
    let id: String
    let hex: String
    let color: Color
}

enum HabitIconCatalog {
    static let all: [HabitIcon] = [
        HabitIcon(id: "star", systemName: "star.fill", label: "Skill"),
        HabitIcon(id: "dumbbell", systemName: "dumbbell.fill", label: "Gym"),
        HabitIcon(id: "cricket", systemName: "figure.cricket", label: "Cricket"),
        HabitIcon(id: "flame", systemName: "flame.fill", label: "Streak"),
        HabitIcon(id: "target", systemName: "scope", label: "Target"),
        HabitIcon(id: "trophy", systemName: "trophy.fill", label: "Trophy"),
        HabitIcon(id: "check-circle", systemName: "checkmark.circle.fill", label: "Done"),
        HabitIcon(id: "check-seal", systemName: "checkmark.seal.fill", label: "Check"),
        HabitIcon(id: "uptrend", systemName: "chart.line.uptrend.xyaxis", label: "Progress"),
        HabitIcon(id: "calendar", systemName: "calendar", label: "Calendar"),
        HabitIcon(id: "bell", systemName: "bell.fill", label: "Bell"),
        HabitIcon(id: "medal", systemName: "medal.fill", label: "Award"),
        HabitIcon(id: "lock", systemName: "lock.fill", label: "Focus"),
        HabitIcon(id: "quote", systemName: "quote.bubble.fill", label: "Quote"),
        HabitIcon(id: "book", systemName: "book.fill", label: "Read"),
        HabitIcon(id: "pencil", systemName: "pencil.and.outline", label: "Write"),
        HabitIcon(id: "brain", systemName: "brain.head.profile", label: "Learn"),
        HabitIcon(id: "code", systemName: "chevron.left.forwardslash.chevron.right", label: "Code"),
        HabitIcon(id: "music", systemName: "music.note", label: "Music"),
        HabitIcon(id: "paint", systemName: "paintbrush.fill", label: "Art"),
        HabitIcon(id: "heart", systemName: "heart.fill", label: "Health"),
        HabitIcon(id: "drop", systemName: "drop.fill", label: "Water"),
        HabitIcon(id: "leaf", systemName: "leaf.fill", label: "Meditate"),
        HabitIcon(id: "moon", systemName: "moon.stars.fill", label: "Sleep"),
        HabitIcon(id: "pill", systemName: "pills.fill", label: "Meds"),
        HabitIcon(id: "fork", systemName: "fork.knife", label: "Diet"),
        HabitIcon(id: "cup", systemName: "cup.and.saucer.fill", label: "Coffee"),
        HabitIcon(id: "run", systemName: "figure.run", label: "Run"),
        HabitIcon(id: "yoga", systemName: "figure.mind.and.body", label: "Yoga"),
        HabitIcon(id: "walk", systemName: "figure.walk", label: "Walk"),
        HabitIcon(id: "bike", systemName: "bicycle", label: "Ride"),
        HabitIcon(id: "sun", systemName: "sun.max.fill", label: "Morning"),
        HabitIcon(id: "globe", systemName: "globe", label: "Language"),
        HabitIcon(id: "camera", systemName: "camera.fill", label: "Photo"),
        HabitIcon(id: "money", systemName: "dollarsign.circle.fill", label: "Save")
    ]

    static let fallback = HabitIcon(id: "star", systemName: "star.fill", label: "Skill")

    static func icon(for id: String?) -> HabitIcon {
        guard let id, let match = all.first(where: { $0.id == id }) else {
            return fallback
        }
        return match
    }
}

enum HabitSwatchCatalog {
    static let all: [HabitSwatch] = [
        HabitSwatch(id: "amber",   hex: "#F5A23C", color: Color(red: 0.96, green: 0.64, blue: 0.24)),
        HabitSwatch(id: "emerald", hex: "#34C980", color: Color(red: 0.20, green: 0.79, blue: 0.50)),
        HabitSwatch(id: "indigo",  hex: "#5B6CF6", color: Color(red: 0.36, green: 0.42, blue: 0.96)),
        HabitSwatch(id: "violet",  hex: "#8B5CF6", color: Color(red: 0.55, green: 0.36, blue: 0.96)),
        HabitSwatch(id: "rose",    hex: "#F43E5E", color: Color(red: 0.96, green: 0.24, blue: 0.37)),
        HabitSwatch(id: "sun",     hex: "#FFC72F", color: Color(red: 1.00, green: 0.78, blue: 0.18)),
        HabitSwatch(id: "cyan",    hex: "#35D4E8", color: Color(red: 0.21, green: 0.83, blue: 0.91)),
        HabitSwatch(id: "pink",    hex: "#FF6BB3", color: Color(red: 1.00, green: 0.42, blue: 0.70)),
        HabitSwatch(id: "mint",    hex: "#4ADBB4", color: Color(red: 0.29, green: 0.86, blue: 0.70)),
        HabitSwatch(id: "coral",   hex: "#FF7A5C", color: Color(red: 1.00, green: 0.48, blue: 0.36))
    ]

    static let fallback = all[2]

    static func swatch(for hex: String?) -> HabitSwatch {
        guard let hex else { return fallback }
        let lower = hex.lowercased()
        return all.first { $0.hex.lowercased() == lower } ?? fallback
    }

    static func color(for hex: String?) -> Color {
        swatch(for: hex).color
    }

    static func fallback(seededBy id: UUID) -> HabitSwatch {
        let seed = abs(id.uuidString.hashValue)
        return all[seed % all.count]
    }
}
