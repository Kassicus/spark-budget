//
//  BillViewModel.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import Foundation
import SwiftData
import Observation

@Observable
final class BillViewModel {
    var title: String = ""
    var category: String = ""
    var amount: String = ""
    var dueDate: Date = Date()
    var recurrence: RecurrenceType = .monthly
    var notes: String = ""
    var selectedAccount: Account?
    var isPaid: Bool = false

    // Validation
    var showError: Bool = false
    var errorMessage: String = ""

    init() {}

    init(bill: Bill) {
        self.title = bill.title
        self.category = bill.category
        self.amount = bill.amount.description
        self.dueDate = bill.dueDate
        self.recurrence = bill.recurrence
        self.notes = bill.notes ?? ""
        self.selectedAccount = bill.account
        self.isPaid = bill.isPaid
    }

    func validate() -> Bool {
        // Reset error state
        showError = false
        errorMessage = ""

        // Validate title
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter a bill title"
            showError = true
            return false
        }

        // Validate amount
        guard let amountValue = Decimal(string: amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount greater than 0"
            showError = true
            return false
        }

        // Validate account selection
        guard selectedAccount != nil else {
            errorMessage = "Please select an account"
            showError = true
            return false
        }

        // Validate category
        if category.isEmpty {
            errorMessage = "Please select or enter a category"
            showError = true
            return false
        }

        return true
    }

    func createBill(context: ModelContext) -> Bill? {
        guard validate() else { return nil }

        guard let amountValue = Decimal(string: amount) else { return nil }

        let bill = Bill(
            title: title,
            category: category,
            amount: amountValue,
            dueDate: dueDate,
            recurrence: recurrence,
            isPaid: isPaid,
            notes: notes.isEmpty ? nil : notes,
            account: selectedAccount
        )

        context.insert(bill)
        return bill
    }

    func updateBill(_ bill: Bill, context: ModelContext) {
        guard validate() else { return }

        guard let amountValue = Decimal(string: amount) else { return }

        bill.title = title
        bill.category = category
        bill.amount = amountValue
        bill.dueDate = dueDate
        bill.recurrence = recurrence
        bill.notes = notes.isEmpty ? nil : notes
        bill.account = selectedAccount
        bill.isPaid = isPaid
        bill.modifiedAt = Date()
    }

    func deleteBill(_ bill: Bill, context: ModelContext) {
        context.delete(bill)
    }

    func markAsPaid(
        _ bill: Bill,
        context: ModelContext,
        createTransaction: Bool = true
    ) -> Transaction? {
        bill.isPaid = true
        bill.lastPaidDate = Date()
        bill.modifiedAt = Date()

        // If recurring, update the due date to next occurrence
        if bill.recurrence != .oneTime {
            bill.dueDate = bill.recurrence.nextDate(from: bill.dueDate)
            bill.isPaid = false // Reset for next occurrence
        }

        // Create transaction if requested
        if createTransaction, let account = bill.account {
            let transaction = Transaction(
                amount: bill.amount,
                date: bill.lastPaidDate ?? Date(),
                description: bill.title,
                category: bill.category,
                type: .expense,
                notes: "Bill payment: \(bill.title)",
                account: account
            )

            context.insert(transaction)

            // Update account balance
            account.balance -= bill.amount
            account.modifiedAt = Date()

            return transaction
        }

        return nil
    }

    func reset() {
        title = ""
        category = ""
        amount = ""
        dueDate = Date()
        recurrence = .monthly
        notes = ""
        selectedAccount = nil
        isPaid = false
        showError = false
        errorMessage = ""
    }
}

// Common bill categories
extension BillViewModel {
    static let billCategories = [
        "Rent/Mortgage",
        "Utilities",
        "Internet",
        "Phone",
        "Insurance",
        "Subscriptions",
        "Loan Payment",
        "Credit Card",
        "Car Payment",
        "Healthcare",
        "Education",
        "Other"
    ]
}
