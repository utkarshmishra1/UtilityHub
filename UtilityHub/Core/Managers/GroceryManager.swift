//
//  GroceryManager.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData

struct GroceryManager {
    func fetchAll(context: ModelContext) -> [UHGroceryItem] {
        let descriptor = FetchDescriptor<UHGroceryItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func add(title: String, context: ModelContext) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        context.insert(UHGroceryItem(title: cleanTitle))
        try? context.save()
    }

    func toggle(_ item: UHGroceryItem, context: ModelContext) {
        item.isChecked.toggle()
        try? context.save()
    }

    func delete(_ item: UHGroceryItem, context: ModelContext) {
        context.delete(item)
        try? context.save()
    }
}
