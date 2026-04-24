//
//  HabitsBoardView.swift
//  UtilityHub
//
//  Created by Codex on 04/03/26.
//

import SwiftUI
import SwiftData

struct HabitsBoardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HabitsBoardViewModel()
    @State private var showAddHabitSheet = false
    @State private var didAnimateIn = false
    @State private var swipedHabitID: UUID?
    @State private var draggingHabitID: UUID?
    @State private var draggingOffset: CGFloat = 0
    @State private var animatedWeeklyProgress: Double = 0

    private let daySpacing: CGFloat = 6
    private let swipeDeleteWidth: CGFloat = 86
    private let rowDotCount: Int = 6
    private let dayColumnWidth: CGFloat = 34

    var body: some View {
        ZStack {
            habitsBackdrop

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    heroCard

                    if viewModel.habits.isEmpty {
                        emptyState
                    } else {
                        habitsSectionHeader
                        weekDayHeader
                        LazyVStack(spacing: 11) {
                            ForEach(Array(viewModel.habits.enumerated()), id: \.element.id) { index, habit in
                                habitRow(habit)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    .animation(
                                        .spring(response: 0.38, dampingFraction: 0.84)
                                            .delay(Double(index) * 0.03),
                                        value: didAnimateIn
                                    )
                            }
                        }

                        heatmapCard
                            .padding(.top, 6)
                    }

                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Habits")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showAddHabitSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                }
                .foregroundColor(.white)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.visible, for: .navigationBar)
        .task {
            viewModel.refresh(context: modelContext)
            withAnimation(.spring(response: 0.44, dampingFraction: 0.84)) {
                didAnimateIn = true
            }
            animatedWeeklyProgress = 0
            try? await Task.sleep(nanoseconds: 180_000_000)
            animatedWeeklyProgress = viewModel.overallWeekProgress()
        }
        .onChange(of: viewModel.totalCompleted) { _, _ in
            animatedWeeklyProgress = viewModel.overallWeekProgress()
        }
        .sheet(isPresented: $showAddHabitSheet) {
            HabitEditorSheet(mode: .create) { title, iconID, hex in
                _ = viewModel.addHabit(
                    title: title,
                    iconID: iconID,
                    colorHex: hex,
                    context: modelContext
                )
                showAddHabitSheet = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $viewModel.editingHabit) { habit in
            HabitEditorSheet(
                mode: .edit(
                    initialTitle: habit.title,
                    initialIconID: viewModel.icon(for: habit).id,
                    initialHex: viewModel.swatchHex(for: habit)
                )
            ) { title, iconID, hex in
                viewModel.updateHabit(
                    habit,
                    title: title,
                    iconID: iconID,
                    colorHex: hex,
                    context: modelContext
                )
                viewModel.closeEditor()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $viewModel.selectedHabit) { habit in
            HabitMonthDetailView(viewModel: viewModel, habit: habit)
        }
    }

    private var heroCard: some View {
        let todayDone = viewModel.habits.filter { viewModel.didComplete($0, on: Date()) }.count
        let totalHabits = viewModel.habits.count
        let weeklyProgress = viewModel.overallWeekProgress()
        let weeklyPercent = Int((weeklyProgress * 100).rounded())
        let weeklyTint = weeklyProgressColor(weeklyProgress)
        let streak = viewModel.globalStreak
        let improvement = viewModel.improvementPercent
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Stay consistent, see the results.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(.white.opacity(0.72))

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.58, blue: 0.21).opacity(0.30),
                                            Color(red: 1.0, green: 0.35, blue: 0.13).opacity(0.18)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 54, height: 54)
                            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                                let t = context.date.timeIntervalSinceReferenceDate
                                let scaleY = 1.0 + 0.07 * sin(t * 3.2)
                                let scaleX = 1.0 + 0.04 * sin(t * 2.4 + 1.3)
                                let rotation = 3.0 * sin(t * 2.1 + 0.6)
                                let offsetY = -1.2 + 1.2 * sin(t * 3.7)
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(red: 1.0, green: 0.72, blue: 0.32), Color(red: 1.0, green: 0.38, blue: 0.18)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .scaleEffect(x: scaleX, y: scaleY, anchor: .bottom)
                                    .rotationEffect(.degrees(rotation), anchor: .bottom)
                                    .offset(y: offsetY)
                            }
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text("\(streak)")
                                    .font(.system(.title2, design: .rounded).weight(.heavy))
                                    .foregroundColor(.white)
                                Text("Day Streak")
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(red: 1.0, green: 0.78, blue: 0.36), Color(red: 1.0, green: 0.55, blue: 0.26)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            Text(streakMessage(for: streak))
                                .font(.caption.weight(.medium))
                                .foregroundColor(.white.opacity(0.70))
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    streakTrail
                }

                Spacer(minLength: 0)

                weeklyProgressRing(progress: weeklyProgress, percent: weeklyPercent)
                    .frame(width: 132, height: 132)
