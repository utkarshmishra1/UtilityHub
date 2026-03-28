//
//  ExpensesBoardView.swift
//  UtilityHub
//
//  Created by Codex on 04/03/26.
//

import SwiftData
import SwiftUI

struct ExpensesBoardView: View {
    private struct WalletRoute: Identifiable {
        let id: String
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ExpensesBoardViewModel()

    @State private var showAddWalletSheet = false
    @State private var showAddEntrySheet = false
    @State private var addEntryPreferredWallet: String?
    @State private var walletRoute: WalletRoute?
    @State private var didAnimateIn = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            expensesBackdrop

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    topBar
                    totalSummaryCard
                    walletsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 96)
            }

//            floatingAddButton
        }
        .navigationBarBackButtonHidden(true)
        .task {
            viewModel.refresh(context: modelContext)
            withAnimation(.spring(response: 0.52, dampingFraction: 0.86)) {
                didAnimateIn = true
            }
        }
        .refreshable {
            viewModel.refresh(context: modelContext)
        }
        .sheet(isPresented: $showAddWalletSheet, onDismiss: {
            viewModel.refresh(context: modelContext)
        }) {
            AddWalletSheet(palette: viewModel.accentPalette) { name, accentHex in
                viewModel.addWallet(name: name, accentHex: accentHex, context: modelContext)
            }
        }
        .sheet(isPresented: $showAddEntrySheet, onDismiss: {
            viewModel.refresh(context: modelContext)
        }) {
            AddExpenseEntrySheet(
                wallets: viewModel.wallets,
                preferredWallet: addEntryPreferredWallet
            ) { walletName, amountText, note, date, kind in
                viewModel.addEntry(
                    amountText: amountText,
                    kind: kind,
                    note: note,
                    walletName: walletName,
                    date: date,
                    context: modelContext
                )
            }
        }
        .sheet(item: $walletRoute) { route in
            WalletDetailSheet(
                viewModel: viewModel,
                walletName: route.id,
                onAddEntry: { preferredWallet in
                    openAddEntry(preferredWallet: preferredWallet)
                },
                onDeleteEntry: { entry in
                    viewModel.deleteEntry(entry, context: modelContext)
                },
                onDeleteWallet: { walletName, removeTransactions in
                    viewModel.deleteWallet(named: walletName, removeTransactions: removeTransactions, context: modelContext)
                }
            )
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
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Expenses")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                Text("Track wallets and cashflow")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.74))
            }

            Spacer()

            Button {
                if viewModel.wallets.isEmpty {
                    showAddWalletSheet = true
                } else {
                    openAddEntry(preferredWallet: nil)
                }
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundColor(Color(red: 0.09, green: 0.36, blue: 0.38))
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.white.opacity(0.92)))
            }
            .buttonStyle(.plain)
        }
    }

    private var totalSummaryCard: some View {
        let totalColor = viewModel.colorForAmount(viewModel.totalBalance)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "wallet.pass.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.white.opacity(0.16)))

                Text("Expenses Overview")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)

                Spacer()
            }

            HStack(spacing: 10) {
                ExpenseSummaryMetric(
                    title: "Total",
                    value: viewModel.formattedSignedCurrency(viewModel.totalBalance),
                    valueColor: totalColor,
                    emphasize: true
                )

                dividerLine

                ExpenseSummaryMetric(
                    title: "Last 30 days",
                    value: viewModel.formattedSignedCurrency(viewModel.totalLast30Days),
                    valueColor: viewModel.colorForAmount(viewModel.totalLast30Days),
                    emphasize: false
                )

                dividerLine

                ExpenseSummaryMetric(
                    title: "Last 7 days",
                    value: viewModel.formattedSignedCurrency(viewModel.totalLast7Days),
                    valueColor: viewModel.colorForAmount(viewModel.totalLast7Days),
                    emphasize: false
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.67, blue: 0.71),
                            Color(red: 0.06, green: 0.52, blue: 0.69),
                            Color(red: 0.16, green: 0.35, blue: 0.67)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 14, x: 0, y: 10)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.28))
            .frame(width: 1)
            .padding(.vertical, 6)
    }

    private var walletsSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Expenses")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(viewModel.wallets.count)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.12))
                    )
            }

            if viewModel.wallets.isEmpty {
                emptyWalletState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(viewModel.wallets.enumerated()), id: \.element.id) { index, wallet in
                        walletCard(wallet, index: index)
                    }
                }
            }

            addWalletCard
        }
    }

    private var emptyWalletState: some View {
        VStack(spacing: 10) {
            Image(systemName: "creditcard")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white.opacity(0.75))
            Text("No wallets yet")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.white)
            Text("Create your first wallet to start tracking expenses and income.")
                .font(.caption.weight(.medium))
                .foregroundColor(.white.opacity(0.72))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private func walletCard(_ wallet: ExpensesBoardViewModel.WalletSummary, index: Int) -> some View {
        let accent = Color(walletHex: wallet.accentHex)
        let totalColor = viewModel.colorForAmount(wallet.total)
        let progress = viewModel.momentumProgress(for: wallet)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                WalletMomentumBadge(progress: progress, tint: accent)
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text(wallet.name)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundColor(.white)

                    Text(viewModel.entrySummaryText(for: wallet))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.66))
                }

                Spacer()

                Button {
                    openAddEntry(preferredWallet: wallet.name)
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(accent))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            Text(viewModel.formattedSignedCurrency(wallet.total))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(totalColor)

            HStack(spacing: 18) {
                ExpenseWalletMetric(
                    title: "Last 30 days",
                    value: viewModel.formattedSignedCurrency(wallet.last30Days),
                    valueColor: viewModel.colorForAmount(wallet.last30Days)
                )
                ExpenseWalletMetric(
                    title: "Last 7 days",
                    value: viewModel.formattedSignedCurrency(wallet.last7Days),
                    valueColor: viewModel.colorForAmount(wallet.last7Days)
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.14),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(accent.opacity(0.55), lineWidth: 1)
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture {
            walletRoute = WalletRoute(id: wallet.name)
        }
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deleteWallet(named: wallet.name, removeTransactions: false, context: modelContext)
            } label: {
                Text("Delete Wallet")
            }

            Button(role: .destructive) {
                viewModel.deleteWallet(named: wallet.name, removeTransactions: true, context: modelContext)
            } label: {
                Text("Delete Wallet and Transactions")
            }
        }
        .offset(y: didAnimateIn ? 0 : 10)
        .opacity(didAnimateIn ? 1 : 0)
        .animation(
            .spring(response: 0.46, dampingFraction: 0.84)
                .delay(Double(index) * 0.03),
            value: didAnimateIn
        )
    }

    private var addWalletCard: some View {
        Button {
            showAddWalletSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                Text("Add Expenses")
                    .font(.headline.weight(.semibold))
                Spacer()
            }
            .foregroundColor(Color.white.opacity(0.88))
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                Color.white.opacity(0.45),
                                style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

//    private var floatingAddButton: some View {
//        Button {
//            if viewModel.wallets.isEmpty {
//                showAddWalletSheet = true
//            } else {
//                openAddEntry(preferredWallet: nil)
//            }
//        } label: {
//            Image(systemName: "plus")
//                .font(.system(size: 22, weight: .bold))
//                .foregroundColor(.white)
//                .frame(width: 60, height: 60)
//                .background(
//                    Circle()
//                        .fill(
//                            LinearGradient(
//                                colors: [
//                                    Color(red: 0.14, green: 0.86, blue: 0.76),
//                                    Color(red: 0.10, green: 0.62, blue: 0.72)
//                                ],
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//                )
//                .shadow(color: Color.black.opacity(0.28), radius: 20, x: 0, y: 10)
//        }
//        .buttonStyle(.plain)
//        .padding(.trailing, 20)
//        .padding(.bottom, 18)
//    }

    private var expensesBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.19),
                    Color(red: 0.06, green: 0.14, blue: 0.28),
                    Color(red: 0.08, green: 0.18, blue: 0.34)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.cyan.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 40)
                .offset(x: 130, y: -280)

            Circle()
                .fill(Color.green.opacity(0.13))
                .frame(width: 320, height: 320)
                .blur(radius: 50)
                .offset(x: -170, y: 360)
        }
    }

    private func openAddEntry(preferredWallet: String?) {
        guard !viewModel.wallets.isEmpty else {
            showAddWalletSheet = true
            return
        }

        addEntryPreferredWallet = preferredWallet ?? viewModel.wallets.first?.name
        showAddEntrySheet = true
    }
}

