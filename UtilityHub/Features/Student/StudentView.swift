//
//  StudentView.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import SwiftUI
import SwiftData

struct StudentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = StudentViewModel()
    @State private var showAddSubjectSheet = false
    @State private var showTargetSheet = false
    @State private var showTimeTableSheet = false
    @State private var editingSubject: UHAttendanceSubject?
    @State private var reportSubject: UHAttendanceSubject?
    @State private var subjectPendingReset: UHAttendanceSubject?
    @State private var subjectPendingDelete: UHAttendanceSubject?

    var body: some View {
        NavigationStack {
            ZStack {
                AttendanceBackdrop()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        summaryCard
                        subjectsSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Attendance Manager")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Add Subject", systemImage: "plus.circle") {
                            showAddSubjectSheet = true
                        }
                        Button("Set Attendance Criteria", systemImage: "slider.horizontal.3") {
                            showTargetSheet = true
                        }
                        Button("Open Time Table", systemImage: "calendar.badge.clock") {
                            showTimeTableSheet = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.mint, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .task {
                viewModel.refresh(context: modelContext)
            }
        }
        .sheet(isPresented: $showAddSubjectSheet) {
            AddSubjectSheet { name, attended, total in
                viewModel.addSubject(name: name, attended: attended, total: total, context: modelContext)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTargetSheet) {
            TargetCriteriaSheet(currentTarget: viewModel.targetPercentage()) { target in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.updateTarget(target, context: modelContext)
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTimeTableSheet) {
            TimeTableSheet(viewModel: viewModel)
        }
        .sheet(item: $editingSubject) { subject in
            EditSubjectSheet(subject: subject) { name, attended, total in
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    viewModel.updateSubject(subject, name: name, attended: attended, total: total, context: modelContext)
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $reportSubject) { subject in
            MonthlyReportSheet(viewModel: viewModel, subject: subject)
        }
        .alert(
            "Reset Attendance?",
            isPresented: Binding(
                get: { subjectPendingReset != nil },
                set: { if !$0 { subjectPendingReset = nil } }
            ),
            presenting: subjectPendingReset
        ) { subject in
            Button("Reset", role: .destructive) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    viewModel.resetSubject(subject, context: modelContext)
                }
                subjectPendingReset = nil
            }
            Button("Cancel", role: .cancel) {
                subjectPendingReset = nil
            }
        } message: { subject in
            Text("This clears all attendance logs for \(subject.name).")
        }
        .alert(
            "Delete Subject?",
            isPresented: Binding(
                get: { subjectPendingDelete != nil },
                set: { if !$0 { subjectPendingDelete = nil } }
            ),
            presenting: subjectPendingDelete
        ) { subject in
            Button("Delete", role: .destructive) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    viewModel.deleteSubject(subject, context: modelContext)
                }
                subjectPendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                subjectPendingDelete = nil
            }
        } message: { subject in
            Text("\(subject.name) and all its report data will be removed.")
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Overall Attendance")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(.white.opacity(0.86))

                    AttendanceRing(
                        progress: Double(viewModel.totalAttendancePercent()) / 100,
                        color: viewModel.overallProgressColor(),
                        label: viewModel.totalAttendancePercentText(),
                        lineWidth: 10
                    )
                    .frame(width: 122, height: 122)

                    HStack(spacing: 8) {
                        Text("Target \(viewModel.targetPercentage())%")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.88))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(viewModel.overallProgressColor().opacity(0.22))
                            )
                        Text(viewModel.summaryDateText())
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Subject Graphs")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(.white.opacity(0.86))
                        Spacer()
                        Text("\(viewModel.subjects.count)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.12))
                            )
                    }

                    if viewModel.subjects.isEmpty {
                        Text("No subjects yet")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white.opacity(0.72))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 14)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.subjects, id: \.id) { subject in
                                SubjectSummaryGraphRow(
                                    subjectName: subject.name,
                                    percentage: viewModel.percentage(for: subject),
                                    ringColor: viewModel.progressColor(for: subject),
                                    accentColor: Color(hex: subject.accentHex),
                                    statusColor: viewModel.progressColor(for: subject)
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                showAddSubjectSheet = true
            } label: {
                Text("ADD SUBJECT")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.41, green: 0.97, blue: 0.55), Color(red: 0.14, green: 0.84, blue: 0.42)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.24), radius: 16, x: 0, y: 8)
    }

    @ViewBuilder
    private var subjectsSection: some View {
        if viewModel.subjects.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "graduationcap.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.47, green: 0.80, blue: 1.0), .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("No subjects added yet")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                Text("Add your first subject to start attendance tracking.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Button("Add Subject") {
                    showAddSubjectSheet = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .padding(.top, 4)
            }
            .padding(22)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        } else {
            LazyVStack(spacing: 14) {
                ForEach(Array(viewModel.subjects.enumerated()), id: \.element.id) { index, subject in
                    AttendanceSubjectCard(
                        subject: subject,
                        percentage: viewModel.percentage(for: subject),
                        statusText: viewModel.statusText(for: subject),
                        ringColor: viewModel.progressColor(for: subject),
                        accentColor: Color(hex: subject.accentHex),
                        onPresent: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                                viewModel.markPresent(for: subject, context: modelContext)
                            }
                        },
                        onAbsent: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                                viewModel.markAbsent(for: subject, context: modelContext)
                            }
                        },
                        onMonthlyReport: {
                            reportSubject = subject
                        },
                        onEdit: {
                            editingSubject = subject
                        },
                        onReset: {
                            subjectPendingReset = subject
                        },
                        onDelete: {
                            subjectPendingDelete = subject
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.86).delay(Double(index) * 0.03),
                        value: viewModel.subjects.count
                    )
                }
            }
        }
    }
}

