//
//  AccountsListView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import SwiftUI
import SwiftData

struct AccountsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allAccounts: [Account]

    @State private var showingAddSheet = false
    @State private var isRefreshing = false

    var accounts: [Account] {
        allAccounts.sorted { first, second in
            if first.isPrimary != second.isPrimary {
                return first.isPrimary
            }
            return first.name < second.name
        }
    }

    var totalBalance: Decimal {
        accounts.reduce(0) { $0 + $1.balance }
    }

    var formattedTotalBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: totalBalance as NSDecimalNumber) ?? "$0.00"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if accounts.isEmpty {
                    ContentUnavailableView(
                        "No Accounts",
                        systemImage: "creditcard",
                        description: Text("Add your first account to get started")
                    )
                } else {
                    List {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Total Balance")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(formattedTotalBalance)
                                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                Text("\(accounts.count) account\(accounts.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }

                        Section("Accounts") {
                            ForEach(accounts) { account in
                                NavigationLink(destination: AccountDetailView(account: account)) {
                                    AccountCard(account: account)
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                            }
                            .onDelete(perform: deleteAccounts)
                        }
                    }
                    .refreshable {
                        await refreshAccounts()
                    }
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Label("Add Account", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditAccountView()
            }
        }
    }

    private func deleteAccounts(offsets: IndexSet) {
        withAnimation(.smooth) {
            for index in offsets {
                modelContext.delete(accounts[index])
            }
        }
    }

    private func refreshAccounts() async {
        // Simulate a brief refresh delay for smooth animation
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        // SwiftData automatically refreshes queries
    }
}

#Preview {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Account.self, configurations: config)

        let account1 = Account(name: "Chase Checking", type: .checking, balance: 2500.75, isPrimary: true)
        let account2 = Account(name: "Savings Account", type: .savings, balance: 10000.00)
        let account3 = Account(name: "Credit Card", type: .creditCard, balance: -150.25)

        container.mainContext.insert(account1)
        container.mainContext.insert(account2)
        container.mainContext.insert(account3)

        return container
    }()

    return AccountsListView()
        .modelContainer(container)
}