//                    .offset(x: -28, y: -10)
            }

            HStack(spacing: 10) {
                HeroMetricChip(
                    icon: "checkmark.circle.fill",
                    tint: Color(red: 0.68, green: 0.42, blue: 1.0),
                    value: "\(todayDone)/\(totalHabits)",
                    label: "Done Today"
                )
                HeroMetricChip(
                    icon: "chart.line.uptrend.xyaxis",
                    tint: Color(red: 0.30, green: 0.88, blue: 0.55),
                    value: improvementValueLabel(viewModel.improvementPercent),
                    label: "Improvement"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.13, green: 0.15, blue: 0.22),
                            Color(red: 0.09, green: 0.11, blue: 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.32), radius: 18, x: 0, y: 12)
    }

    private var streakTrail: some View {
        let trailDays = Array(viewModel.weekDates.reversed().suffix(6))
        return HStack(spacing: 6) {
            ForEach(trailDays, id: \.self) { day in
                let anyDone = viewModel.habits.contains { viewModel.didComplete($0, on: day) }
                Capsule(style: .continuous)
                    .fill(
                        anyDone
                        ? LinearGradient(
                            colors: [Color(red: 1.0, green: 0.72, blue: 0.32), Color(red: 1.0, green: 0.48, blue: 0.22)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.14), Color.white.opacity(0.10)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 18, height: 6)
            }
        }
    }

    private var habitsSectionHeader: some View {
        HStack(alignment: .center) {
            Text("Today's Habits")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(.white)
            Spacer()
            Button {
                showAddHabitSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color(red: 0.36, green: 0.72, blue: 1.0))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 2)
    }

    private var heatmapCard: some View {
        let today = Date().uhDayStart
        let weeks = 52
        let calendar = Calendar.current
        let weekdayOffset = (calendar.component(.weekday, from: today) - calendar.firstWeekday + 7) % 7
        let daysAfterToday = 6 - weekdayOffset
        let totalCells = weeks * 7
        let startDate = calendar.date(byAdding: .day, value: -(totalCells - 1 - daysAfterToday), to: today)?.uhDayStart ?? today
        let totalHabits = max(viewModel.habits.count, 1)

        let windowCompletions = (0..<totalCells).reduce(0) { acc, idx in
            guard let d = calendar.date(byAdding: .day, value: idx, to: startDate) else { return acc }
            if d > today { return acc }
            return acc + viewModel.completionsOnDay(d)
        }

        // Build month labels per column (show when month changes)
        var monthLabels: [Int: String] = [:]
        var lastMonth = -1
        let monthSymbols = calendar.shortMonthSymbols
        for week in 0..<weeks {
            guard let colStart = calendar.date(byAdding: .day, value: week * 7, to: startDate) else { continue }
            let month = calendar.component(.month, from: colStart)
            if month != lastMonth {
                monthLabels[week] = monthSymbols[month - 1]
                lastMonth = month
            }
        }

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Activity")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                    Text("Last 12 months")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.55))
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(windowCompletions)")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundColor(.white)
                    Text("check-ins")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            HStack(alignment: .top, spacing: 6) {
                VStack(spacing: 3) {
                    Color.clear.frame(height: 12)
                    ForEach(0..<7, id: \.self) { idx in
                        Text(shortWeekdayLabel(forRowIndex: idx))
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(idx % 2 == 1 ? 0.55 : 0.0))
                            .frame(height: 12)
                    }
                }
                .frame(width: 18)

                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 3) {
                        ZStack(alignment: .topLeading) {
                            HStack(spacing: 3) {
                                ForEach(0..<weeks, id: \.self) { _ in
                                    Color.clear.frame(width: 12, height: 12)
                                }
                            }
                            ForEach(Array(monthLabels.keys.sorted()), id: \.self) { weekIdx in
                                Text(monthLabels[weekIdx] ?? "")
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.58))
                                    .fixedSize()
                                    .offset(x: CGFloat(weekIdx) * 15)
                            }
                        }
                        .frame(height: 12)

                        HStack(spacing: 3) {
                            ForEach(0..<weeks, id: \.self) { week in
                                VStack(spacing: 3) {
                                    ForEach(0..<7, id: \.self) { day in
                                        let idx = week * 7 + day
                                        let cellDate = (calendar.date(byAdding: .day, value: idx, to: startDate) ?? startDate).uhDayStart
                                        let isFuture = cellDate > today
                                        let completions = isFuture ? 0 : viewModel.completionsOnDay(cellDate)
                                        let intensity = isFuture ? -1.0 : Double(completions) / Double(totalHabits)
                                        HeatCell(
                                            intensity: intensity,
                                            isToday: calendar.isDate(cellDate, inSameDayAs: today)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.trailing, 4)
                }
                .defaultScrollAnchor(.trailing)
            }

            HStack(spacing: 6) {
                Spacer()
                Text("Less")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.52))
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(HabitsBoardView.heatmapColor(intensity: Double(i) / 4.0))
                        .frame(width: 12, height: 12)
                }
                Text("More")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.52))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.14, blue: 0.22),
                            Color(red: 0.08, green: 0.10, blue: 0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func shortWeekdayLabel(forRowIndex idx: Int) -> String {
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return symbols[(idx + first) % symbols.count]
    }

    static func heatmapColor(intensity: Double) -> Color {
        if intensity < 0 { return Color.white.opacity(0.03) }
        if intensity <= 0.01 { return Color.white.opacity(0.08) }
        if intensity <= 0.25 { return Color(red: 0.42, green: 0.38, blue: 0.90).opacity(0.42) }
        if intensity <= 0.50 { return Color(red: 0.50, green: 0.42, blue: 0.95).opacity(0.62) }
        if intensity <= 0.75 { return Color(red: 0.58, green: 0.44, blue: 1.00).opacity(0.82) }
        return Color(red: 0.72, green: 0.48, blue: 1.0)
    }

    @ViewBuilder
    private func weeklyProgressRing(progress: Double, percent: Int) -> some View {
        let clamped = min(max(animatedWeeklyProgress, 0), 1)
        let lineWidth: CGFloat = 14
        let ringColors: [Color] = [
            Color(red: 0.52, green: 0.84, blue: 1.00),
            Color(red: 0.42, green: 0.60, blue: 1.00),
            Color(red: 0.56, green: 0.44, blue: 0.98),
            Color(red: 0.72, green: 0.52, blue: 1.00),
            Color(red: 0.52, green: 0.84, blue: 1.00)
        ]

        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let breath = 0.5 + 0.5 * sin(t * 1.6)
            let sparkleScale = 0.92 + 0.12 * (0.5 + 0.5 * sin(t * 2.2))

            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.55, green: 0.44, blue: 1.0).opacity(0.22 + 0.14 * breath),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 4,
                                endRadius: size * 0.62
                            )
                        )
                        .blur(radius: 6)

                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.16),
                                            Color.white.opacity(0.02),
                                            Color.black.opacity(0.18)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .blendMode(.plusLighter)
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.38),
                                            Color.white.opacity(0.06),
                                            Color.white.opacity(0.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .padding(lineWidth / 2)

                    Circle()
                        .stroke(Color.white.opacity(0.07), lineWidth: lineWidth)

                    Circle()
                        .trim(from: 0, to: clamped)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: ringColors),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color(red: 0.54, green: 0.44, blue: 1.0).opacity(0.32 + 0.18 * breath),
                                radius: 10 + 4 * breath, x: 0, y: 0)
                        .animation(.spring(response: 1.0, dampingFraction: 0.72), value: animatedWeeklyProgress)

                    VStack(spacing: 6) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.95), Color(red: 0.75, green: 0.60, blue: 1.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .scaleEffect(sparkleScale)
                            .shadow(color: Color(red: 0.72, green: 0.56, blue: 1.0).opacity(0.45),
                                    radius: 4, x: 0, y: 0)

                        Text("\(percent)%")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())

                        Text("Weekly Score")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.62))
                    }
                }
                .frame(width: size, height: size)
            }
        }
    }

    private func improvementValueLabel(_ percent: Int) -> String {
        if percent > 0 { return "+\(percent)%" }
        if percent < 0 { return "\(percent)%" }
        return "0%"
    }

    private func streakMessage(for streak: Int) -> String {
        switch streak {
        case 0: return "Start today — every streak begins with one day."
        case 1...2: return "Nice start! Keep the momentum going."
        case 3...6: return "Keep going! You're doing great."
        case 7...13: return "A full week — you're on fire."
        default: return "Legendary streak. Don't break the chain."
        }
    }

    private func habitRow(_ habit: UHHabit) -> some View {
        let color = viewModel.color(for: habit)
        let icon = viewModel.icon(for: habit)
        let trailDays = Array(viewModel.weekDates.reversed().suffix(rowDotCount))
        let todayDate = trailDays.last ?? Date().uhDayStart

        let rowContent = HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.46), color.opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(color.opacity(0.55), lineWidth: 0.9)
                    )
                Image(systemName: icon.systemName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
            }
            .frame(width: 38, height: 38)

            Text(habit.title)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 6)

            HStack(spacing: 0) {
                ForEach(trailDays, id: \.self) { day in
                    let completed = viewModel.didComplete(habit, on: day)
                    let isToday = viewModel.isToday(day)
                    Group {
                        if isToday {
                            Button {
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                                    viewModel.toggleToday(for: habit, context: modelContext)
                                }
                            } label: {
                                HabitDayDot(completed: completed, tint: color, isToday: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            HabitDayDot(completed: completed, tint: color, isToday: false)
                        }
                    }
                    .frame(width: dayColumnWidth)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.13, green: 0.16, blue: 0.22),
                            Color(red: 0.09, green: 0.11, blue: 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(color.opacity(0.22), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .offset(x: rowOffset(for: habit.id))
        .simultaneousGesture(swipeGesture(for: habit))
        .onTapGesture {
            if swipedHabitID != nil {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    closeSwipeState()
                }
                return
            }

            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                viewModel.openDetail(for: habit)
            }
        }
        .contextMenu {
            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                    viewModel.toggleToday(for: habit, context: modelContext)
                }
            } label: {
                Label(
                    viewModel.didComplete(habit, on: todayDate) ? "Undo Today" : "Mark Today",
                    systemImage: "checkmark.circle.fill"
                )
            }
            Button {
                viewModel.openEditor(for: habit)
            } label: {
                Label("Edit Habit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    closeSwipeState()
                    viewModel.deleteHabit(habit, context: modelContext)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }

        return ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.red.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.red.opacity(0.38), lineWidth: 1)
                )

            Button(role: .destructive) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    closeSwipeState()
                    viewModel.deleteHabit(habit, context: modelContext)
                }
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "trash.fill")
                        .font(.subheadline.weight(.bold))
                    Text("Delete")
                        .font(.caption2.weight(.bold))
                }
                .foregroundColor(.white)
                .frame(width: swipeDeleteWidth - 6, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.red.opacity(0.75))
                )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 5)
            .opacity(rowOffset(for: habit.id) < -6 ? 1 : 0)
            .allowsHitTesting(rowOffset(for: habit.id) < -6)

            rowContent
        }
        .clipped()
    }

    private var weekDayHeader: some View {
        let trailDays = Array(viewModel.weekDates.reversed().suffix(rowDotCount))
        return HStack(spacing: 0) {
            Spacer(minLength: 0)
            ForEach(trailDays, id: \.self) { day in
                let isToday = viewModel.isToday(day)
                VStack(spacing: 2) {
                    Text(weekdayShortLabel(day))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(isToday ? 0.85 : 0.5))
                        .tracking(0.6)
                    Text(dayNumberLabel(day))
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(
                            isToday
                            ? Color(red: 0.36, green: 0.72, blue: 1.0)
                            : .white.opacity(0.85)
                        )
                }
                .frame(width: dayColumnWidth)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private func weekdayShortLabel(_ day: Date) -> String {
        day.formatted(.dateTime.weekday(.abbreviated)).uppercased()
    }

    private func dayNumberLabel(_ day: Date) -> String {
        day.formatted(.dateTime.day())
    }

    private func habitStreakLength(for habit: UHHabit) -> Int {
        var cursor = Date().uhDayStart
        if !viewModel.didComplete(habit, on: cursor) {
            if let prev = Calendar.current.date(byAdding: .day, value: -1, to: cursor)?.uhDayStart {
                cursor = prev
            }
        }
        return viewModel.streakLength(for: habit, endingOn: cursor)
    }

    private func streakLabel(for habit: UHHabit, streak: Int, days: [Date]) -> String {
        let allHit = !days.isEmpty && days.allSatisfy { viewModel.didComplete(habit, on: $0) }
        if allHit { return "Perfect Week! 🔥" }
        if streak <= 0 { return "Start today" }
        if streak == 1 { return "1 day streak" }
        return "\(streak) day streak"
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 34))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), Color.cyan.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("No habits yet")
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
            Text("Tap + to add your first habit.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                )
        )
    }

    private var habitsBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.09, blue: 0.14),
                    Color(red: 0.10, green: 0.13, blue: 0.19),
                    Color(red: 0.08, green: 0.10, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.cyan.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .offset(x: 155, y: -270)

            Circle()
                .fill(Color.blue.opacity(0.13))
                .frame(width: 210, height: 210)
                .blur(radius: 50)
                .offset(x: -160, y: 280)
        }
    }

    private func weeklyProgressColor(_ progress: Double) -> Color {
        switch progress {
        case 0.85...:
            return Color(red: 0.23, green: 0.92, blue: 0.58)
        case 0.65..<0.85:
            return Color(red: 0.36, green: 0.80, blue: 1.0)
        case 0.45..<0.65:
            return Color(red: 1.0, green: 0.77, blue: 0.33)
        default:
            return Color(red: 1.0, green: 0.44, blue: 0.42)
        }
    }

    private func rowOffset(for habitID: UUID) -> CGFloat {
        let base = swipedHabitID == habitID ? -swipeDeleteWidth : 0
        let drag = draggingHabitID == habitID ? draggingOffset : 0
        return min(0, max(-swipeDeleteWidth, base + drag))
    }

    private func swipeGesture(for habit: UHHabit) -> some Gesture {
        DragGesture(minimumDistance: 18)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) + 8 else { return }

                if draggingHabitID != habit.id {
                    draggingHabitID = habit.id
                    if swipedHabitID != habit.id {
                        swipedHabitID = nil
                    }
                }

                if swipedHabitID == habit.id {
                    draggingOffset = min(swipeDeleteWidth, max(-swipeDeleteWidth, value.translation.width))
                } else {
                    draggingOffset = min(0, max(-swipeDeleteWidth, value.translation.width))
                }
            }
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) + 8 else {
                    draggingHabitID = nil
                    draggingOffset = 0
                    return
                }

                let finalOffset = rowOffset(for: habit.id)
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    swipedHabitID = finalOffset < (-swipeDeleteWidth * 0.42) ? habit.id : nil
                    draggingHabitID = nil
                    draggingOffset = 0
                }
            }
    }

    private func closeSwipeState() {
        swipedHabitID = nil
        draggingHabitID = nil
        draggingOffset = 0
    }
}

