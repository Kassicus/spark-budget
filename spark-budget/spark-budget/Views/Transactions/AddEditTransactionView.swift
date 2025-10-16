//
//  AddEditTransactionView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddEditTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]

    @State private var viewModel: TransactionViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?

    let transaction: Transaction?
    let onSave: (() -> Void)?

    init(transaction: Transaction? = nil, onSave: (() -> Void)? = nil) {
        self.transaction = transaction
        self.onSave = onSave
        if let transaction = transaction {
            _viewModel = State(initialValue: TransactionViewModel(transaction: transaction))
        } else {
            _viewModel = State(initialValue: TransactionViewModel())
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Transaction Type
                Section {
                    Picker("Type", selection: $viewModel.type) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.type) { oldValue, newValue in
                        // Reset category when type changes
                        if oldValue != newValue {
                            viewModel.category = ""
                            if newValue == .transfer {
                                viewModel.category = "Transfer"
                            }
                        }
                    }
                }

                // Amount and Date
                Section("Transaction Details") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Amount", text: $viewModel.amount)
                            .keyboardType(.decimalPad)
                    }

                    DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                }

                // Account Selection
                Section("Account") {
                    Picker("From Account", selection: $viewModel.selectedAccount) {
                        Text("Select Account").tag(nil as Account?)
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

                    // Show transfer destination for transfers
                    if viewModel.type == .transfer {
                        Picker("To Account", selection: $viewModel.transferToAccount) {
                            Text("Select Account").tag(nil as Account?)
                            ForEach(accounts.filter { $0.id != viewModel.selectedAccount?.id }) { account in
                                HStack {
                                    Circle()
                                        .fill(account.color)
                                        .frame(width: 10, height: 10)
                                    Text(account.name)
                                }
                                .tag(account as Account?)
                            }
                        }
                    }
                }

                // Category and Description
                Section("Information") {
                    if viewModel.type != .transfer {
                        Picker("Category", selection: $viewModel.category) {
                            Text("Select Category").tag("")
                            ForEach(viewModel.availableCategories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                    }

                    TextField("Description", text: $viewModel.description)

                    if viewModel.type != .transfer {
                        TextField("Payee/Payer (Optional)", text: $viewModel.payee)
                    }
                }

                // Notes and Receipt
                Section("Additional Details") {
                    TextField("Notes (Optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)

                    // Photo picker for receipt
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: "camera")
                            Text(viewModel.receiptPhotoData == nil ? "Add Receipt Photo" : "Change Receipt Photo")
                        }
                    }
                    .onChange(of: selectedPhotoItem) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                viewModel.receiptPhotoData = data
                            }
                        }
                    }

                    if viewModel.receiptPhotoData != nil {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundStyle(.green)
                            Text("Receipt attached")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Remove", role: .destructive) {
                                viewModel.receiptPhotoData = nil
                                selectedPhotoItem = nil
                            }
                            .font(.caption)
                        }
                    }
                }

                // Transaction Summary
                Section("Summary") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        if let amount = Decimal(string: viewModel.amount) {
                            Text(formatCurrency(amount))
                                .foregroundStyle(viewModel.type == .income ? .green : .red)
                                .bold()
                        }
                    }

                    if let account = viewModel.selectedAccount {
                        HStack {
                            Text("Account")
                            Spacer()
                            HStack {
                                Circle()
                                    .fill(account.color)
                                    .frame(width: 10, height: 10)
                                Text(account.name)
                            }
                        }
                    }

                    if viewModel.type == .transfer, let toAccount = viewModel.transferToAccount {
                        HStack {
                            Text("To Account")
                            Spacer()
                            HStack {
                                Circle()
                                    .fill(toAccount.color)
                                    .frame(width: 10, height: 10)
                                Text(toAccount.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle(transaction == nil ? "Add Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    private func saveTransaction() {
        if let transaction = transaction {
            // Update existing transaction
            viewModel.updateTransaction(transaction, context: modelContext)
        } else {
            // Create new transaction
            _ = viewModel.createTransaction(context: modelContext)
        }

        // Save context
        do {
            try modelContext.save()
            onSave?()
            dismiss()
        } catch {
            viewModel.errorMessage = "Failed to save transaction: \(error.localizedDescription)"
            viewModel.showError = true
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

#Preview("Add Transaction") {
    AddEditTransactionView()
        .modelContainer(for: [Transaction.self, Account.self], inMemory: true)
}

#Preview("Edit Transaction") {
    let container = try! ModelContainer(for: Transaction.self, Account.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)

    let account = Account(name: "Checking", type: .checking, balance: 1000)
    context.insert(account)

    let transaction = Transaction(
        amount: 50.00,
        date: Date(),
        description: "Grocery Store",
        category: "Groceries",
        type: .expense,
        account: account
    )
    context.insert(transaction)

    return AddEditTransactionView(transaction: transaction)
        .modelContainer(container)
}
