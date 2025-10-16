//
//  AddEditBillView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import SwiftUI
import SwiftData

struct AddEditBillView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]

    @State private var viewModel: BillViewModel

    let bill: Bill?
    let onSave: (() -> Void)?

    init(bill: Bill? = nil, onSave: (() -> Void)? = nil) {
        self.bill = bill
        self.onSave = onSave
        if let bill = bill {
            _viewModel = State(initialValue: BillViewModel(bill: bill))
        } else {
            _viewModel = State(initialValue: BillViewModel())
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Bill Information
                Section("Bill Information") {
                    TextField("Bill Name", text: $viewModel.title)
                        .textInputAutocapitalization(.words)

                    Picker("Category", selection: $viewModel.category) {
                        Text("Select Category").tag("")
                        ForEach(BillViewModel.billCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Amount", text: $viewModel.amount)
                            .keyboardType(.decimalPad)
                    }
                }

                // Account
                Section("Account") {
                    Picker("Payment Account", selection: $viewModel.selectedAccount) {
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

                    if let account = viewModel.selectedAccount {
                        HStack {
                            Text("Current Balance")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(account.formattedBalance)
                                .fontWeight(.medium)
                        }
                    }
                }

                // Due Date & Recurrence
                Section("Schedule") {
                    DatePicker("Due Date", selection: $viewModel.dueDate, displayedComponents: .date)

                    Picker("Recurrence", selection: $viewModel.recurrence) {
                        ForEach(RecurrenceType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    if viewModel.recurrence != .oneTime {
                        HStack {
                            Text("Next Due Date")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(viewModel.recurrence.nextDate(from: viewModel.dueDate), style: .date)
                                .foregroundStyle(.blue)
                        }
                    }
                }

                // Payment Status
                if bill != nil {
                    Section("Status") {
                        Toggle("Paid", isOn: $viewModel.isPaid)
                    }
                }

                // Notes
                Section("Notes") {
                    TextField("Add notes (optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Summary
                Section("Summary") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        if let amount = Decimal(string: viewModel.amount) {
                            Text(formatCurrency(amount))
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
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

                    HStack {
                        Text("Frequency")
                        Spacer()
                        Text(viewModel.recurrence.rawValue)
                    }

                    HStack {
                        Text("Next Due")
                        Spacer()
                        Text(viewModel.dueDate, style: .date)
                            .foregroundStyle(
                                bill?.isOverdue == true ? .red :
                                bill?.isDueSoon == true ? .orange : .primary
                            )
                    }
                }
            }
            .navigationTitle(bill == nil ? "Add Bill" : "Edit Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBill()
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

    private func saveBill() {
        if let bill = bill {
            // Update existing bill
            viewModel.updateBill(bill, context: modelContext)
        } else {
            // Create new bill
            _ = viewModel.createBill(context: modelContext)
        }

        // Save context
        do {
            try modelContext.save()
            onSave?()
            dismiss()
        } catch {
            viewModel.errorMessage = "Failed to save bill: \(error.localizedDescription)"
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

#Preview("Add Bill") {
    let container = try! ModelContainer(for: Bill.self, Account.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)

    let checking = Account(name: "Checking", type: .checking, balance: 2500)
    context.insert(checking)

    return AddEditBillView()
        .modelContainer(container)
}

#Preview("Edit Bill") {
    let container = try! ModelContainer(for: Bill.self, Account.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)

    let checking = Account(name: "Checking", type: .checking, balance: 2500)
    context.insert(checking)

    let bill = Bill(
        title: "Rent",
        category: "Rent/Mortgage",
        amount: 1500.00,
        dueDate: Date(),
        recurrence: .monthly,
        account: checking
    )
    context.insert(bill)

    return AddEditBillView(bill: bill)
        .modelContainer(container)
}