private struct HeatCell: View {
    let intensity: Double
    let isToday: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(HabitsBoardView.heatmapColor(intensity: intensity))
            .frame(width: 12, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .stroke(isToday ? Color.white.opacity(0.85) : Color.clear, lineWidth: 1.1)
            )
    }
}

private struct HabitDayDot: View {
    let completed: Bool
    let tint: Color
    let isToday: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    completed
                    ? LinearGradient(
                        colors: [tint.opacity(0.95), tint.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(
                            completed
                            ? Color.white.opacity(0.18)
                            : (isToday ? tint.opacity(0.85) : Color.white.opacity(0.16)),
                            lineWidth: isToday && !completed ? 1.3 : 1
                        )
                )
                .shadow(color: completed ? tint.opacity(0.35) : .clear, radius: 6, x: 0, y: 3)

            if completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.22), radius: 0.5, x: 0, y: 0.5)
            }
        }
        .frame(width: 24, height: 24)
    }
}

private struct HeroMetricChip: View {
    let icon: String
    let tint: Color
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.20))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(tint)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.64))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.09), lineWidth: 1)
                )
        )
    }
}

private struct HabitRadialProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let tint: Color
    let label: String
    let subtitle: String?
    var showGlow: Bool = true
    var animated: Bool = true

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            if showGlow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tint.opacity(0.20), Color.clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 50
                        )
                    )
            }
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.35), tint.opacity(0.8), tint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(animated ? .spring(response: 0.45, dampingFraction: 0.84) : nil, value: clampedProgress)

            VStack(spacing: subtitle == nil ? 0 : 1) {
                Text(label)
                    .font(.system(size: subtitle == nil ? 9 : 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.72))
                }
            }
        }
    }
}

