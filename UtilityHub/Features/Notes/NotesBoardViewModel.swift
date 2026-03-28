//
//  NotesBoardViewModel.swift
//  UtilityHub
//
//  Created by Codex on 04/03/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
final class NotesBoardViewModel: ObservableObject {
    enum NoteDraftStyle {
        case normal
        case checklist
        case image
    }

    struct NoteColor: Identifiable, Hashable {
        let id: String
        let title: String
        let card: Color
        let tint: Color
    }

    @Published var notes: [UHNote] = []
    @Published var searchText = ""
    @Published var pinnedOnly = false

    let colors: [NoteColor] = [
        NoteColor(id: "mist", title: "Mist", card: Color(red: 0.88, green: 0.91, blue: 0.96), tint: Color(red: 0.29, green: 0.47, blue: 0.82)),
        NoteColor(id: "sky", title: "Sky", card: Color(red: 0.80, green: 0.91, blue: 1.0), tint: Color(red: 0.22, green: 0.54, blue: 0.93)),
        NoteColor(id: "mint", title: "Mint", card: Color(red: 0.80, green: 0.95, blue: 0.90), tint: Color(red: 0.15, green: 0.62, blue: 0.52)),
        NoteColor(id: "peach", title: "Peach", card: Color(red: 0.98, green: 0.86, blue: 0.77), tint: Color(red: 0.82, green: 0.45, blue: 0.28)),
        NoteColor(id: "sand", title: "Sand", card: Color(red: 0.95, green: 0.92, blue: 0.82), tint: Color(red: 0.54, green: 0.44, blue: 0.24)),
        NoteColor(id: "rose", title: "Rose", card: Color(red: 0.96, green: 0.84, blue: 0.90), tint: Color(red: 0.74, green: 0.33, blue: 0.56)),
        NoteColor(id: "violet", title: "Violet", card: Color(red: 0.87, green: 0.84, blue: 0.98), tint: Color(red: 0.45, green: 0.39, blue: 0.79))
    ]

    private let noteManager = NoteManager()
    private let activityManager = ActivityManager()

    var filteredNotes: [UHNote] {
        var pool = pinnedOnly ? notes.filter(\.isPinned) : notes
        let cleaned = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return pool }

        pool = pool.filter { note in
            note.title.localizedCaseInsensitiveContains(cleaned)
            || note.content.localizedCaseInsensitiveContains(cleaned)
        }
        return pool
    }

    var arrangedColumns: [[UHNote]] {
        let list = filteredNotes
        guard !list.isEmpty else { return [[], []] }

        var first: [UHNote] = []
        var second: [UHNote] = []
        var firstWeight = 0
        var secondWeight = 0

        for note in list {
            let weight = cardWeight(for: note)
            if firstWeight <= secondWeight {
                first.append(note)
                firstWeight += weight
            } else {
                second.append(note)
                secondWeight += weight
            }
        }

        return [first, second]
    }

    func refresh(context: ModelContext) {
        notes = noteManager.fetchAll(context: context)
    }

    @discardableResult
    func createNote(style: NoteDraftStyle = .normal, context: ModelContext) -> UHNote {
        let color = colors.randomElement()?.id ?? "mist"
        let note: UHNote

        switch style {
        case .normal:
            note = noteManager.create(colorTag: color, noteKind: .normal, context: context)
        case .checklist:
            note = noteManager.create(content: "- [ ] ", colorTag: color, noteKind: .checklist, context: context)
        case .image:
            note = noteManager.create(colorTag: color, noteKind: .image, context: context)
        }

        refresh(context: context)
        return note
    }

    func save(_ note: UHNote, context: ModelContext) {
        noteManager.save(note, context: context)
        refresh(context: context)
    }

    func togglePin(_ note: UHNote, context: ModelContext) {
        noteManager.setPinned(!note.isPinned, for: note, context: context)
        let action = note.isPinned ? "Unpinned" : "Pinned"
        activityManager.log("\(action) note", type: "note", context: context)
        HapticService.tap()
        refresh(context: context)
    }

    func setColor(_ colorTag: String, for note: UHNote, context: ModelContext) {
        noteManager.setColor(colorTag, for: note, context: context)
        HapticService.tap()
        refresh(context: context)
    }

    func delete(_ note: UHNote, context: ModelContext) {
        noteManager.delete(note, context: context)
        activityManager.log("Deleted note", type: "note", context: context)
        HapticService.warning()
        refresh(context: context)
    }

    func color(for note: UHNote) -> NoteColor {
        colors.first(where: { $0.id == note.colorTag }) ?? colors[0]
    }

    func isChecklist(_ note: UHNote) -> Bool {
        note.noteKind == .checklist
    }

    func isImage(_ note: UHNote) -> Bool {
        note.noteKind == .image
    }

    func preview(for note: UHNote) -> String {
        let value = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            if note.noteKind == .image {
                return "Add a caption for this photo..."
            }
            return "Start writing your idea..."
        }
        return value
    }

    func title(for note: UHNote) -> String {
        let value = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty { return value }
        let preview = preview(for: note)
        if note.noteKind == .image && preview == "Add a caption for this photo..." {
            return "Image Note"
        }
        if preview == "Start writing your idea..." {
            return "Untitled"
        }
        return String(preview.prefix(36))
    }

    private func cardWeight(for note: UHNote) -> Int {
        let titleLength = max(note.title.count, 8)
        let contentLength = max(note.content.count, 24)
        let imageWeight = min(note.imageAttachmentCount, 4)
        return (titleLength / 18) + (contentLength / 42) + imageWeight + 1
    }
}
