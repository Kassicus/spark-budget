//
//  TransactionsListView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import SwiftUI
import SwiftData

struct TransactionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var accounts: [Account]

    @State private var showAddTransaction = false
    @State private var searchText = ""
    @State private var filterType: TransactionType?
    @State private var filterAccount: Account?
    @State private var showFilterSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if filteredTransactions.isEmpty {
                    ContentUnavailableView {
                        Label("No Transactions", systemImage: "dollarsign.circle")
                    } description: {
                        Text("Add your first transaction to get started tracking your finances.")
                    } actions: {
                        Button("Add Transaction") {
                            showAddTransaction = true
                        }
                    }
                } else {
                    List {
                        ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                            Section {
                                ForEach(groupedTransactions[date] ?? []) { transaction in
                                    NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                        TransactionRowView(transaction: transaction)
                                    }
                                }
                            } header: {
                                Text(date, style: .date)
                            }
                        }
                    }
                    .refreshable {
                        await refreshTransactions()
                    }
                    .searchable(text: $searchText, prompt: "Search transactions")
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if filterType != nil || filterAccount != nil {
                        Button {
                            showFilterSheet = true
                        } label: {
                            Label("Filters Active", systemImage: "line.3.horizontal.decrease.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    } else {
                        Button {
                            showFilterSheet = true
                        } label: {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddTransaction = true
                    } label: {
                        Label("Add Transaction", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddEditTransactionView()
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView(
                    filterType: $filterType,
                    filterAccount: $filterAccount,
                    accounts: accounts
                )
            }
        }
    }

    private var filteredTransactions: [Transaction] {
        var transactions = allTransactions

        // Filter by search text
        if !searchText.isEmpty {
            transactions = transactions.filter { transaction in
                transaction.desc.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText) ||
                (transaction.payee?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (transaction.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Filter by type
        if let filterType = filterType {
            transactions = transactions.filter { $0.type == filterType }
        }

        // Filter by account
        if let filterAccount = filterAccount {
            transactions = transactions.filter { $0.account?.id == filterAccount.id }
        }

        return transactions
    }

    private var groupedTransactions: [Date: [Transaction]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
        return grouped
    }

    private func refreshTransactions() async {
        // Simulate a brief refresh delay for smooth animation
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        // SwiftData automatically refreshes queries
    }
}

struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var filterType: TransactionType?
    @Binding var filterAccount: Account?
    let accounts: [Account]

    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Type") {
                    Picker("Type", selection: $filterType) {
                        Text("All Types").tag(nil as TransactionType?)
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .tag(type as TransactionType?)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Account") {
                    Picker("Account", selection: $filterAccount) {
                        Text("All Accounts").tag(nil as Account?)
                        ForEach(accounts) { account in
                            HStack {
                                Circle()
                                    .fill(account.color)
                                    .frame(width: 10, height: 10)
                                Text(account.name)
                            }
                            .tag(account as Account?)
                        }
                    }
                    .pickerStyle(.inline)
                }

                if filterType != nil || filterAccount != nil {
                    Section {
                        Button("Clear All Filters", role: .destructive) {
                            filterType = nil
                            filterAccount = nil
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Filter Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview("With Transactions") {
    let container = try! ModelContainer(for: Transaction.self, Account.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)

    let checking = Account(name: "Checking", type: .checking, balance: 1000)
    let savings = Account(name: "Savings", type: .savings, balance: 5000)
    context.insert(checking)
    context.insert(savings)

    let transactions = [
        Transaction(amount: 2500, date: Date(), description: "Salary", category: "Salary", type: .income, account: checking),
        Transaction(amount: 45.99, date: Date().addingTimeInterval(-86400), description: "Groceries", category: "Food", type: .expense, payee: "Whole Foods", account: checking),
        Transaction(amount: 500, date: Date().addingTimeInterval(-172800), description: "Transfer to Savings", category: "Transfer", type: .transfer, account: checking, transferToAccount: savings)
    ]

    transactions.forEach { context.insert($0) }

    return TransactionsListView()
        .modelContainer(container)
}

#Preview("Empty State") {
    TransactionsListView()
        .modelContainer(for: [Transaction.self, Account.self], inMemory: true)
}
