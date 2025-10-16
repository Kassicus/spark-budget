//
//  TransactionDetailView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let transaction: Transaction

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var receiptImage: UIImage?

    var body: some View {
        List {
            // Amount Section
            Section {
                VStack(spacing: 8) {
                    Image(systemName: transaction.type.iconName)
                        .font(.system(size: 50))
                        .foregroundStyle(typeColor)

                    Text(transaction.formattedAmount)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(typeColor)

                    Text(transaction.type.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .listRowBackground(Color.clear)

            // Basic Information
            Section("Information") {
                DetailRow(label: "Description", value: transaction.displayDescription)
                DetailRow(label: "Category", value: transaction.category)

                if let payee = transaction.payee, !payee.isEmpty {
                    DetailRow(label: "Payee", value: payee)
                }

                DetailRow(label: "Date", value: transaction.date.formatted(date: .long, time: .shortened))
            }

            // Account Information
            Section("Account") {
                if let account = transaction.account {
                    HStack {
                        Text("Account")
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 8) {
                            Circle()
                                .fill(account.color)
                                .frame(width: 10, height: 10)
                            VStack(alignment: .trailing) {
                                Text(account.name)
                                    .fontWeight(.medium)
                                Text(account.type.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if transaction.type == .transfer, let toAccount = transaction.transferToAccount {
                    HStack {
                        Text("To Account")
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 8) {
                            Circle()
                                .fill(toAccount.color)
                                .frame(width: 10, height: 10)
                            VStack(alignment: .trailing) {
                                Text(toAccount.name)
                                    .fontWeight(.medium)
                                Text(toAccount.type.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            // Notes
            if let notes = transaction.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .font(.body)
                }
            }

            // Receipt Photo
            if transaction.receiptPhotoData != nil {
                Section("Receipt") {
                    if let image = receiptImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            // Metadata
            Section("Details") {
                DetailRow(label: "Created", value: transaction.createdAt.formatted(date: .abbreviated, time: .shortened))
                DetailRow(label: "Modified", value: transaction.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                DetailRow(label: "ID", value: transaction.id.uuidString)
                    .font(.caption)
            }

            // Delete Button
            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Transaction")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddEditTransactionView(transaction: transaction) {
                // Refresh view after save
            }
        }
        .alert("Delete Transaction", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteTransaction()
            }
        } message: {
            Text("Are you sure you want to delete this transaction? This action cannot be undone.")
        }
        .task {
            loadReceiptImage()
        }
    }

    private var typeColor: Color {
        switch transaction.type {
        case .income:
            return .green
        case .expense:
            return .red
        case .transfer:
            return .blue
        }
    }

    private func loadReceiptImage() {
        guard let data = transaction.receiptPhotoData,
              let image = UIImage(data: data) else {
            return
        }
        receiptImage = image
    }

    private func deleteTransaction() {
        let viewModel = TransactionViewModel()
        viewModel.deleteTransaction(transaction, context: modelContext)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting transaction: \(error)")
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    NavigationStack {
        let account = Account(name: "Checking", type: .checking, balance: 1000)
        let transaction = Transaction(
            amount: 125.50,
            date: Date(),
            description: "Grocery Shopping",
            category: "Groceries",
            type: .expense,
            payee: "Whole Foods",
            notes: "Weekly grocery shopping trip. Bought organic produce and some snacks for the week.",
            account: account
        )

        TransactionDetailView(transaction: transaction)
            .modelContainer(for: [Transaction.self, Account.self], inMemory: true)
    }
}
