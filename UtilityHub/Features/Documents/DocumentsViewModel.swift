//
//  DocumentsViewModel.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import Foundation
import SwiftData
import UIKit
import Combine

@MainActor
final class DocumentsViewModel: ObservableObject {
    @Published var documents: [UHDocument] = []
    @Published var errorMessage: String?

    private let documentManager = DocumentManager()
    private let activityManager = ActivityManager()

    func refresh(context: ModelContext) {
        documents = documentManager.fetchAll(context: context)
    }

    func saveScan(images: [UIImage], context: ModelContext) {
        do {
            try documentManager.saveScan(images: images, context: context)
            activityManager.log("Scanned and saved a document", type: "document", context: context)
            HapticService.success()
            refresh(context: context)
        } catch {
            errorMessage = "Failed to save PDF."
        }
    }

    func toggleLock(_ document: UHDocument, context: ModelContext) {
        documentManager.toggleLock(document, context: context)
        let title = document.isLocked ? "Locked \(document.fileName)" : "Unlocked \(document.fileName)"
        activityManager.log(title, type: "document", context: context)
        refresh(context: context)
    }

    func delete(_ document: UHDocument, context: ModelContext) {
        documentManager.delete(document, context: context)
        activityManager.log("Deleted \(document.fileName)", type: "document", context: context)
        refresh(context: context)
    }

    func canOpen(_ document: UHDocument) async -> Bool {
        guard document.isLocked else { return true }
        return await BiometricAuthService.shared.authenticate(reason: "Unlock document")
    }
}
