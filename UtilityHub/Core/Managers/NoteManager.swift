//
//  NoteManager.swift
//  UtilityHub
//
//  Created by Codex on 04/03/26.
//

import Foundation
import SwiftData

struct NoteManager {
    func fetchAll(context: ModelContext) -> [UHNote] {
        let descriptor = FetchDescriptor<UHNote>(
            sortBy: [SortDescriptor(\UHNote.updatedAt, order: .reverse)]
        )
        let notes = (try? context.fetch(descriptor)) ?? []
        return notes.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    @discardableResult
    func create(
        title: String = "",
        content: String = "",
        colorTag: String = "mist",
        noteKind: UHNoteKind = .normal,
        imageData: Data? = nil,
        context: ModelContext
    ) -> UHNote {
        let note = UHNote(
            title: title,
            content: content,
            colorTag: colorTag,
            noteKind: noteKind,
            imageData: imageData
        )
        context.insert(note)
        try? context.save()
        return note
    }

    func save(_ note: UHNote, context: ModelContext) {
        note.title = note.title.trimmingCharacters(in: .newlines)
        note.updatedAt = Date()
        try? context.save()
    }

    func setPinned(_ pinned: Bool, for note: UHNote, context: ModelContext) {
        note.isPinned = pinned
        note.updatedAt = Date()
        try? context.save()
    }

    func setColor(_ colorTag: String, for note: UHNote, context: ModelContext) {
        note.colorTag = colorTag
        note.updatedAt = Date()
        try? context.save()
    }

    func delete(_ note: UHNote, context: ModelContext) {
        context.delete(note)
        try? context.save()
    }
}