private struct AttendanceSubjectCard: View {
    let subject: UHAttendanceSubject
    let percentage: Int
    let statusText: String
    let ringColor: Color
    let accentColor: Color
    let onPresent: () -> Void
    let onAbsent: () -> Void
    let onMonthlyReport: () -> Void
    let onEdit: () -> Void
    let onReset: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(accentColor)
                    .frame(width: 4, height: 46)

                VStack(alignment: .leading, spacing: 5) {
                    Text(subject.name)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("Attendance \(subject.attendedClasses)/\(subject.totalClasses)")
                        .font(.system(.headline, design: .rounded).weight(.medium))
                        .foregroundColor(.white.opacity(0.85))
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 8)

                AttendanceRing(
                    progress: Double(percentage) / 100,
                    color: ringColor,
                    label: "\(percentage)%",
                    lineWidth: 8
                )
                .frame(width: 86, height: 86)
            }

            Text(statusText)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                AttendanceActionButton(
                    title: "Present",
                    symbol: "checkmark",
                    tint: Color(red: 0.20, green: 0.84, blue: 0.33),
                    action: onPresent
                )

                AttendanceActionButton(
                    title: "Absent",
                    symbol: "xmark",
                    tint: Color(red: 1.0, green: 0.34, blue: 0.39),
                    action: onAbsent
                )

                Spacer()

                Menu {
                    Button("Monthly Report", systemImage: "calendar") {
                        onMonthlyReport()
                    }
                    Button("Edit Attendance", systemImage: "pencil") {
                        onEdit()
                    }
                    Button("Reset Attendance", systemImage: "arrow.counterclockwise") {
                        onReset()
                    }
                    Button("Delete Subject", systemImage: "trash", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.78))
                        .frame(width: 34, height: 34)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.11), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.23), radius: 14, x: 0, y: 8)
    }
}

private struct AttendanceActionButton: View {
    let title: String
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.caption.bold())
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.gradient)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

private struct AttendanceRing: View {
    let progress: Double
    let color: Color
    let label: String
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.35), color],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: progress)

            Text(label)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(.white)
        }
    }
}

private struct SubjectSummaryGraphRow: View {
    let subjectName: String
    let percentage: Int
    let ringColor: Color
    let accentColor: Color
    let statusColor: Color

    var body: some View {
        HStack(spacing: 10) {
            SubjectGraphIcon(
                title: subjectName,
                progress: Double(percentage) / 100,
                color: ringColor,
                fillColor: accentColor
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(subjectName)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("\(percentage)% attendance")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(statusColor.opacity(0.95))
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(statusColor.opacity(0.28), lineWidth: 1)
                )
        )
    }
}

