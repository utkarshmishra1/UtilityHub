//
//  DocumentsView.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import SwiftUI
import SwiftData
import VisionKit
import PDFKit

struct DocumentsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DocumentsViewModel()
    @State private var showScanner = false
    @State private var previewURL: URL?

    var body: some View {
        NavigationStack {
            List {
                if viewModel.documents.isEmpty {
                    Text("No scanned documents yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.documents) { document in
                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    let canOpen = await viewModel.canOpen(document)
                                    if canOpen {
                                        previewURL = URL(fileURLWithPath: document.filePath)
                                    }
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(document.fileName)
                                        .font(.subheadline.weight(.semibold))
                                    Text(document.createdAt.uhHeaderDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button {
                                viewModel.toggleLock(document, context: modelContext)
                            } label: {
                                Image(systemName: document.isLocked ? "lock.fill" : "lock.open.fill")
                                    .foregroundColor(document.isLocked ? .orange : .secondary)
                            }
                            .buttonStyle(.plain)

                            Button(role: .destructive) {
                                viewModel.delete(document, context: modelContext)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Documents")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showScanner = true
                    } label: {
                        Label("Scan", systemImage: "doc.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                DocumentScannerView { images in
                    viewModel.saveScan(images: images, context: modelContext)
                    showScanner = false
                } onCancel: {
                    showScanner = false
                }
            }
            .sheet(item: Binding(
                get: {
                    previewURL.map { URLBox(url: $0) }
                },
                set: { item in
                    previewURL = item?.url
                }
            )) { item in
                PDFPreviewScreen(url: item.url)
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                viewModel.refresh(context: modelContext)
            }
        }
    }
}

private struct URLBox: Identifiable {
    let id = UUID()
    let url: URL
}

struct DocumentScannerView: UIViewControllerRepresentable {
    let onComplete: ([UIImage]) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onComplete: ([UIImage]) -> Void
        let onCancel: () -> Void

        init(onComplete: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void) {
            self.onComplete = onComplete
            self.onCancel = onCancel
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let images = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            onComplete(images)
        }
    }
}

private struct PDFPreviewScreen: View {
    let url: URL
    var body: some View {
        PDFKitContainer(url: url)
            .ignoresSafeArea()
    }
}

private struct PDFKitContainer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(url: url)
    }
}