private struct ExpenseSummaryMetric: View {
    let title: String
    let value: String
    let valueColor: Color
    let emphasize: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.72))
            Text(value)
                .font(emphasize ? .system(.title3, design: .rounded).weight(.bold) : .subheadline.weight(.bold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ExpenseWalletMetric: View {
    let title: String
    let value: String
    let valueColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }
}

private struct WalletMomentumBadge: View {
    let progress: Double
    let tint: Color

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.2))

            Circle()
                .stroke(tint.opacity(0.25), lineWidth: 6)

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Image(systemName: "waveform.path.ecg")
                .font(.caption.weight(.bold))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

private struct AddWalletSheet: View {
    @Environment(\.dismiss) private var dismiss

    let palette: [String]
    let onSave: (String, String) -> Bool

    @State private var walletName = ""
    @State private var selectedHex: String
    @State private var showValidationError = false
    @FocusState private var isWalletNameFocused: Bool

    init(palette: [String], onSave: @escaping (String, String) -> Bool) {
        self.palette = palette
        self.onSave = onSave
        _selectedHex = State(initialValue: palette.first ?? "#14B8A6")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Create a wallet to group related transactions.")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)

                TextField("Wallet name", text: $walletName)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .focused($isWalletNameFocused)

                Text("Accent")
                    .font(.subheadline.weight(.semibold))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 40), spacing: 10)], spacing: 10) {
                    ForEach(palette, id: \.self) { hex in
                        let color = Color(walletHex: hex)
                        Button {
                            selectedHex = hex
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.9), lineWidth: selectedHex == hex ? 2 : 0)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.14), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if showValidationError {
                    Text("Enter a unique wallet name.")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.red)
                }

                Spacer(minLength: 0)
            }
            .padding(18)
            .navigationTitle("Add Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let success = onSave(walletName, selectedHex)
                        if success {
                            dismiss()
                        } else {
                            showValidationError = true
                        }
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    isWalletNameFocused = true
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct AddExpenseEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let wallets: [ExpensesBoardViewModel.WalletSummary]
    let onSave: (String, String, String, Date, ExpensesBoardViewModel.EntryKind) -> Bool

    @State private var selectedWalletName: String
    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var kind: ExpensesBoardViewModel.EntryKind = .expense
    @State private var showValidationError = false
    @FocusState private var isAmountFocused: Bool

    init(
        wallets: [ExpensesBoardViewModel.WalletSummary],
        preferredWallet: String?,
        onSave: @escaping (String, String, String, Date, ExpensesBoardViewModel.EntryKind) -> Bool
    ) {
        self.wallets = wallets
        self.onSave = onSave
        _selectedWalletName = State(initialValue: preferredWallet ?? wallets.first?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Type", selection: $kind) {
                    ForEach(ExpensesBoardViewModel.EntryKind.allCases) { entryKind in
                        Label(entryKind.rawValue, systemImage: entryKind.symbol)
                            .tag(entryKind)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Amount")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $amountText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .focused($isAmountFocused)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Wallet")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Picker("Wallet", selection: $selectedWalletName) {
                        ForEach(wallets) { wallet in
                            Text(wallet.name).tag(wallet.name)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Note")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    TextField("Optional", text: $note)
                        .textFieldStyle(.roundedBorder)
                }

                DatePicker("Date", selection: $date, displayedComponents: [.date])
                    .font(.subheadline.weight(.medium))

                if showValidationError {
                    Text("Enter valid amount and wallet.")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.red)
                }

                Spacer(minLength: 0)
            }
            .padding(18)
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let success = onSave(selectedWalletName, amountText, note, date, kind)
                        if success {
                            dismiss()
                        } else {
                            showValidationError = true
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(wallets.isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    isAmountFocused = true
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct WalletDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: ExpensesBoardViewModel
    let walletName: String
    let onAddEntry: (String) -> Void
    let onDeleteEntry: (UHExpense) -> Void
    let onDeleteWallet: (String, Bool) -> Void

    @State private var showDeleteDialog = false

    private var wallet: ExpensesBoardViewModel.WalletSummary? {
        viewModel.wallet(named: walletName)
    }

    private var entries: [UHExpense] {
        viewModel.transactions(for: walletName)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.09, blue: 0.2),
                        Color(red: 0.07, green: 0.14, blue: 0.27)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    if let wallet {
                        walletSummary(wallet)
                            .padding(.horizontal, 16)
                            .padding(.top, 10)

                        if entries.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(.white.opacity(0.7))
                                Text("No transactions yet")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.86))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(entries) { entry in
                                    transactionRow(entry)
                                        .listRowInsets(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
                                        .listRowBackground(Color.white.opacity(0.04))
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        let entry = entries[index]
                                        onDeleteEntry(entry)
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                        }
                    } else {
                        Text("Wallet not found")
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle(walletName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onAddEntry(walletName)
                            }
                        } label: {
                            Image(systemName: "plus")
                        }

                        Button {
                            showDeleteDialog = true
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .confirmationDialog("Delete Wallet", isPresented: $showDeleteDialog) {
                Button("Delete Wallet", role: .destructive) {
                    onDeleteWallet(walletName, false)
                    dismiss()
                }

                Button("Delete Wallet and Transactions", role: .destructive) {
                    onDeleteWallet(walletName, true)
                    dismiss()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose whether to keep or remove this wallet's transactions.")
            }
        }
        .presentationDetents([.large])
    }

    private func walletSummary(_ wallet: ExpensesBoardViewModel.WalletSummary) -> some View {
        let accent = Color(walletHex: wallet.accentHex)

        return HStack(spacing: 16) {
            WalletMomentumBadge(progress: viewModel.momentumProgress(for: wallet), tint: accent)
                .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.formattedSignedCurrency(wallet.total))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(viewModel.colorForAmount(wallet.total))

                Text(viewModel.entrySummaryText(for: wallet))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accent.opacity(0.6), lineWidth: 1)
                )
        )
    }

    private func transactionRow(_ entry: UHExpense) -> some View {
        let tone = viewModel.colorForAmount(entry.amount)
        let noteText = entry.note.isEmpty ? "No note" : entry.note

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(noteText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Spacer()

                Text(viewModel.formattedSignedCurrency(entry.amount))
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(tone)
            }

            Text(entry.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption.weight(.medium))
                .foregroundColor(.white.opacity(0.62))
        }
    }
}

private extension Color {
    init(walletHex: String) {
        let cleaned = walletHex
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
