//
//  TransactionManager.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import Foundation
import SwiftData

/// Actor-based transaction manager for thread-safe transaction operations
/// Handles bulk operations, imports, and complex transaction processing
actor TransactionManager {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Transaction Creation

    func createTransaction(
        amount: Decimal,
        date: Date,
        description: String,
        category: String,
        type: TransactionType,
        payee: String? = nil,
        notes: String? = nil,
        accountID: UUID,
        transferToAccountID: UUID? = nil
    ) async throws -> Transaction {
        let context = ModelContext(modelContainer)

        // Fetch accounts
        let accountDescriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.id == accountID }
        )
        guard let account = try context.fetch(accountDescriptor).first else {
            throw TransactionManagerError.accountNotFound
        }

        var transferToAccount: Account? = nil
        if let transferToAccountID = transferToAccountID {
            let transferDescriptor = FetchDescriptor<Account>(
                predicate: #Predicate { $0.id == transferToAccountID }
            )
            transferToAccount = try context.fetch(transferDescriptor).first
        }

        // Create transaction
        let transaction = Transaction(
            amount: amount,
            date: date,
            description: description,
            category: category,
            type: type,
            payee: payee,
            notes: notes,
            account: account,
            transferToAccount: transferToAccount
        )

        context.insert(transaction)

        // Update account balance
        updateAccountBalance(account: account, amount: amount, type: type, isAdding: true)

        // Update transfer destination balance
        if type == .transfer, let toAccount = transferToAccount {
            toAccount.balance += amount
            toAccount.modifiedAt = Date()
        }

        try context.save()
        return transaction
    }

    // MARK: - Bulk Operations

    func createBulkTransactions(_ transactions: [(
        amount: Decimal,
        date: Date,
        description: String,
        category: String,
        type: TransactionType,
        accountID: UUID
    )]) async throws -> Int {
        let context = ModelContext(modelContainer)
        var createdCount = 0

        for transactionData in transactions {
            let accountID = transactionData.accountID
            let accountDescriptor = FetchDescriptor<Account>(
                predicate: #Predicate { $0.id == accountID }
            )
            guard let account = try context.fetch(accountDescriptor).first else {
                continue
            }

            let transaction = Transaction(
                amount: transactionData.amount,
                date: transactionData.date,
                description: transactionData.description,
                category: transactionData.category,
                type: transactionData.type,
                account: account
            )

            context.insert(transaction)
            updateAccountBalance(account: account, amount: transactionData.amount, type: transactionData.type, isAdding: true)
            createdCount += 1
        }

        try context.save()
        return createdCount
    }

    func deleteTransactionsBefore(date: Date) async throws -> Int {
        let context = ModelContext(modelContainer)

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.date < date }
        )

        let transactions = try context.fetch(descriptor)
        let deleteCount = transactions.count

        // Reverse balance changes
        for transaction in transactions {
            if let account = transaction.account {
                updateAccountBalance(account: account, amount: transaction.amount, type: transaction.type, isAdding: false)
            }
            if transaction.type == .transfer, let toAccount = transaction.transferToAccount {
                toAccount.balance -= transaction.amount
                toAccount.modifiedAt = Date()
            }
            context.delete(transaction)
        }

        try context.save()
        return deleteCount
    }

    // MARK: - Analytics

    func calculateTotalsByType(startDate: Date, endDate: Date) async throws -> [TransactionType: Decimal] {
        let context = ModelContext(modelContainer)

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.date >= startDate && transaction.date <= endDate
            }
        )

        let transactions = try context.fetch(descriptor)

        var totals: [TransactionType: Decimal] = [
            .income: 0,
            .expense: 0,
            .transfer: 0
        ]

        for transaction in transactions {
            totals[transaction.type, default: 0] += transaction.amount
        }

        return totals
    }

    func calculateCategoryTotals(startDate: Date, endDate: Date, type: TransactionType) async throws -> [String: Decimal] {
        let context = ModelContext(modelContainer)

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.date >= startDate &&
                transaction.date <= endDate &&
                transaction.type == type
            }
        )

        let transactions = try context.fetch(descriptor)

        var categoryTotals: [String: Decimal] = [:]
        for transaction in transactions {
            categoryTotals[transaction.category, default: 0] += transaction.amount
        }

        return categoryTotals
    }

    func calculateAccountBalance(accountID: UUID, upToDate: Date) async throws -> Decimal {
        let context = ModelContext(modelContainer)

        let accountDescriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.id == accountID }
        )
        // Verify account exists
        guard try context.fetch(accountDescriptor).first != nil else {
            throw TransactionManagerError.accountNotFound
        }

        let transactionDescriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.account?.id == accountID && transaction.date <= upToDate
            }
        )

        let transactions = try context.fetch(transactionDescriptor)

        var balance: Decimal = 0
        for transaction in transactions {
            switch transaction.type {
            case .income:
                balance += transaction.amount
            case .expense:
                balance -= transaction.amount
            case .transfer:
                // Check if this is source or destination
                if transaction.account?.id == accountID {
                    balance -= transaction.amount
                }
                if transaction.transferToAccount?.id == accountID {
                    balance += transaction.amount
                }
            }
        }

        return balance
    }

    // MARK: - Helper Methods

    private func updateAccountBalance(account: Account, amount: Decimal, type: TransactionType, isAdding: Bool) {
        switch type {
        case .income:
            account.balance += isAdding ? amount : -amount
        case .expense:
            account.balance -= isAdding ? amount : -amount
        case .transfer:
            // For transfers, subtract from source account
            // Destination is handled separately in createTransaction
            account.balance -= isAdding ? amount : -amount
        }
        account.modifiedAt = Date()
    }

    // MARK: - Validation

    func validateTransfer(fromAccountID: UUID, toAccountID: UUID, amount: Decimal) async throws -> Bool {
        let context = ModelContext(modelContainer)

        // Fetch accounts
        let fromDescriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.id == fromAccountID }
        )
        let toDescriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.id == toAccountID }
        )

        guard let fromAccount = try context.fetch(fromDescriptor).first else {
            throw TransactionManagerError.accountNotFound
        }
        guard try context.fetch(toDescriptor).first != nil else {
            throw TransactionManagerError.accountNotFound
        }

        // Check if source account has sufficient funds
        // Note: We allow negative balances for credit cards, so this is optional
        if fromAccount.type != .creditCard && fromAccount.balance < amount {
            throw TransactionManagerError.insufficientFunds
        }

        return true
    }
}

// MARK: - Error Types

enum TransactionManagerError: LocalizedError {
    case accountNotFound
    case insufficientFunds
    case invalidTransactionType
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .accountNotFound:
            return "The specified account could not be found."
        case .insufficientFunds:
            return "Insufficient funds in the source account."
        case .invalidTransactionType:
            return "Invalid transaction type specified."
        case .saveFailed:
            return "Failed to save the transaction."
        }
    }
}
