//
//  NotesBoardView.swift
//  UtilityHub
//
//  Created by Codex on 04/03/26.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct NotesBoardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = NotesBoardViewModel()
    @State private var selectedNote: UHNote?
    @State private var showCreateNoteOptions = false
    @State private var didAnimateIn = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            notesBackdrop

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    topBar
                    searchBar
                    filterBar
                    notesGrid
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 96)
            }

            addNoteButton

            if isSearchFocused {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        isSearchFocused = false
                    }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            viewModel.refresh(context: modelContext)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                didAnimateIn = true
            }
        }
        .sheet(item: $selectedNote, onDismiss: {
            viewModel.refresh(context: modelContext)
        }) { note in
            NoteEditorView(
                note: note,
                colors: viewModel.colors,
                onSave: { updated in
                    viewModel.save(updated, context: modelContext)
                },
                onDelete: { deleted in
                    viewModel.delete(deleted, context: modelContext)
                },
                onTogglePin: { target in
                    viewModel.togglePin(target, context: modelContext)
                },
                onSelectColor: { target, colorTag in
                    viewModel.setColor(colorTag, for: target, context: modelContext)
                }
            )
        }
        .confirmationDialog("Create Note", isPresented: $showCreateNoteOptions, titleVisibility: .visible) {
            Button("Normal Note") {
                createAndOpenNote(style: .normal)
            }
            Button("Checklist Note") {
                createAndOpenNote(style: .checklist)
            }
            Button("Image Note") {
                createAndOpenNote(style: .image)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how you want to start your note.")
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.white.opacity(0.14)))
            }
            .buttonStyle(.plain)

            Text("Notes")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            Spacer()

            Button {
                showCreateNoteOptions = true
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundColor(Color(red: 0.18, green: 0.28, blue: 0.46))
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.white.opacity(0.88)))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.74))

            TextField(
                "",
                text: $viewModel.searchText,
                prompt: Text("Search notes").foregroundColor(.black.opacity(0.3))
            )
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .focused($isSearchFocused)
                .foregroundColor(.black)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.68))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            NotesFilterChip(
                title: "All",
                isActive: !viewModel.pinnedOnly,
                tint: Color(red: 0.42, green: 0.76, blue: 1.0)
            ) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    viewModel.pinnedOnly = false
                }
            }

            NotesFilterChip(
                title: "Pinned",
                isActive: viewModel.pinnedOnly,
                tint: Color(red: 1.0, green: 0.80, blue: 0.44)
            ) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    viewModel.pinnedOnly = true
                }
            }

            Spacer()

            Text("\(viewModel.filteredNotes.count) notes")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.72))
        }
    }

    private var notesGrid: some View {
        let columns = viewModel.arrangedColumns

        return Group {
            if viewModel.filteredNotes.isEmpty {
                emptyState
            } else {
                HStack(alignment: .top, spacing: 12) {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(columns[0].enumerated()), id: \.element.id) { index, note in
                            noteCard(note)
                                .offset(y: didAnimateIn ? 0 : 12)
                                .opacity(didAnimateIn ? 1 : 0)
                                .animation(
                                    .spring(response: 0.44, dampingFraction: 0.84)
                                        .delay(Double(index) * 0.02),
                                    value: didAnimateIn
                                )
                        }
                    }

                    LazyVStack(spacing: 12) {
                        ForEach(Array(columns[1].enumerated()), id: \.element.id) { index, note in
                            noteCard(note)
                                .offset(y: didAnimateIn ? 0 : 12)
                                .opacity(didAnimateIn ? 1 : 0)
                                .animation(
                                    .spring(response: 0.44, dampingFraction: 0.84)
                                        .delay(Double(index) * 0.025),
                                    value: didAnimateIn
                                )
                        }
                    }
                }
            }
        }
    }

    private func noteCard(_ note: UHNote) -> some View {
        let color = viewModel.color(for: note)
        let checklist = checklistRows(from: note.content)
        let isChecklistNote = viewModel.isChecklist(note) || (!checklist.isEmpty && !viewModel.isImage(note))
        let noteImage = imageFromData(note.imageAttachments.first)
        let imageCount = note.imageAttachmentCount

        return Button {
            selectedNote = note
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 6) {
                    Text(viewModel.title(for: note))
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(.black.opacity(0.8))
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption.weight(.bold))
                            .foregroundColor(color.tint)
                    }
                }

                if viewModel.isImage(note) {
                    if let noteImage = noteImage {
                        Image(uiImage: noteImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 130)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(.white.opacity(0.55), lineWidth: 1)
                            )
                            .overlay(alignment: .bottomTrailing) {
                                if imageCount > 1 {
                                    Text("\(imageCount) photos")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule(style: .continuous)
                                                .fill(.black.opacity(0.55))
                                        )
                                        .padding(8)
                                }
                            }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.subheadline.weight(.semibold))
                            Text("Add Photo")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.black.opacity(0.58))
                        .frame(maxWidth: .infinity)
                        .frame(height: 74)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.white.opacity(0.38))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(.white.opacity(0.55), lineWidth: 1)
                                )
                        )
                    }
                }

                if !isChecklistNote {
                    Text(viewModel.preview(for: note))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black.opacity(0.72))
                        .lineLimit(8)
                        .multilineTextAlignment(.leading)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(checklist.prefix(6).enumerated()), id: \.offset) { _, item in
                            HStack(spacing: 7) {
                                Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(item.isChecked ? color.tint : .black.opacity(0.45))
                                Text(item.text)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.black.opacity(item.isChecked ? 0.46 : 0.72))
                                    .lineLimit(1)
                                    .strikethrough(item.isChecked)
                            }
                        }
                    }
                }

                Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.black.opacity(0.48))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.55), lineWidth: 1)
                    )
            )
            .shadow(color: color.tint.opacity(0.16), radius: 10, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(note.isPinned ? "Unpin" : "Pin") {
                viewModel.togglePin(note, context: modelContext)
            }
            Button(role: .destructive) {
                viewModel.delete(note, context: modelContext)
            } label: {
                Text("Delete")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white.opacity(0.78))

            Text(viewModel.searchText.isEmpty ? "Capture ideas at a moment's notice" : "No notes matched your search")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(viewModel.searchText.isEmpty ? "Tap + to create your first note." : "Try a different keyword or clear search.")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private var addNoteButton: some View {
        Button {
            showCreateNoteOptions = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.18, green: 0.28, blue: 0.46))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.85), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.24), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 18)
        .padding(.bottom, 18)
    }

    private var notesBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.16, blue: 0.31),
                    Color(red: 0.14, green: 0.25, blue: 0.42),
                    Color(red: 0.21, green: 0.33, blue: 0.50)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 30)
                .offset(x: -150, y: -330)

            Circle()
                .fill(Color.cyan.opacity(0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 42)
                .offset(x: 150, y: 380)
        }
    }

    private func createAndOpenNote(style: NotesBoardViewModel.NoteDraftStyle) {
        let note = viewModel.createNote(style: style, context: modelContext)
        selectedNote = note
    }

    private func checklistRows(from content: String) -> [(text: String, isChecked: Bool)] {
        let lines = content
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        let rows = lines.compactMap { line -> (String, Bool)? in
            if line.hasPrefix("- [ ] ") {
                return (String(line.dropFirst(6)), false)
            }
            if line.hasPrefix("- [x] ") || line.hasPrefix("- [X] ") {
                return (String(line.dropFirst(6)), true)
            }
            return nil
        }

        return rows
    }

    private func imageFromData(_ data: Data?) -> UIImage? {
        guard let data, !data.isEmpty else { return nil }
        return UIImage(data: data)
    }
}