private struct HabitMonthDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: HabitsBoardViewModel
    let habit: UHHabit

    @State private var pendingEditDay: Date?

    private var color: Color {
        viewModel.color(for: habit)
    }

    private var weekdayLabels: [String] {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.09, blue: 0.13),
                        Color(red: 0.10, green: 0.12, blue: 0.17),
                        Color(red: 0.07, green: 0.09, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(color.opacity(0.20))
                    .frame(width: 240, height: 240)
                    .blur(radius: 55)
                    .offset(x: 150, y: -290)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        detailHero
                        monthHeader
                        monthWeekHeader
                        monthGrid
                        streakSection
                    }
                    .padding(14)
                }
            }
            .navigationTitle(habit.title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                            viewModel.toggleToday(for: habit, context: modelContext)
                        }
                    } label: {
                        Text(viewModel.didComplete(habit, on: Date()) ? "Undo Today" : "Mark Today")
                    }
                }
            }
            .toolbarBackground(Color.black.opacity(0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                viewModel.refresh(context: modelContext)
            }
        }
    }

    private var detailHero: some View {
        let month = viewModel.detailMonth
        let completedCount = viewModel.completionCount(in: month, for: habit)
        let daysInMonth = viewModel.daysInMonth(for: month)
        let progress = daysInMonth > 0 ? Double(completedCount) / Double(daysInMonth) : 0
        let markedToday = viewModel.didComplete(habit, on: Date())

        return HStack(spacing: 14) {
            HabitRadialProgressView(
                progress: progress,
                lineWidth: 9,
                tint: color,
                label: "\(completedCount)/\(daysInMonth)",
                subtitle: "DAYS"
            )
            .frame(width: 86, height: 86)

            VStack(alignment: .leading, spacing: 7) {
                Text("Monthly Score")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)

                Text("\(completedCount) / \(daysInMonth) days completed")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.86))

                Text(markedToday ? "Today's check-in done" : "Today's check-in pending")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(markedToday ? color : .white.opacity(0.70))
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(color.opacity(0.36), lineWidth: 1)
                )
        )
    }

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.24)) {
                    viewModel.shiftDetailMonth(by: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(viewModel.monthTitle())
                .font(.headline.weight(.bold))
                .foregroundColor(.white)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.24)) {
                    viewModel.shiftDetailMonth(by: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var monthWeekHeader: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(weekdayLabels, id: \.self) { item in
                Text(item)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.68))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        let days = viewModel.monthGrid()
        let today = Date().uhDayStart
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    let completed = viewModel.didComplete(habit, on: day)
                    let streak = completed ? viewModel.streakLength(for: habit, endingOn: day) : 0
                    let isFuture = day.uhDayStart > today
                    HabitMonthDayCell(
                        day: day,
                        completed: completed,
                        streakLength: streak,
                        isToday: viewModel.isToday(day),
                        isFuture: isFuture,
                        tint: color
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isFuture else { return }
                        HapticService.tap()
                        pendingEditDay = day
                    }
                } else {
                    Color.clear
                        .frame(height: 36)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .confirmationDialog(
            pendingDialogTitle,
            isPresented: Binding(
                get: { pendingEditDay != nil },
                set: { if !$0 { pendingEditDay = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let day = pendingEditDay {
                let completed = viewModel.didComplete(habit, on: day)
                Button(completed ? "Mark as Not Done" : "Mark as Completed",
                       role: completed ? .destructive : nil) {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        viewModel.setCompletion(!completed, for: habit, on: day, context: modelContext)
                    }
                    pendingEditDay = nil
                }
                Button("Cancel", role: .cancel) { pendingEditDay = nil }
            }
        }
    }

    private var pendingDialogTitle: String {
        guard let day = pendingEditDay else { return "" }
        let completed = viewModel.didComplete(habit, on: day)
        let dayStr = day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        return completed
            ? "\(dayStr) is marked done. Remove it?"
            : "Mark \(habit.title) as completed on \(dayStr)?"
    }

    private var streakSection: some View {
        let streaks = viewModel.streaks(for: habit)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Best Streaks")
                .font(.title3.weight(.bold))
                .foregroundColor(color)

            if streaks.isEmpty {
                Text("No streaks yet")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 10) {
                    ForEach(streaks) { streak in
                        HabitStreakRow(
                            streak: streak,
                            maxLength: viewModel.maxStreakLength(for: habit),
                            tint: color
                        )
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.13), lineWidth: 1)
                )
        )
    }
}

