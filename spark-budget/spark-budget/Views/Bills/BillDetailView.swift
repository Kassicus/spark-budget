//
//  BillDetailView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import SwiftUI
import SwiftData

struct BillDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let bill: Bill

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showPaymentSheet = false

    var body: some View {
        List {
            // Status Section
            Section {
                VStack(spacing: 12) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 50))
                        .foregroundStyle(statusColor)

                    Text(bill.formattedAmount)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(statusColor)

                    Text(bill.title)
                        .font(.title3)
                        .fontWeight(.semibold)

                    if bill.isPaid {
                        Label("Paid", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    } else if bill.isOverdue {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    } else if bill.isDueSoon {
                        Label("Due Soon", systemImage: "clock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .listRowBackground(Color.clear)

            // Bill Information
            Section("Information") {
                DetailRow(label: "Category", value: bill.category)
                DetailRow(label: "Recurrence", value: bill.recurrence.rawValue)
                DetailRow(label: "Due Date", value: bill.dueDate.formatted(date: .long, time: .omitted))

                if bill.recurrence != .oneTime {
                    HStack {
                        Text("Next Due Date")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(bill.nextDueDate, style: .date)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
                }

                HStack {
                    Text("Days Until Due")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if bill.daysUntilDue < 0 {
                        Text("\(abs(bill.daysUntilDue)) days overdue")
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                    } else if bill.daysUntilDue == 0 {
                        Text("Due Today")
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                    } else {
                        Text("\(bill.daysUntilDue) days")
                            .fontWeight(.medium)
                    }
                }
            }

            // Account Information
            if let account = bill.account {
                Section("Payment Account") {
                    HStack {
                        Circle()
                            .fill(account.color)
                            .frame(width: 12, height: 12)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(account.name)
                                .fontWeight(.medium)
                            Text(account.type.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(account.formattedBalance)
                            .fontWeight(.medium)
                    }
                }
            }

            // Payment History
            if let lastPaidDate = bill.lastPaidDate {
                Section("Payment History") {
                    DetailRow(label: "Last Paid", value: lastPaidDate.formatted(date: .long, time: .omitted))
                }
            }

            // Notes
            if let notes = bill.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .font(.body)
                }
            }

            // Metadata
            Section("Details") {
                DetailRow(label: "Created", value: bill.createdAt.formatted(date: .abbreviated, time: .shortened))
                DetailRow(label: "Modified", value: bill.modifiedAt.formatted(date: .abbreviated, time: .shortened))
            }

            // Actions
            if !bill.isPaid {
                Section {
                    Button {
                        showPaymentSheet = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Mark as Paid", systemImage: "checkmark.circle.fill")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }

            // Delete Button
            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Bill")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Bill Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddEditBillView(bill: bill)
        }
        .sheet(isPresented: $showPaymentSheet) {
            MarkAsPaidSheet(bill: bill)
        }
        .alert("Delete Bill", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteBill()
            }
        } message: {
            Text("Are you sure you want to delete this bill? This action cannot be undone.")
        }
    }

    private var statusColor: Color {
        if bill.isPaid {
            return .green
        } else if bill.isOverdue {
            return .red
        } else if bill.isDueSoon {
            return .orange
        }
        return .blue
    }

    private var statusIcon: String {
        if bill.isPaid {
            return "checkmark.circle.fill"
        } else if bill.isOverdue {
            return "exclamationmark.triangle.fill"
        } else if bill.isDueSoon {
            return "clock.fill"
        }
        return "doc.text.fill"
    }

    private func deleteBill() {
        let viewModel = BillViewModel()
        viewModel.deleteBill(bill, context: modelContext)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting bill: \(error)")
        }
    }
}

// Mark as Paid Sheet
struct MarkAsPaidSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let bill: Bill

    @State private var createTransaction = true
    @State private var paymentDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Payment Date", selection: $paymentDate, displayedComponents: .date)

                    Toggle("Create Transaction", isOn: $createTransaction)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This will:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if createTransaction {
                            Label("Create an expense transaction for \(bill.formattedAmount)", systemImage: "dollarsign.circle")
                                .font(.caption)
                        }

                        if bill.recurrence != .oneTime {
                            Label("Update the due date to \(bill.nextDueDate.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                                .font(.caption)
                        } else {
                            Label("Mark this bill as paid", systemImage: "checkmark.circle")
                                .font(.caption)
                        }
                    }
                }

                Section {
                    Button {
                        markAsPaid()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Confirm Payment")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Mark as Paid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func markAsPaid() {
        let viewModel = BillViewModel()
        bill.lastPaidDate = paymentDate
        _ = viewModel.markAsPaid(bill, context: modelContext, createTransaction: createTransaction)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error marking bill as paid: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        let account = Account(name: "Checking", type: .checking, balance: 2500)
        let bill = Bill(
            title: "Rent",
            category: "Rent/Mortgage",
            amount: 1500.00,
            dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
            recurrence: .monthly,
            notes: "Monthly rent payment for apartment 202",
            account: account
        )

        BillDetailView(bill: bill)
            .modelContainer(for: [Bill.self, Account.self], inMemory: true)
    }
}
