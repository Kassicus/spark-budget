//
//  AccountDetailView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import SwiftUI
import SwiftData

struct AccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let account: Account

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var accountTransactions: [Transaction] {
        account.transactions?.sorted(by: { $0.date > $1.date }) ?? []
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: account.type.iconName)
                            .font(.system(size: 40))
                            .foregroundColor(account.color)

                        VStack(alignment: .leading) {
                            Text(account.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(account.type.rawValue)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Current Balance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(account.formattedBalance)
                                .font(.title)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        if account.isPrimary {
                            VStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Primary")
                                    .font(.caption)
                            }
                        }
                    }

                    if account.accountNumber != nil {
                        HStack {
                            Text("Account Number")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(account.displayAccountNumber)
                        }
                        .font(.footnote)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Recent Transactions") {
                if accountTransactions.isEmpty {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Transactions for this account will appear here")
                    )
                } else {
                    ForEach(accountTransactions.prefix(10)) { transaction in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(transaction.displayDescription)
                                    .font(.headline)
                                Text(transaction.category)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text(transaction.formattedAmount)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(transaction.type == .expense ? .red : .green)
                                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Account")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Account Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddEditAccountView(account: account)
        }
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Are you sure you want to delete this account? This will also delete all associated transactions and cannot be undone.")
        }
    }

    private func deleteAccount() {
        modelContext.delete(account)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Account.self, Transaction.self, configurations: config)

    let account = Account(
        name: "Chase Checking",
        type: .checking,
        balance: 2500.75,
        isPrimary: true,
        accountNumber: "1234"
    )
    container.mainContext.insert(account)

    return NavigationStack {
        AccountDetailView(account: account)
    }
    .modelContainer(container)
}
