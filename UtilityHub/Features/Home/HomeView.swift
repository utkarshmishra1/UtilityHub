//
//  HomeView.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("display_name") private var displayName = "User"
    @AppStorage(AppPreferenceKeys.isStudentModeEnabled) private var isStudentModeEnabled = true
    @Binding var selectedTab: AppTab
    @StateObject private var viewModel = HomeViewModel()
    @State private var activeQuickAction: HomeQuickAction?
    @State private var showHabitsBoard = false
    @State private var showNotesBoard = false
    @State private var showExpensesBoard = false
    @State private var showTodoOverlay = false
    @State private var todoInput = ""
    @State private var todoFilter: TodoOverlayFilter = .all
    @State private var editingReminderTask: UHTask?
    @FocusState private var isTodoInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: HubTheme.sectionSpacing) {
                        adBannerSection
                        headerSection
                        quickActionsSection
                        snapshotSection
                        todayTodoSummarySection
                        todayHabitsSummarySection
                        if isStudentModeEnabled {
                            prioritySection
                        }
                        analyticsSection
                    }
                    .padding(.horizontal, HubTheme.horizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
                .background(AmbientHubBackground())

                if showTodoOverlay {
                    todoOverlay
                }
            }
            .navigationBarHidden(true)
            .task {
                viewModel.refresh(context: modelContext)
            }
            .navigationDestination(isPresented: $showHabitsBoard) {
                HabitsBoardView()
                    .onDisappear {
                        viewModel.refresh(context: modelContext)
                    }
            }
            .navigationDestination(isPresented: $showNotesBoard) {
                NotesBoardView()
                    .onDisappear {
                        viewModel.refresh(context: modelContext)
                    }
            }
            .navigationDestination(isPresented: $showExpensesBoard) {
                ExpensesBoardView()
                    .onDisappear {
                        viewModel.refresh(context: modelContext)
                    }
            }
            .onChange(of: showHabitsBoard) { _, isPresented in
                if !isPresented {
                    viewModel.refresh(context: modelContext)
                }
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
        }
    }

    private var adBannerSection: some View {
        HomeTopBannerAdView()
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(greetingText), \(displayName)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text(Date().uhHeaderDate)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                HStack(spacing: 6) {
                    Text("🔥 \(viewModel.streakDays) Day Streak")
                        .font(.subheadline.weight(.semibold))
                    Text("Keep going!")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                selectedTab = .settings
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(HubTheme.accentGradient)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(height: 114, alignment: .top)
    }

    private var quickActionsSection: some View {
        VStack(spacing: 10) {
            HubSectionHeader(title: "Quick Actions")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(HomeQuickAction.allCases) { action in
                        QuickActionButton(
                            symbol: action.symbol,
                            title: action.title,
                            tint: action.tint,
                            isPressed: activeQuickAction == action
                        ) {
                            activeQuickAction = action
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                activeQuickAction = nil
                            }

                            if action == .addTask {
                                openTodoOverlay()
                            } else if action == .addHabit {
                                showHabitsBoard = true
                            } else if action == .addExpense {
                                showExpensesBoard = true
                            } else if action == .notes {
                                showNotesBoard = true
                            } else {
                                viewModel.handleQuickAction(action, context: modelContext)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var snapshotSection: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 14) {
                HubSectionHeader(title: "Today Snapshot")
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tasks: \(viewModel.snapshot.tasksDone)/\(viewModel.snapshot.tasksTotal)")
                            .font(.headline.weight(.semibold))
                        Text("Habits: \(viewModel.snapshot.habitsDone)/\(viewModel.snapshot.habitsTotal)")
                            .font(.headline.weight(.semibold))
                    }

                    if isStudentModeEnabled {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text(viewModel.snapshot.nextClassText)
                                .font(.subheadline.weight(.medium))
                            Text("Attendance Target: \(viewModel.attendanceTarget)%")
                                .font(.subheadline.weight(.medium))
                        }
                    }
                }
            }
        }
    }

    private var todayTodoSummarySection: some View {
        let total = max(viewModel.todayTodos.count, 1)
        let completed = viewModel.todayTodoCompletedCount
        let pending = max(viewModel.todayTodos.count - completed, 0)
        let completionProgress = Double(completed) / Double(total)
        let accent = todoCompletionColor(completionProgress)
        let previewTodos = Array(viewModel.todayTodos.prefix(3))

        return VStack(spacing: 10) {
            HubSectionHeader(
                title: "Today's ToDo",
                trailing: "\(completed)/\(viewModel.todayTodos.count)"
            )

            HubCard {
                if viewModel.todayTodos.isEmpty {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(accent.opacity(0.16))
                                .frame(width: 56, height: 56)
                            Image(systemName: "checklist.checked")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(accent)
                        }

                        Text("No ToDo items for today.")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.primary)

                        Text("Create your first task and keep your day organized.")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            openTodoOverlay()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add ToDo")
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                } else {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            HomeTodoProgressSeal(
                                progress: completionProgress,
                                label: "\(Int((completionProgress * 100).rounded()))%",
                                subtitle: "DONE",
                                tint: accent
                            )
                            .frame(width: 70, height: 70)

                            VStack(alignment: .leading, spacing: 7) {
                                Text(pending == 0 ? "All tasks completed" : "\(pending) pending, stay focused")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.primary)
                                Text("You completed \(completed) of \(viewModel.todayTodos.count) tasks today")
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
                                                    colors: [accent.opacity(0.7), accent],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: proxy.size.width * completionProgress, height: 7)
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
                                        .stroke(accent.opacity(0.24), lineWidth: 1)
                                )
                        )

                        HStack(spacing: 8) {
                            TodoMetricChip(title: "Pending", value: pending, tint: .orange)
                            TodoMetricChip(title: "Done", value: completed, tint: .green)
                            Spacer()
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 8) {
                            ForEach(previewTodos) { task in
                                todoSummaryPreviewRow(task, accent: accent)
                                if task.id != previewTodos.last?.id {
                                    Divider()
                                        .opacity(0.5)
                                }
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemBackground).opacity(0.58))
                        )

                        Button {
                            openTodoOverlay()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption.weight(.bold))
                                Text("Open ToDo")
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

    private var todayHabitsSummarySection: some View {
        let total = max(viewModel.homeHabits.count, 1)
        let completed = viewModel.todayHabitCompletedCount
        let completionProgress = Double(completed) / Double(total)
        let accent = habitsCompletionColor(completionProgress)

        return VStack(spacing: 10) {
            HubSectionHeader(
                title: "Today's Habits",
                trailing: "\(viewModel.todayHabitCompletedCount)/\(viewModel.homeHabits.count)"
            )

            HubCard {
                if viewModel.homeHabits.isEmpty {
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
                        Text("No habits yet. Use Add Habit quick action to start tracking.")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            HomeHabitProgressSeal(
                                progress: completionProgress,
                                label: "\(completed)",
                                subtitle: "DONE",
                                tint: accent
                            )
                            .frame(width: 68, height: 68)

                            VStack(alignment: .leading, spacing: 7) {
                                Text("Habit Summary")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.primary)
                                Text("\(completed) of \(viewModel.homeHabits.count) completed today")
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
                                            .frame(width: proxy.size.width * completionProgress, height: 7)
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

    private func todoCompletionColor(_ progress: Double) -> Color {
        switch progress {
        case 0.8...:
            return Color(red: 0.20, green: 0.86, blue: 0.54)
        case 0.6..<0.8:
            return Color(red: 0.32, green: 0.74, blue: 1.0)
        case 0.35..<0.6:
            return Color(red: 0.99, green: 0.74, blue: 0.35)
        default:
            return Color(red: 0.98, green: 0.45, blue: 0.43)
        }
    }

    private var analyticsSection: some View {
        VStack(spacing: 10) {
            HubSectionHeader(title: "Analytics Preview")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                analyticsCard(title: "Productivity", value: viewModel.analytics.productivityPercent.asPercentageText, symbol: "chart.bar.fill") {
                    selectedTab = .productivity
                }
                if isStudentModeEnabled {
                    analyticsCard(title: "Attendance", value: viewModel.analytics.attendancePercent.asPercentageText, symbol: "checkmark.seal.fill") {
                        selectedTab = .student
                    }
                } else {
                    analyticsCard(title: "Habits Done", value: "\(viewModel.todayHabitCompletedCount)", symbol: "checkmark.circle.fill") {
                        showHabitsBoard = true
                    }
                }
                analyticsCard(title: "Pending ToDo", value: "\(pendingTodoCount)", symbol: "list.bullet.clipboard.fill") {
                    selectedTab = .productivity
                }
                analyticsCard(title: "Habit Streak", value: "\(viewModel.analytics.longestHabitStreak) days", symbol: "flame.fill") {
                    selectedTab = .productivity
                }
            }
        }
    }

    private var prioritySection: some View {
        VStack(spacing: 10) {
            HubSectionHeader(title: "Attendance Summary")
            HubCard {
                HStack(alignment: .top, spacing: 12) {
                    HomePriorityAttendanceGraph(
                        progress: Double(viewModel.analytics.attendancePercent) / 100,
                        label: viewModel.analytics.attendancePercent.asPercentageText,
                        tint: viewModel.overallAttendanceColor()
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(attendancePriorityTitle)
                            .font(.subheadline.weight(.semibold))
                        Text(attendancePriorityDetail)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Open") {
                        selectedTab = .student
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var attendancePriorityTitle: String {
        let percent = viewModel.analytics.attendancePercent
        let target = viewModel.attendanceTarget
        if percent >= target {
            return "Attendance on track"
        }
        return "Attendance below target"
    }

    private var attendancePriorityDetail: String {
        let percent = viewModel.analytics.attendancePercent
        let target = viewModel.attendanceTarget
        if percent >= target {
            return "You're at \(percent)% and target is \(target)%. Keep this consistency."
        }
        return "You're at \(percent)% with target \(target)%. Open Student to recover attendance."
    }

    private func analyticsCard(title: String, value: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HubCard {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: symbol)
                        .foregroundStyle(HubTheme.accentGradient)
                    Text(value)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Text(title)
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 17 { return "Good Afternoon" }
        return "Good Evening"
    }

    private var pendingTodoCount: Int {
        viewModel.todayTodos.filter { !$0.isCompleted }.count
    }

    private var filteredTodos: [UHTask] {
        switch todoFilter {
        case .all:
            return viewModel.todayTodos
        case .pending:
            return viewModel.todayTodos.filter { !$0.isCompleted }
        case .completed:
            return viewModel.todayTodos.filter(\.isCompleted)
        }
    }

    private func todoSummaryPreviewRow(_ task: UHTask, accent: Color) -> some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                    viewModel.toggleTodo(task, context: modelContext)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(task.isCompleted ? accent : .secondary)
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(task.isCompleted ? .secondary : .primary)
                .strikethrough(task.isCompleted)
                .lineLimit(1)

            Spacer()

            if !task.isCompleted {
                Button {
                    editingReminderTask = task
                } label: {
                    Image(systemName: task.reminderAt == nil ? "bell" : "bell.badge.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(task.reminderAt == nil ? Color.secondary : AppAccent.current.tintColor)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill((task.reminderAt == nil ? Color.secondary : AppAccent.current.tintColor).opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }

            Text(task.isCompleted ? "Done" : "Pending")
                .font(.caption2.weight(.bold))
                .foregroundColor(task.isCompleted ? .green : .orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill((task.isCompleted ? Color.green : Color.orange).opacity(0.14))
                )
        }
    }

    private var todoOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.46),
                    Color.black.opacity(0.36)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
                .ignoresSafeArea()
                .onTapGesture {
                    closeTodoOverlay()
                }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.35, green: 0.80, blue: 1.0),
                                            Color(red: 0.36, green: 0.95, blue: 0.63)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 34, height: 34)
                            Image(systemName: "checklist")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.black.opacity(0.8))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("ToDo")
                                .font(.system(.title3, design: .rounded).weight(.bold))
                            Text(Date().formatted(date: .abbreviated, time: .omitted))
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        TodoMetricChip(title: "Pending", value: pendingTodoCount, tint: .orange)
                        TodoMetricChip(title: "Done", value: viewModel.todayTodoCompletedCount, tint: .green)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.40, green: 0.83, blue: 1.0), .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    TextField("Write your task...", text: $todoInput)
                        .focused($isTodoInputFocused)
                        .textFieldStyle(.plain)
                    Button {
                        viewModel.addTodo(title: todoInput, context: modelContext)
                        todoInput = ""
                        isTodoInputFocused = true
                    } label: {
                        Text("Add")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.31, green: 0.94, blue: 0.62), Color(red: 0.36, green: 0.83, blue: 1.0)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(todoInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(todoInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground).opacity(0.85))
                )

                HStack(spacing: 8) {
                    ForEach(TodoOverlayFilter.allCases) { filter in
                        TodoFilterPill(
                            title: filter.title,
                            isSelected: todoFilter == filter,
                            action: {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                                    todoFilter = filter
                                }
                            }
                        )
                    }
                    Spacer()
                    Button {
                        closeTodoOverlay()
                    } label: {
                        Text("Close")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                            )
                    }
                    .buttonStyle(.plain)
                }

                if filteredTodos.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text(todoFilter == .all ? "No tasks for today yet." : "No \(todoFilter.title.lowercased()) tasks for today.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 9) {
                            ForEach(filteredTodos) { task in
                                todoRow(task)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .padding(.vertical, 1)
                    }
                    .frame(maxHeight: 248)
                }

                Text("Completed tasks remain visible for today.")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(16)
            .frame(maxWidth: 370)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Color.cyan.opacity(0.25))
                    .frame(width: 70, height: 70)
                    .blur(radius: 18)
                    .offset(x: 18, y: -16)
            }
            .shadow(color: .black.opacity(0.30), radius: 26, x: 0, y: 16)
            .padding(.horizontal, 20)
            .transition(.opacity.combined(with: .scale(scale: 0.94)))
        }
        .zIndex(2)
    }

    private func todoRow(_ task: UHTask) -> some View {
        HStack(spacing: 11) {
            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                    viewModel.toggleTodo(task, context: modelContext)
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? Color.green.opacity(0.25) : Color.gray.opacity(0.28), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if task.isCompleted {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(task.isCompleted ? "Completed" : "Pending")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(task.isCompleted ? .green : .orange)

                    if !task.isCompleted, let reminder = task.reminderAt {
                        reminderInlineChip(for: reminder)
                    }
                }
            }

            Spacer()

            if !task.isCompleted {
                Button {
                    editingReminderTask = task
                } label: {
                    Image(systemName: task.reminderAt == nil ? "bell" : "bell.badge.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(task.reminderAt == nil ? Color.secondary : AppAccent.current.tintColor)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill((task.reminderAt == nil ? Color.secondary : AppAccent.current.tintColor).opacity(0.10))
                        )
                }
                .buttonStyle(.plain)
            }

            Button(role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.deleteTodo(task, context: modelContext)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.red.opacity(0.85))
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.red.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground).opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(task.isCompleted ? Color.green.opacity(0.2) : Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(task.isCompleted ? 0.86 : 1)
    }

    @ViewBuilder
    private func reminderInlineChip(for date: Date) -> some View {
        let fired = date <= Date()
        let tint = fired ? Color.secondary : AppAccent.current.tintColor
        HStack(spacing: 3) {
            Image(systemName: fired ? "bell.slash.fill" : "bell.fill")
                .font(.system(size: 8, weight: .bold))
            Text(homeReminderLabel(date))
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule(style: .continuous).fill(tint.opacity(0.14)))
    }

    private func homeReminderLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return date.uhShortTime }
        if cal.isDateInTomorrow(date) { return "Tmrw \(date.uhShortTime)" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    private func closeTodoOverlay() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            showTodoOverlay = false
        }
        todoInput = ""
        todoFilter = .all
        isTodoInputFocused = false
    }

    private func openTodoOverlay() {
        viewModel.refresh(context: modelContext)
        todoFilter = .all
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            showTodoOverlay = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isTodoInputFocused = true
        }
    }
}