private struct NotesFilterChip: View {
    let title: String
    let isActive: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(isActive ? .black.opacity(0.78) : .white.opacity(0.78))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(isActive ? tint.opacity(0.95) : Color.white.opacity(0.14))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var note: UHNote
    let colors: [NotesBoardViewModel.NoteColor]
    let onSave: (UHNote) -> Void
    let onDelete: (UHNote) -> Void
    let onTogglePin: (UHNote) -> Void
    let onSelectColor: (UHNote, String) -> Void

    @State private var showDeleteAlert = false
    @State private var deleted = false
    @State private var checklistItems: [ChecklistItem] = []
    @State private var isChecklistMode = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isLoadingPhoto = false
    @State private var photoErrorMessage: String?
    @FocusState private var focusField: FocusField?

    private struct ChecklistItem: Identifiable, Hashable {
        var id = UUID()
        var text: String
        var isChecked: Bool
    }

    private enum FocusField: Hashable {
        case title
        case content
        case checklist(UUID)
    }

    private var selectedColor: NotesBoardViewModel.NoteColor {
        colors.first(where: { $0.id == note.colorTag }) ?? colors[0]
    }

    private var isImageMode: Bool {
        note.noteKind == .image
    }

    private var attachedImages: [UIImage] {
        note.imageAttachments.compactMap { UIImage(data: $0) }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [selectedColor.card, selectedColor.card.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.black.opacity(0.72))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(.white.opacity(0.5)))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        onTogglePin(note)
                    } label: {
                        Image(systemName: note.isPinned ? "pin.fill" : "pin")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.black.opacity(0.68))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(.white.opacity(0.45)))
                    }
                    .buttonStyle(.plain)

                    Menu {
                        ForEach(colors) { color in
                            Button {
                                onSelectColor(note, color.id)
                            } label: {
                                Label(color.title, systemImage: "circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(color.tint, color.tint)
                            }
                        }
                    } label: {
                        Image(systemName: "paintpalette")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.black.opacity(0.68))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(.white.opacity(0.45)))
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.black.opacity(0.68))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(.white.opacity(0.45)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 10)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField(
                            "",
                            text: $note.title,
                            prompt: Text("Title").foregroundColor(.black.opacity(0.3)),
                            axis: .vertical
                        )
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundColor(.black)
                            .focused($focusField, equals: .title)

                        Divider()
                            .background(.black.opacity(0.15))

                        if isImageMode {
                            imageAttachmentEditor
                        }

                        if isChecklistMode {
                            checklistEditor
                        } else {
                            TextEditor(text: $note.content)
                                .font(.system(.body, design: .rounded).weight(.medium))
                                .foregroundColor(.black.opacity(0.82))
                                .frame(minHeight: isImageMode ? 220 : 320)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .focused($focusField, equals: .content)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: editorHint.icon)
                                .foregroundColor(selectedColor.tint.opacity(0.8))
                            Text(editorHint.message)
                                .font(.caption.weight(.medium))
                                .foregroundColor(.black.opacity(0.56))
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.white.opacity(0.4))
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 26)
                }
            }

            if focusField != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        focusField = nil
                    }
            }
        }
        .onAppear {
            configureInitialEditorMode()
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            loadSelectedPhotos(from: newItems)
        }
        .onDisappear {
            commitIfNeeded()
        }
        .alert("Delete this note?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleted = true
                onDelete(note)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var checklistEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach($checklistItems) { $item in
                HStack(alignment: .top, spacing: 10) {
                    Button {
                        item.isChecked.toggle()
                        rebuildChecklistContent()
                    } label: {
                        Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                            .font(.headline)
                            .foregroundColor(item.isChecked ? selectedColor.tint : .black.opacity(0.45))
                    }
                    .buttonStyle(.plain)

                    TextField(
                        "",
                        text: $item.text,
                        prompt: Text("List item").foregroundColor(.black.opacity(0.3)),
                        axis: .vertical
                    )
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundColor(.black)
                        .strikethrough(item.isChecked)
                        .focused($focusField, equals: .checklist(item.id))
                        .onChange(of: item.text) { _, _ in
                            rebuildChecklistContent()
                        }

                    if checklistItems.count > 1 {
                        Button(role: .destructive) {
                            removeChecklistItem(id: item.id)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.red.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.42))
                )
            }

            Button {
                addChecklistItem(focus: true)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Item")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(selectedColor.tint)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.44))
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .frame(minHeight: 320, alignment: .top)
    }

    private var imageAttachmentEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            if attachedImages.isEmpty {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.34))
                    .frame(height: 150)
                    .overlay {
                        VStack(spacing: 7) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 20, weight: .semibold))
                            Text("No photos added yet")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.black.opacity(0.58))
                    }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(attachedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 220, height: 170)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(.white.opacity(0.5), lineWidth: 1)
                                    )

                                Button(role: .destructive) {
                                    note.removeImageAttachment(at: index)
                                    photoErrorMessage = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.28), radius: 4, x: 0, y: 2)
                                        .padding(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(height: 176)
            }

            if !attachedImages.isEmpty {
                Text("\(attachedImages.count) photo\(attachedImages.count == 1 ? "" : "s") attached")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.black.opacity(0.58))
            }

            HStack(spacing: 10) {
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: nil,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label(attachedImages.isEmpty ? "Add Photos" : "Add More", systemImage: "photo.on.rectangle.angled")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(selectedColor.tint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(.white.opacity(0.48))
                        )
                }
                .buttonStyle(.plain)

                if note.hasImageAttachment {
                    Button(role: .destructive) {
                        note.setImageAttachments([])
                        photoErrorMessage = nil
                    } label: {
                        Label("Remove All", systemImage: "trash")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.red.opacity(0.74))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(.white.opacity(0.48))
                            )
                    }
                    .buttonStyle(.plain)
                }

                if isLoadingPhoto {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let photoErrorMessage = photoErrorMessage {
                Text(photoErrorMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.red.opacity(0.8))
            }
        }
    }

    private var editorHint: (icon: String, message: String) {
        if isChecklistMode {
            return ("checklist.checked", "Checked items stay visible and crossed out.")
        }
        if isImageMode {
            return ("photo.on.rectangle.angled", "Add one or more photos and write details below.")
        }
        return ("note.text", "Write your note details here.")
    }

    private func configureInitialEditorMode() {
        let parsed = parseChecklistItems(from: note.content)
        let shouldUseChecklist = note.noteKind == .checklist || (!parsed.isEmpty && note.noteKind != .image)

        if shouldUseChecklist {
            isChecklistMode = true
            checklistItems = parsed.isEmpty ? [ChecklistItem(text: "", isChecked: false)] : parsed
            rebuildChecklistContent()
        } else {
            isChecklistMode = false
            checklistItems = []
        }

        if note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            focusField = .title
            return
        }

        if isChecklistMode, let first = checklistItems.first {
            focusField = .checklist(first.id)
        } else {
            focusField = .content
        }
    }

    private func parseChecklistItems(from content: String) -> [ChecklistItem] {
        let lines = content
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var rows: [ChecklistItem] = []

        for line in lines {
            if line.hasPrefix("- [ ] ") {
                rows.append(ChecklistItem(text: String(line.dropFirst(6)), isChecked: false))
                continue
            }
            if line == "- [ ]" {
                rows.append(ChecklistItem(text: "", isChecked: false))
                continue
            }
            if line.hasPrefix("- [x] ") || line.hasPrefix("- [X] ") {
                rows.append(ChecklistItem(text: String(line.dropFirst(6)), isChecked: true))
                continue
            }
            if line == "- [x]" || line == "- [X]" {
                rows.append(ChecklistItem(text: "", isChecked: true))
                continue
            }
        }

        return rows
    }

    private func rebuildChecklistContent() {
        if checklistItems.isEmpty {
            checklistItems = [ChecklistItem(text: "", isChecked: false)]
        }

        note.content = checklistItems
            .map { item in
                let marker = item.isChecked ? "x" : " "
                return "- [\(marker)] \(item.text.trimmingCharacters(in: .newlines))"
            }
            .joined(separator: "\n")
    }

    private func addChecklistItem(focus: Bool) {
        let item = ChecklistItem(text: "", isChecked: false)
        checklistItems.append(item)
        rebuildChecklistContent()
        if focus {
            focusField = .checklist(item.id)
        }
    }

    private func removeChecklistItem(id: UUID) {
        checklistItems.removeAll { $0.id == id }
        if checklistItems.isEmpty {
            checklistItems = [ChecklistItem(text: "", isChecked: false)]
        }
        rebuildChecklistContent()
    }

    private func loadSelectedPhotos(from items: [PhotosPickerItem]) {
        isLoadingPhoto = true
        photoErrorMessage = nil

        Task {
            var loadedImages: [Data] = []

            for item in items {
                do {
                    guard
                        let data = try await item.loadTransferable(type: Data.self),
                        let sourceImage = UIImage(data: data),
                        let optimizedData = optimizedImageData(from: sourceImage)
                    else {
                        continue
                    }
                    loadedImages.append(optimizedData)
                } catch {
                    continue
                }
            }

            await MainActor.run {
                if loadedImages.isEmpty {
                    photoErrorMessage = "Couldn't read selected photos. Please try again."
                } else {
                    for imageData in loadedImages {
                        note.appendImageAttachment(imageData)
                    }
                    photoErrorMessage = nil
                }
                isLoadingPhoto = false
                selectedPhotoItems = []
            }
        }
    }

    private func optimizedImageData(from image: UIImage) -> Data? {
        let maxDimension: CGFloat = 1_800
        let maxSide = max(image.size.width, image.size.height)
        guard maxSide > 0 else { return nil }

        let scale = min(1, maxDimension / maxSide)
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let normalized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return normalized.jpegData(compressionQuality: 0.82)
    }

    private func commitIfNeeded() {
        guard !deleted else { return }

        let title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasChecklistText = parseChecklistItems(from: note.content)
            .contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let hasImageAttachment = note.hasImageAttachment

        if isChecklistMode, title.isEmpty && !hasChecklistText {
            deleted = true
            onDelete(note)
            return
        }

        if !isChecklistMode, title.isEmpty && body.isEmpty && !hasImageAttachment {
            deleted = true
            onDelete(note)
            return
        }

        onSave(note)
    }
}
