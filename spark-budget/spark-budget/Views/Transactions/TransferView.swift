//
//  TransferView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import SwiftUI
import SwiftData

struct TransferView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]

    @State private var viewModel = TransactionViewModel()
    @State private var showError = false

    init() {
        _viewModel = State(initialValue: TransactionViewModel())
    }

    var body: some View {
        NavigationStack {
            Form {
                // Amount
                Section {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                        TextField("Amount", text: $viewModel.amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                } header: {
                    Text("Transfer Amount")
                }

                // From Account
                Section {
                    Picker("From", selection: $viewModel.selectedAccount) {
                        Text("Select Account").tag(nil as Account?)
                        ForEach(accounts) { account in
                            HStack {
                                Circle()
                                    .fill(account.color)
                                    .frame(width: 10, height: 10)
                                VStack(alignment: .leading) {
                                    Text(account.name)
                                    Text(account.formattedBalance)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(account as Account?)
                        }
                    }

                    if let fromAccount = viewModel.selectedAccount {
                        HStack {
                            Text("Current Balance")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(fromAccount.formattedBalance)
                                .fontWeight(.medium)
                        }

                        if let amount = Decimal(string: viewModel.amount), amount > 0 {
                            HStack {
                                Text("After Transfer")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatCurrency(fromAccount.balance - amount))
                                    .fontWeight(.medium)
                                    .foregroundStyle(fromAccount.balance - amount < 0 ? .red : .primary)
                            }
                        }
                    }
                } header: {
                    Text("From Account")
                }

                // To Account
                Section {
                    Picker("To", selection: $viewModel.transferToAccount) {
                        Text("Select Account").tag(nil as Account?)
                        ForEach(accounts.filter { $0.id != viewModel.selectedAccount?.id }) { account in
                            HStack {
                                Circle()
                                    .fill(account.color)
                                    .frame(width: 10, height: 10)
                                VStack(alignment: .leading) {
                                    Text(account.name)
                                    Text(account.formattedBalance)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(account as Account?)
                        }
                    }

                    if let toAccount = viewModel.transferToAccount {
                        HStack {
                            Text("Current Balance")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(toAccount.formattedBalance)
                                .fontWeight(.medium)
                        }

                        if let amount = Decimal(string: viewModel.amount), amount > 0 {
                            HStack {
                                Text("After Transfer")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatCurrency(toAccount.balance + amount))
                                    .fontWeight(.medium)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                } header: {
                    Text("To Account")
                }

                // Date and Notes
                Section {
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])

                    TextField("Description (Optional)", text: $viewModel.description)

                    TextField("Notes (Optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Details")
                }

                // Transfer Summary
                if let amount = Decimal(string: viewModel.amount),
                   amount > 0,
                   let fromAccount = viewModel.selectedAccount,
                   let toAccount = viewModel.transferToAccount {
                    Section {
                        VStack(spacing: 16) {
                            // Transfer visualization
                            HStack(spacing: 20) {
                                // From
                                VStack {
                                    Circle()
                                        .fill(fromAccount.color)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: fromAccount.type.iconName)
                                                .foregroundStyle(.white)
                                        )
                                    Text(fromAccount.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }

                                // Arrow
                                Image(systemName: "arrow.right")
                                    .font(.title2)
                                    .foregroundStyle(.blue)

                                // To
                                VStack {
                                    Circle()
                                        .fill(toAccount.color)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: toAccount.type.iconName)
                                                .foregroundStyle(.white)
                                        )
                                    Text(toAccount.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)

                            // Amount
                            Text(formatCurrency(amount))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        }
                    } header: {
                        Text("Transfer Summary")
                    }
                }

                // Transfer Button
                Section {
                    Button {
                        performTransfer()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Complete Transfer")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Transfer Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                viewModel.type = .transfer
                viewModel.category = "Transfer"
                if viewModel.description.isEmpty {
                    viewModel.description = "Account Transfer"
                }
            }
        }
    }

    private var isValid: Bool {
        guard let amount = Decimal(string: viewModel.amount), amount > 0 else {
            return false
        }
        guard viewModel.selectedAccount != nil else {
            return false
        }
        guard viewModel.transferToAccount != nil else {
            return false
        }
        return true
    }

    private func performTransfer() {
        guard isValid else { return }

        if viewModel.createTransaction(context: modelContext) != nil {
            do {
                try modelContext.save()
                dismiss()
            } catch {
                viewModel.errorMessage = "Failed to complete transfer: \(error.localizedDescription)"
                viewModel.showError = true
            }
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

#Preview {
    let container = try! ModelContainer(for: Account.self, Transaction.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)

    let checking = Account(name: "Checking", type: .checking, balance: 2500)
    let savings = Account(name: "Savings", type: .savings, balance: 10000)
    let credit = Account(name: "Credit Card", type: .creditCard, balance: -450)

    context.insert(checking)
    context.insert(savings)
    context.insert(credit)

    return TransferView()
        .modelContainer(container)
}