private struct SubjectGraphIcon: View {
    let title: String
    let progress: Double
    let color: Color
    let fillColor: Color

    private var initials: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "S" }
        return String(trimmed.prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 4)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: progress)
            Circle()
                .fill(fillColor.opacity(0.18))
                .padding(6)
            Text(initials)
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
        }
        .frame(width: 38, height: 38)
    }
}

private struct AddSubjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var attended = 0
    @State private var total = 0

    let onSave: (String, Int, Int) -> Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AttendanceBackdrop()

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Subject Name")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white.opacity(0.85))
                        TextField("e.g. Physics", text: $name)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .foregroundColor(.black)
                    }

                    VStack(spacing: 10) {
                        Stepper("Total Classes: \(total)", value: $total, in: 0...1000)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                        Stepper("Attended Classes: \(attended)", value: $attended, in: 0...max(total, 0))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )

                    Button {
                        if onSave(name, attended, total) {
                            dismiss()
                        }
                    } label: {
                        Text("Save Subject")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(red: 0.27, green: 0.95, blue: 0.52))
                            )
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

                    Spacer(minLength: 0)
                }
                .padding(18)
            }
            .navigationTitle("Add Subject")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: total) { _, newValue in
                attended = min(attended, newValue)
            }
        }
    }
}

private struct EditSubjectSheet: View {
    let subject: UHAttendanceSubject
    let onSave: (String, Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var attended: Int
    @State private var total: Int

    init(subject: UHAttendanceSubject, onSave: @escaping (String, Int, Int) -> Void) {
        self.subject = subject
        self.onSave = onSave
        _name = State(initialValue: subject.name)
        _attended = State(initialValue: subject.attendedClasses)
        _total = State(initialValue: subject.totalClasses)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AttendanceBackdrop()

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Subject Name")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white.opacity(0.85))
                        TextField("Subject", text: $name)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .foregroundColor(.black)
                    }

                    VStack(spacing: 10) {
                        Stepper("Total Classes: \(total)", value: $total, in: 0...1000)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                        Stepper("Attended Classes: \(attended)", value: $attended, in: 0...max(total, 0))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )

                    Button {
                        onSave(name, attended, total)
                        dismiss()
                    } label: {
                        Text("Save Changes")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(red: 0.31, green: 0.86, blue: 1.0))
                            )
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

                    Spacer(minLength: 0)
                }
                .padding(18)
            }
            .navigationTitle("Edit Attendance")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: total) { _, newValue in
                attended = min(attended, newValue)
            }
        }
    }
}