private struct HabitMonthDayCell: View {
    let day: Date
    let completed: Bool
    let streakLength: Int
    let isToday: Bool
    let isFuture: Bool
    let tint: Color

    /// 0.0 = first day of a streak (darkest), 1.0 = 7+ days in a row (lightest).
    private var intensity: Double {
        guard streakLength > 0 else { return 0 }
        return min(Double(streakLength - 1) / 6.0, 1.0)
    }

    private var fillGradient: LinearGradient {
        if completed {
            // Darker at streak start, lighter as the streak grows.
            let lowOpacity = 0.38 + 0.52 * intensity   // 0.38 → 0.90
            let highOpacity = 0.28 + 0.52 * intensity  // 0.28 → 0.80
            return LinearGradient(
                colors: [tint.opacity(lowOpacity), tint.opacity(highOpacity)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var textColor: Color {
        if !completed { return .white.opacity(isFuture ? 0.35 : 0.85) }
        // Lighter fills → darker text for contrast; darker fills → white text.
        return intensity > 0.55 ? .black.opacity(0.85) : .white.opacity(0.95)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(day.formatted(.dateTime.day()))
                .font(.caption.weight(.semibold))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(fillGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(completed ? 0.10 * intensity : 0))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isToday ? Color.white.opacity(0.86) : Color.clear, lineWidth: 1.4)
                        )
                )
                .opacity(isFuture ? 0.55 : 1)

            if completed && streakLength >= 2 {
                Text("\(streakLength)")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(textColor.opacity(0.85))
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(
                        Capsule().fill(Color.black.opacity(intensity > 0.55 ? 0.10 : 0.28))
                    )
                    .padding(3)
            }
        }
        .shadow(color: completed ? tint.opacity(0.12 + 0.10 * intensity) : .clear, radius: 6, x: 0, y: 4)
    }
}

