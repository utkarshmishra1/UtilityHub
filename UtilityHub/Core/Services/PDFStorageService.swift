//
//  PDFStorageService.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import UIKit

final class PDFStorageService {
    static let shared = PDFStorageService()
    private init() {}

    func save(images: [UIImage], preferredName: String? = nil) throws -> URL {
        guard !images.isEmpty else { throw PDFStorageError.emptyInput }
        let name = preferredName ?? "Scan-\(Int(Date().timeIntervalSince1970)).pdf"
        let url = documentsDirectory.appendingPathComponent(name)

        let firstRect = CGRect(origin: .zero, size: images[0].size)
        let renderer = UIGraphicsPDFRenderer(bounds: firstRect)
        let data = renderer.pdfData { context in
            for image in images {
                let pageRect = CGRect(origin: .zero, size: image.size)
                context.beginPage(withBounds: pageRect, pageInfo: [:])
                image.draw(in: pageRect)
            }
        }

        try data.write(to: url, options: .atomic)
        return url
    }

    func deleteFile(at path: String) {
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
    }

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

enum PDFStorageError: Error {
    case emptyInput
}
