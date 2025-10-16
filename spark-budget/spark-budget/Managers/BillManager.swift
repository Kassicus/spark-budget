//
//  BillManager.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import Foundation
import SwiftData

/// Actor-based bill manager for thread-safe bill operations
/// Handles bulk operations, recurring bill processing, and payment automation
actor BillManager {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Bill Operations

    func createBill(
        title: String,
        category: String,
        amount: Decimal,
        dueDate: Date,
        recurrence: RecurrenceType,
        notes: String? = nil,
        accountID: UUID
    ) async throws -> Bill {
        let context = ModelContext(modelContainer)

        // Fetch account
        let accountDescriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.id == accountID }
        )
        guard let account = try context.fetch(accountDescriptor).first else {
            throw BillManagerError.accountNotFound
        }

        let bill = Bill(
            title: title,
            category: category,
            amount: amount,
            dueDate: dueDate,
            recurrence: recurrence,
            notes: notes,
            account: account
        )

        context.insert(bill)
        try context.save()

        return bill
    }

    // MARK: - Payment Processing

    func payBill(
        billID: UUID,
        paymentDate: Date = Date(),
        createTransaction: Bool = true
    ) async throws -> Transaction? {
        let context = ModelContext(modelContainer)

        // Fetch bill
        let billDescriptor = FetchDescriptor<Bill>(
            predicate: #Predicate { $0.id == billID }
        )
        guard let bill = try context.fetch(billDescriptor).first else {
            throw BillManagerError.billNotFound
        }

        bill.isPaid = true
        bill.lastPaidDate = paymentDate
        bill.modifiedAt = Date()

        var transaction: Transaction? = nil

        // Create transaction if requested
        if createTransaction, let account = bill.account {
            transaction = Transaction(
                amount: bill.amount,
                date: paymentDate,
                description: bill.title,
                category: bill.category,
                type: .expense,
                notes: "Bill payment: \(bill.title)",
                account: account
            )

            context.insert(transaction!)

            // Update account balance
            account.balance -= bill.amount
            account.modifiedAt = Date()
        }

        // If recurring, create next occurrence
        if bill.recurrence != .oneTime {
            bill.dueDate = bill.recurrence.nextDate(from: bill.dueDate)
            bill.isPaid = false // Reset for next occurrence
        }

        try context.save()
        return transaction
    }

    // MARK: - Recurring Bill Processing

    func processRecurringBills() async throws -> Int {
        let context = ModelContext(modelContainer)

        // Find bills that are paid and recurring
        let oneTime = RecurrenceType.oneTime
        let descriptor = FetchDescriptor<Bill>(
            predicate: #Predicate { bill in
                bill.isPaid && bill.recurrence != oneTime
            }
        )

        let bills = try context.fetch(descriptor)
        var processedCount = 0

        for bill in bills {
            // Check if the next due date has passed
            if bill.dueDate < Date() {
                bill.dueDate = bill.recurrence.nextDate(from: bill.dueDate)
                bill.isPaid = false
                bill.modifiedAt = Date()
                processedCount += 1
            }
        }

        if processedCount > 0 {
            try context.save()
        }

        return processedCount
    }

    // MARK: - Analytics

    func calculateUpcomingBillsTotal(days: Int = 30) async throws -> Decimal {
        let context = ModelContext(modelContainer)

        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<Bill>(
            predicate: #Predicate { bill in
                !bill.isPaid && bill.dueDate <= endDate
            }
        )

        let bills = try context.fetch(descriptor)

        return bills.reduce(Decimal(0)) { $0 + $1.amount }
    }

    func getOverdueBills() async throws -> [Bill] {
        let context = ModelContext(modelContainer)

        let now = Date()
        let descriptor = FetchDescriptor<Bill>(
            predicate: #Predicate { bill in
                !bill.isPaid && bill.dueDate < now
            },
            sortBy: [SortDescriptor(\.dueDate)]
        )

        return try context.fetch(descriptor)
    }

    func getDueSoonBills(days: Int = 7) async throws -> [Bill] {
        let context = ModelContext(modelContainer)

        let today = Calendar.current.startOfDay(for: Date())
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today

        let descriptor = FetchDescriptor<Bill>(
            predicate: #Predicate { bill in
                !bill.isPaid && bill.dueDate >= today && bill.dueDate <= futureDate
            },
            sortBy: [SortDescriptor(\.dueDate)]
        )

        return try context.fetch(descriptor)
    }

    func calculateMonthlyRecurringTotal() async throws -> Decimal {
        let context = ModelContext(modelContainer)

        let monthly = RecurrenceType.monthly
        let descriptor = FetchDescriptor<Bill>(
            predicate: #Predicate { bill in
                bill.recurrence == monthly
            }
        )

        let bills = try context.fetch(descriptor)

        return bills.reduce(Decimal(0)) { $0 + $1.amount }
    }

    // MARK: - Bulk Operations

    func deleteOldPaidBills(olderThan days: Int) async throws -> Int {
        let context = ModelContext(modelContainer)

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let oneTime = RecurrenceType.oneTime

        let descriptor = FetchDescriptor<Bill>(
            predicate: #Predicate { bill in
                bill.isPaid &&
                bill.recurrence == oneTime &&
                bill.lastPaidDate != nil &&
                bill.lastPaidDate! < cutoffDate
            }
        )

        let bills = try context.fetch(descriptor)
        let deleteCount = bills.count

        for bill in bills {
            context.delete(bill)
        }

        if deleteCount > 0 {
            try context.save()
        }

        return deleteCount
    }
}

// MARK: - Error Types

enum BillManagerError: LocalizedError {
    case billNotFound
    case accountNotFound
    case paymentFailed
    case invalidRecurrence

    var errorDescription: String? {
        switch self {
        case .billNotFound:
            return "The specified bill could not be found."
        case .accountNotFound:
            return "The specified account could not be found."
        case .paymentFailed:
            return "Failed to process bill payment."
        case .invalidRecurrence:
            return "Invalid recurrence type specified."
        }
    }
}
