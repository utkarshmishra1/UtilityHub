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
    @State private var newHabitTitle = ""
    @State private var didAnimateIn = false
    @State private var swipedHabitID: UUID?
    @State private var draggingHabitID: UUID?
    @State private var draggingOffset: CGFloat = 0

    private let habitColumnWidth: CGFloat = 108
    private let dayCellSize: CGFloat = 30
    private let daySpacing: CGFloat = 6
    private let swipeDeleteWidth: CGFloat = 86

    var body: some View {
        ZStack {
            habitsBackdrop

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    overviewCard
                    weekHeader

                    if viewModel.habits.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 10) {
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
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Habits")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    newHabitTitle = ""
                    showAddHabitSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                }
                .foregroundColor(.white)
            }
        }
        .toolbarBackground(Color.black.opacity(0.92), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.visible, for: .navigationBar)
        .task {
            viewModel.refresh(context: modelContext)
            withAnimation(.spring(response: 0.44, dampingFraction: 0.84)) {
                didAnimateIn = true
            }
        }
        .sheet(isPresented: $showAddHabitSheet, onDismiss: {
            newHabitTitle = ""
        }) {
            HabitCreateSheet(title: $newHabitTitle) {
                if viewModel.addHabit(title: newHabitTitle, context: modelContext) {
                    newHabitTitle = ""
                    showAddHabitSheet = false
                }
            }
            .presentationDetents([.fraction(0.32)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $viewModel.selectedHabit) { habit in
            HabitMonthDetailView(viewModel: viewModel, habit: habit)
        }
        .onAppear {
            if newHabitTitle.isEmpty == false {
                newHabitTitle = ""
            }
        }
    }

    private var overviewCard: some View {
        let todayDone = viewModel.habits.filter { viewModel.didComplete($0, on: Date()) }.count
        let total = max(viewModel.habits.count, 1)
        let todayProgress = Double(todayDone) / Double(total)
        let weeklyCompletion = viewModel.overallWeekCompletion()
        let weeklyProgress = viewModel.overallWeekProgress()
        let weeklyDaysLabel = weeklyCompletion.total > 0
            ? "\(weeklyCompletion.completed)/\(weeklyCompletion.total)"
            : "0"

        return HStack(spacing: 14) {
            HabitRadialProgressView(
                progress: weeklyProgress,
                lineWidth: 10,
                tint: weeklyProgressColor(weeklyProgress),
                label: weeklyDaysLabel,
                subtitle: "DAYS"
            )
            .frame(width: 82, height: 82)

            VStack(alignment: .leading, spacing: 8) {
                Text("Weekly Momentum")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)

                Text("\(todayDone)/\(viewModel.habits.count) done today")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.88))

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.14))
                            .frame(height: 8)

                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [weeklyProgressColor(todayProgress).opacity(0.72), weeklyProgressColor(todayProgress)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: proxy.size.width * todayProgress, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.24), radius: 12, x: 0, y: 8)
    }

    private var weekHeader: some View {
        let weekDates = viewModel.weekDates

        return HStack(spacing: 8) {
            Text("Habit")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.72))
                .frame(width: habitColumnWidth, alignment: .leading)

            HStack(spacing: daySpacing) {
                ForEach(weekDates, id: \.self) { day in
                    VStack(spacing: 2) {
                        Text(day.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.66))
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(viewModel.isToday(day) ? .cyan : .white.opacity(0.82))
                    }
                    .frame(width: dayCellSize)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func habitRow(_ habit: UHHabit) -> some View {
        let color = viewModel.color(for: habit)
        let weeklyProgress = viewModel.weeklyProgress(for: habit)
        let completedDays = viewModel.weeklyCompletedDays(for: habit)
        let weekDates = viewModel.weekDates

        let rowContent = HStack(spacing: 8) {
            HStack(spacing: 8) {
                HabitRadialProgressView(
                    progress: weeklyProgress,
                    lineWidth: 3.4,
                    tint: color,
                    label: "\(completedDays)/\(weekDates.count)",
                    subtitle: nil,
                    showGlow: false,
                    animated: false
                )
                .frame(width: 24, height: 24)

                Text(habit.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.95))
                    .lineLimit(1)
            }
            .frame(width: habitColumnWidth, alignment: .leading)

            HStack(spacing: daySpacing) {
                ForEach(weekDates, id: \.self) { day in
                    let completed = viewModel.didComplete(habit, on: day)
                    if viewModel.isToday(day) {
                        Button {
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                                viewModel.toggleToday(for: habit, context: modelContext)
                            }
                        } label: {
                            HabitWeekMarkCell(
                                completed: completed,
                                isToday: true,
                                tint: color,
                                size: dayCellSize
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        HabitWeekMarkCell(
                            completed: completed,
                            isToday: false,
                            tint: color,
                            size: dayCellSize
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.12),
                            Color.white.opacity(0.07)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(color.opacity(0.30), lineWidth: 0.9)
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

        return ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.red.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
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
                .frame(width: swipeDeleteWidth - 6, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
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

private struct HabitWeekMarkCell: View {
    let completed: Bool
    let isToday: Bool
    let tint: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(completed ? tint.opacity(0.34) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            isToday ? tint.opacity(0.95) : Color.white.opacity(0.09),
                            lineWidth: isToday ? 1.3 : 1
                        )
                )

            Image(systemName: completed ? "checkmark" : "minus")
                .font(.system(size: max(size * 0.34, 9), weight: .bold))
                .foregroundColor(completed ? tint : .white.opacity(0.35))
        }
        .frame(width: size, height: size)
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
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    let completed = viewModel.didComplete(habit, on: day)
                    HabitMonthDayCell(
                        day: day,
                        completed: completed,
                        isToday: viewModel.isToday(day),
                        tint: color
                    )
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
    let isToday: Bool
    let tint: Color

    var body: some View {
        Text(day.formatted(.dateTime.day()))
            .font(.caption.weight(.semibold))
            .foregroundColor(completed ? .black.opacity(0.82) : .white.opacity(0.85))
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        completed
                        ? LinearGradient(
                            colors: [tint.opacity(0.90), tint.opacity(0.75)],
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
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isToday ? Color.white.opacity(0.86) : Color.clear, lineWidth: 1.4)
                    )
            )
            .shadow(color: completed ? tint.opacity(0.16) : .clear, radius: 6, x: 0, y: 4)
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

private struct HabitCreateSheet: View {
    @Binding var title: String
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.10, blue: 0.14),
                        Color(red: 0.11, green: 0.13, blue: 0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Create Habit")
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .foregroundColor(.white)
                            Text("Track it daily from your home dashboard.")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.72))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

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
                                .fill(Color.black.opacity(0.88))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                                )
                        )

                        HStack(spacing: 10) {
                            Button {
                                dismiss()
                            } label: {
                                Text("Cancel")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.86))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.white.opacity(0.12))
                                    )
                            }
                            .buttonStyle(.plain)

                            Button {
                                onSave()
                            } label: {
                                Text("Save")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.black.opacity(0.86))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.38, green: 0.86, blue: 1.0),
                                                        Color(red: 0.32, green: 0.95, blue: 0.64)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.56 : 1)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.14, green: 0.17, blue: 0.24),
                                        Color(red: 0.10, green: 0.12, blue: 0.18)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 12)
                    .padding(.horizontal, 16)

                    Spacer(minLength: 0)
                }
                .padding(.top, 12)

                Circle()
                    .fill(Color.cyan.opacity(0.18))
                    .frame(width: 170, height: 170)
                    .blur(radius: 42)
                    .offset(x: 140, y: -210)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.86))
                }
            }
            .toolbarBackground(Color.black.opacity(0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isTitleFocused = true
                }
            }
        }
    }
}