private struct HomePriorityAttendanceGraph: View {
    let progress: Double
    let label: String
    let tint: Color

    private var clampedProgress: Double {
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
                        endRadius: 36
                    )
                )

            Circle()
                .stroke(tint.opacity(0.16), lineWidth: 9)

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.25), tint.opacity(0.65), tint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.42, dampingFraction: 0.84), value: clampedProgress)

            VStack(spacing: 0) {
                Text(label)
                    .font(.caption.weight(.bold))
                    .foregroundColor(tint)
                Text("OVERALL")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(0.3)
            }
        }
        .frame(width: 72, height: 72)
    }
}

private struct HomeHabitProgressSeal: View {
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

private struct HomeTodoProgressSeal: View {
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
                        startRadius: 8,
                        endRadius: 36
                    )
                )

            Circle()
                .stroke(tint.opacity(0.14), lineWidth: 8)

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.4), tint.opacity(0.75), tint],
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

private enum TodoOverlayFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .pending: return "Pending"
        case .completed: return "Completed"
        }
    }
}

private struct TodoMetricChip: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)
            Text("\(title) \(value)")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

private struct TodoFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(isSelected ? .black : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            isSelected
                            ? LinearGradient(
                                colors: [Color(red: 0.36, green: 0.92, blue: 0.62), Color(red: 0.40, green: 0.82, blue: 1.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color(uiColor: .secondarySystemBackground), Color(uiColor: .secondarySystemBackground)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