private struct HabitStreakRow: View {
    let streak: HabitStreakRange
    let maxLength: Int
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(streak.start.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.72))
                Spacer()
                Text(streak.end.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.72))
            }

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.09))
                    .frame(height: 24)

                GeometryReader { proxy in
                    let width = max((CGFloat(streak.length) / CGFloat(max(maxLength, 1))) * proxy.size.width, 24)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.6), tint.opacity(0.88)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width, height: 24)
                }

                HStack {
                    Text("\(streak.length) days")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.black.opacity(0.78))
                        .padding(.leading, 8)
                    Spacer()
                }
            }
            .frame(height: 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

enum HabitEditorMode {
    case create
    case edit(initialTitle: String, initialIconID: String, initialHex: String)

    var navigationTitle: String {
        switch self {
        case .create: return "Create Habit"
        case .edit: return "Edit Habit"
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .create: return "Save"
        case .edit: return "Update"
        }
    }
}

struct HabitEditorSheet: View {
    let mode: HabitEditorMode
    let onSave: (_ title: String, _ iconID: String, _ colorHex: String) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool
    @State private var title: String = ""
    @State private var selectedIconID: String = HabitIconCatalog.fallback.id
    @State private var selectedHex: String = HabitSwatchCatalog.fallback.hex

    private let iconColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)
    private let swatchColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    private var selectedColor: Color {
        HabitSwatchCatalog.color(for: selectedHex)
    }

    private var selectedIcon: HabitIcon {
        HabitIconCatalog.icon(for: selectedIconID)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.07, green: 0.09, blue: 0.14),
                        Color(red: 0.11, green: 0.13, blue: 0.20),
                        Color(red: 0.08, green: 0.10, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(selectedColor.opacity(0.22))
                    .frame(width: 200, height: 200)
                    .blur(radius: 52)
                    .offset(x: 140, y: -240)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        previewTile
                        titleField
                        iconPickerSection
                        colorPickerSection
                        Spacer(minLength: 12)
                        saveRow
                    }
                    .padding(16)
                }
            }
            .navigationTitle(mode.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white.opacity(0.86))
                }
            }
            .toolbarBackground(Color.black.opacity(0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                configureInitialState()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if case .create = mode {
                        isTitleFocused = true
                    }
                }
            }
        }
    }

    private var previewTile: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [selectedColor.opacity(0.46), selectedColor.opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selectedColor.opacity(0.55), lineWidth: 1)
                    )
                Image(systemName: selectedIcon.systemName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(selectedColor)
            }
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 3) {
                Text(trimmedTitle.isEmpty ? "Your habit" : trimmedTitle)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(selectedIcon.label)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.64))
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.caption.weight(.bold))
                .foregroundColor(.white.opacity(0.66))
                .tracking(0.6)

            TextField(
                "",
                text: $title,
                prompt: Text("Habit title")
                    .foregroundColor(.white.opacity(0.48))
            )
            .focused($isTitleFocused)
            .textInputAutocapitalization(.words)
            .foregroundColor(.white)
            .tint(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.70))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
            )
        }
    }

    private var iconPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Icon")
                .font(.caption.weight(.bold))
                .foregroundColor(.white.opacity(0.66))
                .tracking(0.6)

            LazyVGrid(columns: iconColumns, spacing: 10) {
                ForEach(HabitIconCatalog.all) { icon in
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) {
                            selectedIconID = icon.id
                        }
                        HapticService.tap()
                    } label: {
                        let isSelected = icon.id == selectedIconID
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    isSelected
                                    ? LinearGradient(
                                        colors: [selectedColor.opacity(0.40), selectedColor.opacity(0.18)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            isSelected ? selectedColor.opacity(0.85) : Color.white.opacity(0.10),
                                            lineWidth: isSelected ? 1.4 : 1
                                        )
                                )
                            Image(systemName: icon.systemName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(isSelected ? selectedColor : .white.opacity(0.82))
                        }
                        .frame(height: 48)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color")
                .font(.caption.weight(.bold))
                .foregroundColor(.white.opacity(0.66))
                .tracking(0.6)

            LazyVGrid(columns: swatchColumns, spacing: 10) {
                ForEach(HabitSwatchCatalog.all) { swatch in
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) {
                            selectedHex = swatch.hex
                        }
                        HapticService.tap()
                    } label: {
                        let isSelected = swatch.hex.lowercased() == selectedHex.lowercased()
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [swatch.color, swatch.color.opacity(0.70)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(isSelected ? 0.95 : 0.12), lineWidth: isSelected ? 2 : 1)
                                )
                                .shadow(color: isSelected ? swatch.color.opacity(0.55) : .clear, radius: 8, x: 0, y: 4)
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var saveRow: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.86))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                    )
            }
            .buttonStyle(.plain)

            Button {
                guard !trimmedTitle.isEmpty else { return }
                onSave(trimmedTitle, selectedIconID, selectedHex)
            } label: {
                Text(mode.primaryButtonTitle)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.black.opacity(0.86))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [selectedColor, selectedColor.opacity(0.72)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .buttonStyle(.plain)
            .disabled(trimmedTitle.isEmpty)
            .opacity(trimmedTitle.isEmpty ? 0.55 : 1)
        }
    }

    private func configureInitialState() {
        switch mode {
        case .create:
            if title.isEmpty {
                title = ""
                selectedIconID = HabitIconCatalog.fallback.id
                selectedHex = HabitSwatchCatalog.fallback.hex
            }
        case let .edit(initialTitle, initialIconID, initialHex):
            if title.isEmpty {
                title = initialTitle
                selectedIconID = initialIconID
                selectedHex = initialHex
            }
        }
    }
}
