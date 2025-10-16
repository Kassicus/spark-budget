//
//  TransactionViewModel.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import Foundation
import SwiftData
import Observation

@Observable
final class TransactionViewModel {
    var amount: String = ""
    var date: Date = Date()
    var description: String = ""
    var category: String = ""
    var type: TransactionType = .expense
    var payee: String = ""
    var notes: String = ""
    var selectedAccount: Account?
    var transferToAccount: Account?
    var receiptPhotoData: Data?

    // Validation
    var showError: Bool = false
    var errorMessage: String = ""

    init() {}

    init(transaction: Transaction) {
        self.amount = transaction.amount.description
        self.date = transaction.date
        self.description = transaction.desc
        self.category = transaction.category
        self.type = transaction.type
        self.payee = transaction.payee ?? ""
        self.notes = transaction.notes ?? ""
        self.selectedAccount = transaction.account
        self.transferToAccount = transaction.transferToAccount
        self.receiptPhotoData = transaction.receiptPhotoData
    }

    func validate() -> Bool {
        // Reset error state
        showError = false
        errorMessage = ""

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

        // Validate transfer destination
        if type == .transfer {
            guard let transferAccount = transferToAccount else {
                errorMessage = "Please select a destination account for the transfer"
                showError = true
                return false
            }

            guard transferAccount.id != selectedAccount?.id else {
                errorMessage = "Cannot transfer to the same account"
                showError = true
                return false
            }
        }

        // Validate category
        if category.isEmpty {
            errorMessage = "Please enter a category"
            showError = true
            return false
        }

        return true
    }

    func createTransaction(context: ModelContext) -> Transaction? {
        guard validate() else { return nil }

        guard let amountValue = Decimal(string: amount) else { return nil }

        let transaction = Transaction(
            amount: amountValue,
            date: date,
            description: description,
            category: category,
            type: type,
            payee: payee.isEmpty ? nil : payee,
            notes: notes.isEmpty ? nil : notes,
            receiptPhotoData: receiptPhotoData,
            account: selectedAccount,
            transferToAccount: type == .transfer ? transferToAccount : nil
        )

        context.insert(transaction)

        // Update account balance
        if let account = selectedAccount {
            updateAccountBalance(account: account, amount: amountValue, isAdding: true)
        }

        // If transfer, update destination account
        if type == .transfer, let toAccount = transferToAccount {
            updateAccountBalance(account: toAccount, amount: amountValue, isAdding: true, isTransferDestination: true)
        }

        return transaction
    }

    func updateTransaction(_ transaction: Transaction, context: ModelContext) {
        guard validate() else { return }

        guard let amountValue = Decimal(string: amount) else { return }

        // Reverse the original transaction's effect on balances
        if let account = transaction.account {
            updateAccountBalance(account: account, amount: transaction.amount, isAdding: false)
        }
        if transaction.type == .transfer, let toAccount = transaction.transferToAccount {
            updateAccountBalance(account: toAccount, amount: transaction.amount, isAdding: false, isTransferDestination: true)
        }

        // Update transaction properties
        transaction.amount = amountValue
        transaction.date = date
        transaction.desc = description
        transaction.category = category
        transaction.type = type
        transaction.payee = payee.isEmpty ? nil : payee
        transaction.notes = notes.isEmpty ? nil : notes
        transaction.receiptPhotoData = receiptPhotoData
        transaction.account = selectedAccount
        transaction.transferToAccount = type == .transfer ? transferToAccount : nil
        transaction.modifiedAt = Date()

        // Apply new transaction's effect on balances
        if let account = selectedAccount {
            updateAccountBalance(account: account, amount: amountValue, isAdding: true)
        }
        if type == .transfer, let toAccount = transferToAccount {
            updateAccountBalance(account: toAccount, amount: amountValue, isAdding: true, isTransferDestination: true)
        }
    }

    func deleteTransaction(_ transaction: Transaction, context: ModelContext) {
        // Reverse the transaction's effect on balances
        if let account = transaction.account {
            updateAccountBalance(account: account, amount: transaction.amount, isAdding: false)
        }
        if transaction.type == .transfer, let toAccount = transaction.transferToAccount {
            updateAccountBalance(account: toAccount, amount: transaction.amount, isAdding: false, isTransferDestination: true)
        }

        context.delete(transaction)
    }

    private func updateAccountBalance(account: Account, amount: Decimal, isAdding: Bool, isTransferDestination: Bool = false) {
        let transaction = account.transactions?.first { $0.amount == amount }
        let transactionType = transaction?.type ?? type

        // For transfers, we need special logic
        if transactionType == .transfer {
            if isTransferDestination {
                // Money coming into this account
                account.balance += isAdding ? amount : -amount
            } else {
                // Money leaving this account
                account.balance += isAdding ? -amount : amount
            }
        } else {
            // Normal income/expense
            switch transactionType {
            case .income:
                account.balance += isAdding ? amount : -amount
            case .expense:
                account.balance -= isAdding ? amount : -amount
            case .transfer:
                break // Already handled above
            }
        }

        account.modifiedAt = Date()
    }

    func reset() {
        amount = ""
        date = Date()
        description = ""
        category = ""
        type = .expense
        payee = ""
        notes = ""
        selectedAccount = nil
        transferToAccount = nil
        receiptPhotoData = nil
        showError = false
        errorMessage = ""
    }
}

// Common transaction categories
extension TransactionViewModel {
    static let expenseCategories = [
        "Food & Dining",
        "Groceries",
        "Transportation",
        "Shopping",
        "Entertainment",
        "Bills & Utilities",
        "Healthcare",
        "Personal Care",
        "Travel",
        "Education",
        "Gifts",
        "Other"
    ]

    static let incomeCategories = [
        "Salary",
        "Freelance",
        "Investment",
        "Gift",
        "Refund",
        "Other"
    ]

    var availableCategories: [String] {
        switch type {
        case .income:
            return Self.incomeCategories
        case .expense:
            return Self.expenseCategories
        case .transfer:
            return ["Transfer"]
        }
    }
}
