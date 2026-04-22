//
//  ProductivityView.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import SwiftUI
import SwiftData
import Charts

struct ProductivityView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ProductivityViewModel()
    @State private var showAddTaskSheet = false
    @State private var showHabitsBoard = false
    @State private var newTaskTitle = ""
    @State private var editingReminderTask: UHTask?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: HubTheme.sectionSpacing) {
                        tasksSection
                        habitsSection
                        focusSection
                        chartSection
                    }
                    .padding(.horizontal, HubTheme.horizontalPadding)
                    .padding(.vertical, 12)
                    .padding(.bottom, 80)
                }
                .background(AmbientHubBackground())
                .navigationTitle("Productivity")
                .task {
                    viewModel.refresh(context: modelContext)
                }

                Button {
                    showAddTaskSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(HubTheme.accentGradient, in: Circle())
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 10)
            }
            .sheet(isPresented: $showAddTaskSheet, onDismiss: { newTaskTitle = "" }) {
                TaskReminderSheet(
                    mode: .create,
                    initialTitle: newTaskTitle,
                    initialReminder: nil
                ) { title, reminder in
                    viewModel.addTask(title: title, reminderAt: reminder, context: modelContext)
                    showAddTaskSheet = false
                    newTaskTitle = ""
                } onCancel: {
                    showAddTaskSheet = false
                    newTaskTitle = ""
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingReminderTask) { task in
                TaskReminderSheet(
                    mode: .edit(title: task.title),
                    initialTitle: task.title,
                    initialReminder: task.reminderAt
                ) { _, reminder in
                    viewModel.updateReminder(reminder, for: task, context: modelContext)
                    editingReminderTask = nil
                } onCancel: {
                    editingReminderTask = nil
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .navigationDestination(isPresented: $showHabitsBoard) {
                HabitsBoardView()
                    .onDisappear {
                        viewModel.refresh(context: modelContext)
                    }
            }
        }
    }

    private var tasksSection: some View {
        VStack(spacing: 12) {
            HubSectionHeader(title: "Today's Tasks", trailing: "\(viewModel.tasks.filter(\.isCompleted).count)/\(viewModel.tasks.count)")

            Picker("Task Filter", selection: $viewModel.taskFilter) {
                ForEach(TaskFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            HubCard {
                if viewModel.filteredTasks.isEmpty {
                    Text("No tasks yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.filteredTasks) { task in
                            taskRow(task)
                            if task.id != viewModel.filteredTasks.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private func taskRow(_ task: UHTask) -> some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut) {
                    viewModel.toggleTask(task, context: modelContext)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                reminderChip(for: task)
            }

            Spacer()

            if !task.isCompleted {
                Button {
                    editingReminderTask = task
                } label: {
                    Image(systemName: task.reminderAt == nil ? "bell" : "bell.badge.fill")
                        .font(.subheadline)
                        .foregroundStyle(task.reminderAt == nil ? Color.secondary : AppAccent.current.tintColor)
                }
                .buttonStyle(.plain)
            }

            Button {
                withAnimation(.easeInOut) {
                    viewModel.deleteTask(task, context: modelContext)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .opacity(task.isCompleted ? 0.74 : 1)
        .contextMenu {
            if !task.isCompleted {
                Button {
                    editingReminderTask = task
                } label: {
                    Label(task.reminderAt == nil ? "Set Reminder" : "Edit Reminder",
                          systemImage: "bell.badge")
                }
                if task.reminderAt != nil {
                    Button(role: .destructive) {
                        viewModel.updateReminder(nil, for: task, context: modelContext)
                    } label: {
                        Label("Remove Reminder", systemImage: "bell.slash")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func reminderChip(for task: UHTask) -> some View {
        if !task.isCompleted, let reminder = task.reminderAt {
            let fired = reminder <= Date()
            HStack(spacing: 4) {
                Image(systemName: fired ? "bell.slash.fill" : "bell.fill")
                    .font(.system(size: 9, weight: .bold))
                Text(reminderLabel(reminder))
                    .font(.caption2.weight(.semibold))
            }
            .foregroundColor(fired ? .secondary : AppAccent.current.tintColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill((fired ? Color.secondary : AppAccent.current.tintColor).opacity(0.14))
            )
        } else if let dueDate = task.dueDate {
            Text("Added \(dueDate.uhShortTime)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func reminderLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today \(date.uhShortTime)"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow \(date.uhShortTime)"
        } else {
            let f = DateFormatter()
            f.dateFormat = "MMM d, h:mm a"
            return f.string(from: date)
        }
    }

    private var habitsSection: some View {
        let completed = viewModel.habitSummary.completedToday
        let total = max(viewModel.habitSummary.total, 1)
        let progress = Double(completed) / Double(total)
        let accent = habitsCompletionColor(progress)

        return VStack(spacing: 12) {
            HubSectionHeader(title: "Habit Summary", trailing: "\(completed)/\(viewModel.habitSummary.total)")

            HubCard {
                if viewModel.habitSummary.total == 0 {
                    VStack(spacing: 10) {
                        Image(systemName: "sparkles.rectangle.stack")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("No habits yet. Open tracker to add your first habit.")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            ProductivityHabitProgressSeal(
                                progress: progress,
                                label: "\(completed)",
                                subtitle: "DONE",
                                tint: accent
                            )
                            .frame(width: 68, height: 68)

                            VStack(alignment: .leading, spacing: 7) {
                                Text("Daily Habit Score")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.primary)
                                Text("\(completed) of \(viewModel.habitSummary.total) completed today")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.secondary)

                                GeometryReader { proxy in
                                    ZStack(alignment: .leading) {
                                        Capsule(style: .continuous)
                                            .fill(Color.secondary.opacity(0.16))
                                            .frame(height: 7)
                                        Capsule(style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [accent.opacity(0.72), accent],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: proxy.size.width * progress, height: 7)
                                    }
                                }
                                .frame(height: 7)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [accent.opacity(0.14), accent.opacity(0.06)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(accent.opacity(0.22), lineWidth: 1)
                                )
                        )

                        HStack(spacing: 8) {
                            Label("\(viewModel.habitSummary.longestStreak) day best streak", systemImage: "flame.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 6)

                        Button {
                            showHabitsBoard = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption.weight(.bold))
                                Text("Open Habit Tracker")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundColor(accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(accent.opacity(0.12))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func habitsCompletionColor(_ progress: Double) -> Color {
        switch progress {
        case 0.8...:
            return Color(red: 0.22, green: 0.84, blue: 0.56)
        case 0.6..<0.8:
            return Color(red: 0.27, green: 0.74, blue: 1.0)
        case 0.4..<0.6:
            return Color(red: 1.0, green: 0.72, blue: 0.32)
        default:
            return Color(red: 1.0, green: 0.43, blue: 0.41)
        }
    }

    private var focusSection: some View {
        VStack(spacing: 12) {
            HubSectionHeader(title: "Focus (Pomodoro)")

            HubCard {
                VStack(spacing: 12) {
                    ProgressRingView(
                        progress: viewModel.focusProgress,
                        color: Color(red: 0.33, green: 0.45, blue: 0.93),
                        lineWidth: 10,
                        label: focusTimeText
                    )
                    .frame(width: 140, height: 140)
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 10) {
                        Button(viewModel.isFocusRunning ? "Pause" : "Start") {
                            viewModel.startOrPauseFocus(context: modelContext)
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Reset") {
                            viewModel.resetFocus()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var chartSection: some View {
        VStack(spacing: 12) {
            HubSectionHeader(title: "Weekly Productivity Chart")

            HubCard {
                Chart(viewModel.weeklyScores) { item in
                    BarMark(
                        x: .value("Day", item.label),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(HubTheme.accentGradient)
                    .cornerRadius(4)
                }
                .frame(height: 160)
            }
        }
    }

    private var focusTimeText: String {
        let minutes = viewModel.focusRemainingSeconds / 60
        let seconds = viewModel.focusRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

}


private struct ProductivityHabitProgressSeal: View {
    let progress: Double
    let label: String
    let subtitle: String
    let tint: Color

    private var clamped: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 6,
                        endRadius: 34
                    )
                )

            Circle()
                .stroke(tint.opacity(0.14), lineWidth: 8)

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.42), tint.opacity(0.75), tint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.42, dampingFraction: 0.84), value: clamped)

            VStack(spacing: 0) {
                Text(label)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
}