private struct TargetCriteriaSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sliderValue: Double

    let onSave: (Int) -> Void

    init(currentTarget: Int, onSave: @escaping (Int) -> Void) {
        _sliderValue = State(initialValue: Double(currentTarget))
        self.onSave = onSave
    }

    private var roundedTarget: Int {
        Int(sliderValue.rounded())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AttendanceBackdrop()

                VStack(spacing: 18) {
                    Text("Set Attendance Criteria")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundColor(.white)

                    AttendanceRing(
                        progress: Double(roundedTarget) / 100,
                        color: .teal,
                        label: "\(roundedTarget)%",
                        lineWidth: 10
                    )
                    .frame(width: 150, height: 150)
                    .padding(.vertical, 4)

                    Slider(value: $sliderValue, in: 50...95, step: 1)
                        .tint(.teal)

                    HStack {
                        Text("50%")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("95%")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Button {
                        onSave(roundedTarget)
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(red: 0.28, green: 0.92, blue: 0.55))
                            )
                    }
                    .buttonStyle(PressScaleButtonStyle())

                    Spacer(minLength: 0)
                }
                .padding(18)
            }
            .navigationTitle("Attendance Target")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct TimeTableSheet: View {
    @ObservedObject var viewModel: StudentViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showAddClassSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                AttendanceBackdrop()

                VStack(spacing: 16) {
                    weekdayChips

                    let classes = viewModel.classes(for: viewModel.selectedWeekday)
                    if classes.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.8))
                            Text("No classes for \(viewModel.weekdayName(viewModel.selectedWeekday))")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.white)
                            Text("Tap + to add your class schedule.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(22)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.07))
                        )
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(classes) { item in
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(viewModel.startTimeText(for: item)) - \(viewModel.endTimeText(for: item))")
                                                .font(.headline.weight(.semibold))
                                                .foregroundColor(.white)
                                            Text(item.subject)
                                                .font(.title3.weight(.bold))
                                                .foregroundColor(.white)
                                            Text("Location: \(item.location.isEmpty ? "-" : item.location)")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.75))
                                        }

                                        Spacer()

                                        Button(role: .destructive) {
                                            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                                                viewModel.deleteSchedule(item, context: modelContext)
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .frame(width: 34, height: 34)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .fill(Color.red.opacity(0.85))
                                                )
                                        }
                                        .buttonStyle(PressScaleButtonStyle())
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(Color.white.opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)
            }
            .navigationTitle("Time Table")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddClassSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddClassSheet) {
                AddClassSheet(defaultWeekday: viewModel.selectedWeekday) {
                    weekday,
                    startHour,
                    startMinute,
                    endHour,
                    endMinute,
                    subject,
                    location in
                    viewModel.addSchedule(
                        weekday: weekday,
                        startHour: startHour,
                        startMinute: startMinute,
                        endHour: endHour,
                        endMinute: endMinute,
                        subject: subject,
                        location: location,
                        context: modelContext
                    )
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .task {
                viewModel.refresh(context: modelContext)
            }
        }
    }

    private var weekdayChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(1...7, id: \.self) { weekday in
                    Button {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.85)) {
                            viewModel.selectedWeekday = weekday
                        }
                    } label: {
                        Text(String(viewModel.weekdayName(weekday).prefix(3)))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(viewModel.selectedWeekday == weekday ? .black : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        viewModel.selectedWeekday == weekday
                                        ? Color(red: 0.39, green: 0.84, blue: 1.0)
                                        : Color.white.opacity(0.1)
                                    )
                            )
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

