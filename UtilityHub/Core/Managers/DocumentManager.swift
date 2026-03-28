//
//  DocumentManager.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData
import UIKit

struct DocumentManager {
    func fetchAll(context: ModelContext) -> [UHDocument] {
        let descriptor = FetchDescriptor<UHDocument>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func saveScan(images: [UIImage], context: ModelContext) throws {
        let url = try PDFStorageService.shared.save(images: images)
        let item = UHDocument(fileName: url.lastPathComponent, filePath: url.path)
        context.insert(item)
        try context.save()
    }

    func toggleLock(_ document: UHDocument, context: ModelContext) {
        document.isLocked.toggle()
        try? context.save()
    }

    func delete(_ document: UHDocument, context: ModelContext) {
        PDFStorageService.shared.deleteFile(at: document.filePath)
        context.delete(document)
        try? context.save()
    }
}
