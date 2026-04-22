//
//  TaskReminderSheet.swift
//  UtilityHub
//

import SwiftUI

struct TaskReminderSheet: View {
    enum Mode {
        case create
        case edit(title: String)

        var navTitle: String {
            switch self {
            case .create: return "New Task"
            case .edit: return "Edit Reminder"
            }
        }

        var showsTitleField: Bool {
            if case .create = self { return true }
            return false
        }
    }

    let mode: Mode
    let initialTitle: String
    let initialReminder: Date?
    let onSave: (String, Date?) -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var reminderEnabled: Bool
    @State private var reminderDate: Date
    @State private var permissionDenied = false
    @FocusState private var titleFocused: Bool

    init(
        mode: Mode,
        initialTitle: String,
        initialReminder: Date?,
        onSave: @escaping (String, Date?) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.mode = mode
        self.initialTitle = initialTitle
        self.initialReminder = initialReminder
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: initialTitle)
        _reminderEnabled = State(initialValue: initialReminder != nil)
        _reminderDate = State(initialValue: initialReminder ?? Self.defaultFireDate())
    }

    private static func defaultFireDate() -> Date {
        Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientHubBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        if mode.showsTitleField {
                            titleField
                        }
                        reminderCard
                    }
                    .padding(.horizontal, HubTheme.horizontalPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(mode.navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let finalReminder = reminderEnabled ? reminderDate : nil
                        onSave(title.trimmingCharacters(in: .whitespacesAndNewlines), finalReminder)
                    }
                    .disabled(!canSave)
                    .fontWeight(.bold)
                }
            }
            .task {
                if mode.showsTitleField {
                    titleFocused = true
                }
            }
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TASK")
                .font(.caption2.weight(.bold))
                .foregroundColor(.secondary)
                .tracking(0.8)

            TextField("What do you need to do?", text: $title)
                .font(.body.weight(.semibold))
                .focused($titleFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                )
        }
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label {
                    Text("Remind me")
                        .font(.subheadline.weight(.bold))
                } icon: {
                    Image(systemName: reminderEnabled ? "bell.badge.fill" : "bell")
                        .foregroundStyle(reminderEnabled ? AppAccent.current.tintColor : .secondary)
                }

                Spacer()

                Toggle("", isOn: $reminderEnabled)
                    .labelsHidden()
                    .tint(AppAccent.current.tintColor)
                    .onChange(of: reminderEnabled) { _, newValue in
                        if newValue {
                            requestPermission()
                            if reminderDate <= Date() {
                                reminderDate = Self.defaultFireDate()
                            }
                        }
                    }
            }

            if reminderEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    quickPickRow

                    DatePicker(
                        "Reminder time",
                        selection: $reminderDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if permissionDenied {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Notifications are off. Enable them in Settings to receive this reminder.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: HubTheme.cardRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: HubTheme.cardRadius, style: .continuous)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: reminderEnabled)
    }

    private var quickPickRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(QuickPick.options) { pick in
                    Button {
                        reminderDate = pick.date()
                        HapticService.tap()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: pick.icon)
                                .font(.system(size: 11, weight: .bold))
                            Text(pick.label)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(AppAccent.current.tintColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppAccent.current.tintColor.opacity(0.14))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func requestPermission() {
        Task {
            let granted = await NotificationService.shared.ensurePermission()
            await MainActor.run { permissionDenied = !granted }
        }
    }

    private struct QuickPick: Identifiable {
        let id = UUID()
        let label: String
        let icon: String
        let date: () -> Date

        static var options: [QuickPick] {
            [
                QuickPick(label: "In 1 hour", icon: "clock.arrow.circlepath") {
                    Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
                },
                QuickPick(label: "Tonight 8 PM", icon: "moon.stars") {
                    let cal = Calendar.current
                    var comps = cal.dateComponents([.year, .month, .day], from: Date())
                    comps.hour = 20
                    comps.minute = 0
                    let target = cal.date(from: comps) ?? Date()
                    return target > Date() ? target : (cal.date(byAdding: .day, value: 1, to: target) ?? target)
                },
                QuickPick(label: "Tomorrow 9 AM", icon: "sunrise.fill") {
                    let cal = Calendar.current
                    let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    var comps = cal.dateComponents([.year, .month, .day], from: tomorrow)
                    comps.hour = 9
                    comps.minute = 0
                    return cal.date(from: comps) ?? tomorrow
                }
            ]
        }
    }
}