private struct AddClassSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var weekday: Int
    @State private var subject = ""
    @State private var location = ""
    @State private var startTime: Date = Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: Date()) ?? Date()
    @State private var endTime: Date = Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date()) ?? Date()

    let onSave: (Int, Int, Int, Int, Int, String, String) -> Void

    init(
        defaultWeekday: Int,
        onSave: @escaping (Int, Int, Int, Int, Int, String, String) -> Void
    ) {
        _weekday = State(initialValue: defaultWeekday)
        self.onSave = onSave
    }

    private var canSave: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && endTime > startTime
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AttendanceBackdrop()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        Group {
                            TextField("Subject", text: $subject)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.1))
                                )
                                .foregroundColor(.black)

                            TextField("Location", text: $location)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.1))
                                )
                                .foregroundColor(.black)
                        }

                        Picker("Weekday", selection: $weekday) {
                            ForEach(1...7, id: \.self) { value in
                                Text(Calendar.current.weekdaySymbols[max(min(value - 1, 6), 0)]).tag(value)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start Time")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.85))
                            DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .datePickerStyle(.wheel)
                                .frame(maxHeight: 130)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("End Time")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.85))
                            DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .datePickerStyle(.wheel)
                                .frame(maxHeight: 130)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )

                        Button {
                            let startComponents = Calendar.current.dateComponents([.hour, .minute], from: startTime)
                            let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endTime)
                            onSave(
                                weekday,
                                startComponents.hour ?? 0,
                                startComponents.minute ?? 0,
                                endComponents.hour ?? 0,
                                endComponents.minute ?? 0,
                                subject,
                                location
                            )
                            dismiss()
                        } label: {
                            Text("Save Class")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(red: 0.28, green: 0.91, blue: 0.55))
                                )
                        }
                        .buttonStyle(PressScaleButtonStyle())
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.5)
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Add Class")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct MonthlyReportSheet: View {
    @ObservedObject var viewModel: StudentViewModel
    let subject: UHAttendanceSubject

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private var reportCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    private var weekLabels: [String] {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    }

    private var monthTitle: String {
        viewModel.reportMonth.formatted(.dateTime.month(.wide).year())
    }

    private var daySummaryMap: [Date: AttendanceDaySummary] {
        viewModel.monthSummaryMap(for: viewModel.reportMonth)
    }

    private var selectedSummary: AttendanceDaySummary {
        viewModel.summary(for: viewModel.reportSelectedDate)
    }

    private var monthGridDays: [Date?] {
        guard let interval = reportCalendar.dateInterval(of: .month, for: viewModel.reportMonth),
              let daysRange = reportCalendar.range(of: .day, in: .month, for: viewModel.reportMonth) else {
            return []
        }

        let firstDay = interval.start
        let leadingPadding = (reportCalendar.component(.weekday, from: firstDay) - reportCalendar.firstWeekday + 7) % 7

        var days = Array(repeating: Optional<Date>.none, count: leadingPadding)
        for day in daysRange {
            if let date = reportCalendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AttendanceBackdrop()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        monthHeader
                        weekdayHeader
                        monthGrid
                        selectedDaySummaryCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("\(subject.name) Report")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                viewModel.openReport(for: subject.id, context: modelContext)
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.shiftReportMonth(by: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                    )
            }
            .buttonStyle(PressScaleButtonStyle())

            Spacer()

            Text(monthTitle)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.shiftReportMonth(by: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                    )
            }
            .buttonStyle(PressScaleButtonStyle())
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(weekLabels, id: \.self) { day in
                Text(day)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.72))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 10) {
            ForEach(Array(monthGridDays.enumerated()), id: \.offset) { _, day in
                if let date = day {
                    let daySummary = daySummaryMap[date.uhDayStart] ?? AttendanceDaySummary()
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                            viewModel.selectReportDate(date)
                        }
                    } label: {
                        MonthlyReportDayCell(
                            date: date,
                            summary: daySummary,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.reportSelectedDate),
                            isToday: Calendar.current.isDateInToday(date)
                        )
                    }
                    .buttonStyle(PressScaleButtonStyle())
                } else {
                    Color.clear
                        .frame(height: 48)
                }
            }
        }
    }

    private var selectedDaySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Date: \(viewModel.reportSelectedDate.formatted(date: .numeric, time: .omitted))")
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)

            HStack(spacing: 20) {
                HStack(spacing: 8) {
                    Circle().fill(Color.green).frame(width: 9, height: 9)
                    Text("Present: \(selectedSummary.present)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.9))
                }

                HStack(spacing: 8) {
                    Circle().fill(Color.red).frame(width: 9, height: 9)
                    Text("Absent: \(selectedSummary.absent)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            HStack(spacing: 20) {
                HStack(spacing: 8) {
                    Circle().fill(Color.blue).frame(width: 9, height: 9)
                    Text("Selected Day")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.78))
                }

                HStack(spacing: 8) {
                    Circle().stroke(Color.white.opacity(0.82), lineWidth: 1.5)
                        .frame(width: 9, height: 9)
                    Text("Current Day")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.78))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

private struct MonthlyReportDayCell: View {
    let date: Date
    let summary: AttendanceDaySummary
    let isSelected: Bool
    let isToday: Bool

    var body: some View {
        VStack(spacing: 5) {
            Text(date.formatted(.dateTime.day()))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)

            HStack(spacing: 3) {
                if summary.present > 0 {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }
                if summary.absent > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.blue.opacity(0.78) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isToday ? Color.white.opacity(0.86) : Color.clear, lineWidth: 1.5)
                )
        )
    }
}

private struct AttendanceBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.16),
                    Color(red: 0.07, green: 0.10, blue: 0.22),
                    Color(red: 0.03, green: 0.04, blue: 0.11)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.cyan.opacity(0.15))
                .blur(radius: 60)
                .frame(width: 260, height: 260)
                .offset(x: 120, y: -260)

            Circle()
                .fill(Color.green.opacity(0.12))
                .blur(radius: 70)
                .frame(width: 280, height: 280)
                .offset(x: -150, y: 300)
        }
    }
}

private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            .uppercased()
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
