//
//  ExpensesBoardViewModel.swift
//  UtilityHub
//
//  Created by Codex on 04/03/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
final class ExpensesBoardViewModel: ObservableObject {
    enum EntryKind: String, CaseIterable, Identifiable {
        case expense = "Expense"
        case income = "Income"

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .expense:
                return "arrow.down.circle.fill"
            case .income:
                return "arrow.up.circle.fill"
            }
        }
    }

    struct WalletSummary: Identifiable, Hashable {
        let id: UUID
        let name: String
        let accentHex: String
        let total: Double
        let last30Days: Double
        let last7Days: Double
        let transactionCount: Int
    }

    private struct WalletDescriptor: Codable, Identifiable, Hashable {
        let id: UUID
        var name: String
        var accentHex: String
        var createdAt: Date
    }

    @Published private(set) var wallets: [WalletSummary] = []
    @Published private(set) var allExpenses: [UHExpense] = []
    @Published private(set) var totalBalance: Double = 0
    @Published private(set) var totalLast30Days: Double = 0
    @Published private(set) var totalLast7Days: Double = 0

    let accentPalette: [String] = [
        "#14B8A6",
        "#22C55E",
        "#0EA5E9",
        "#F59E0B",
        "#EF4444",
        "#A855F7",
        "#FB7185",
        "#84CC16"
    ]

    private let expenseManager = ExpenseManager()
    private let activityManager = ActivityManager()
    private let walletStorageKey = "utilityhub.expense.wallets.v1"
    private var walletDescriptors: [WalletDescriptor] = []

    private let amountParser: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.locale = .current
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    func refresh(context: ModelContext) {
        allExpenses = expenseManager.fetchAll(context: context)
        loadWalletDescriptors()
        syncWalletsWithTransactionsIfNeeded()
        rebuildSummaries()
    }

    func addWallet(
        name: String,
        accentHex: String? = nil,
        context: ModelContext,
        logActivity: Bool = true
    ) -> Bool {
        let cleanName = normalizedWalletName(name)
        guard !cleanName.isEmpty else { return false }

        guard !walletExists(named: cleanName) else { return false }

        let descriptor = WalletDescriptor(
            id: UUID(),
            name: cleanName,
            accentHex: accentHex ?? nextAccentHex(),
            createdAt: Date()
        )
        walletDescriptors.append(descriptor)
        persistWalletDescriptors()
        if logActivity {
            activityManager.log("Added wallet \(cleanName)", type: "expense", context: context)
            HapticService.tap()
        }
        refresh(context: context)
        return true
    }

    func deleteWallet(named walletName: String, removeTransactions: Bool, context: ModelContext) {
        walletDescriptors.removeAll { descriptor in
            sameWalletName(descriptor.name, walletName)
        }

        if removeTransactions {
            let targetEntries = allExpenses.filter { expense in
                sameWalletName(expense.category, walletName)
            }
            for entry in targetEntries {
                expenseManager.delete(entry, context: context)
            }
        }

        persistWalletDescriptors()
        activityManager.log("Deleted wallet \(walletName)", type: "expense", context: context)
        HapticService.warning()
        refresh(context: context)
    }

    func addEntry(
        amountText: String,
        kind: EntryKind,
        note: String,
        walletName: String,
        date: Date,
        context: ModelContext
    ) -> Bool {
        let cleanWalletName = normalizedWalletName(walletName)
        guard !cleanWalletName.isEmpty else { return false }

        guard let parsedAmount = parseAmount(from: amountText), parsedAmount > 0 else {
            return false
        }

        if !walletExists(named: cleanWalletName) {
            _ = addWallet(name: cleanWalletName, context: context, logActivity: false)
        }

        let signedAmount = kind == .income ? abs(parsedAmount) : -abs(parsedAmount)
        expenseManager.add(
            amount: signedAmount,
            category: cleanWalletName,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: date,
            context: context
        )

        let logTitle = kind == .income ? "Added income" : "Added expense"
        activityManager.log("\(logTitle) in \(cleanWalletName)", type: "expense", context: context)
        HapticService.tap()
        refresh(context: context)
        return true
    }

    func deleteEntry(_ entry: UHExpense, context: ModelContext) {
        expenseManager.delete(entry, context: context)
        activityManager.log("Deleted transaction from \(entry.category)", type: "expense", context: context)
        HapticService.warning()
        refresh(context: context)
    }

    func transactions(for walletName: String) -> [UHExpense] {
        allExpenses.filter { expense in
            sameWalletName(expense.category, walletName)
        }
    }

    func wallet(named walletName: String) -> WalletSummary? {
        wallets.first { wallet in
            sameWalletName(wallet.name, walletName)
        }
    }

    func formattedCurrency(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    func formattedSignedCurrency(_ value: Double) -> String {
        let amountText = formattedCurrency(abs(value))
        if value > 0 {
            return "+\(amountText)"
        }
        if value < 0 {
            return "-\(amountText)"
        }
        return amountText
    }

    func colorForAmount(_ value: Double) -> Color {
        if value > 0 {
            return Color(red: 0.14, green: 0.78, blue: 0.58)
        }
        if value < 0 {
            return Color(red: 0.95, green: 0.34, blue: 0.42)
        }
        return .secondary
    }

    func momentumProgress(for wallet: WalletSummary) -> Double {
        let denominator = abs(wallet.last30Days)
        guard denominator > 0 else { return 0 }
        return min(abs(wallet.last7Days) / denominator, 1)
    }

    func entrySummaryText(for wallet: WalletSummary) -> String {
        if wallet.transactionCount == 1 {
            return "1 transaction"
        }
        return "\(wallet.transactionCount) transactions"
    }

    private func rebuildSummaries() {
        totalBalance = allExpenses.reduce(0) { $0 + $1.amount }
        totalLast30Days = sum(allExpenses, inLast: 30)
        totalLast7Days = sum(allExpenses, inLast: 7)

        wallets = walletDescriptors.map { descriptor in
            let walletEntries = allExpenses.filter { expense in
                sameWalletName(expense.category, descriptor.name)
            }

            return WalletSummary(
                id: descriptor.id,
                name: descriptor.name,
                accentHex: descriptor.accentHex,
                total: walletEntries.reduce(0) { $0 + $1.amount },
                last30Days: sum(walletEntries, inLast: 30),
                last7Days: sum(walletEntries, inLast: 7),
                transactionCount: walletEntries.count
            )
        }
    }

    private func sum(_ entries: [UHExpense], inLast days: Int) -> Double {
        guard days > 0 else {
            return entries.reduce(0) { $0 + $1.amount }
        }

        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let offset = -(days - 1)
        let lowerBound = calendar.date(byAdding: .day, value: offset, to: todayStart) ?? todayStart

        return entries
            .filter { $0.createdAt >= lowerBound }
            .reduce(0) { $0 + $1.amount }
    }

    private func parseAmount(from raw: String) -> Double? {
        let compact = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[^0-9,.-]", with: "", options: .regularExpression)

        if let number = amountParser.number(from: compact) {
            return number.doubleValue
        }

        let normalized = compact.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private func normalizedWalletName(_ raw: String) -> String {
        let collapsed = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if collapsed.isEmpty {
            return ""
        }

        if collapsed == collapsed.lowercased() {
            return collapsed.capitalized
        }

        return collapsed
    }

    private func walletExists(named walletName: String) -> Bool {
        let inDescriptors = walletDescriptors.contains { descriptor in
            sameWalletName(descriptor.name, walletName)
        }
        if inDescriptors {
            return true
        }

        return allExpenses.contains { expense in
            sameWalletName(expense.category, walletName)
        }
    }

    private func sameWalletName(_ lhs: String, _ rhs: String) -> Bool {
        normalizedWalletName(lhs).lowercased() == normalizedWalletName(rhs).lowercased()
    }

    private func nextAccentHex() -> String {
        accentPalette[walletDescriptors.count % accentPalette.count]
    }

    private func syncWalletsWithTransactionsIfNeeded() {
        var didAppend = false

        for expense in allExpenses {
            let walletName = normalizedWalletName(expense.category)
            guard !walletName.isEmpty else { continue }

            let alreadyExists = walletDescriptors.contains { descriptor in
                sameWalletName(descriptor.name, walletName)
            }

            if !alreadyExists {
                walletDescriptors.append(
                    WalletDescriptor(
                        id: UUID(),
                        name: walletName,
                        accentHex: nextAccentHex(),
                        createdAt: expense.createdAt
                    )
                )
                didAppend = true
            }
        }

        if didAppend {
            persistWalletDescriptors()
        }
    }

    private func loadWalletDescriptors() {
        guard let data = UserDefaults.standard.data(forKey: walletStorageKey) else {
            walletDescriptors = []
            return
        }

        if let decoded = try? JSONDecoder().decode([WalletDescriptor].self, from: data) {
            walletDescriptors = decoded
        } else {
            walletDescriptors = []
        }
    }

    private func persistWalletDescriptors() {
        guard let data = try? JSONEncoder().encode(walletDescriptors) else { return }
        UserDefaults.standard.set(data, forKey: walletStorageKey)
    }
}
