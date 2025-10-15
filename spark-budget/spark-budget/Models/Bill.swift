//
//  Bill.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import Foundation
import SwiftData

@Model
final class Bill {
    var id: UUID
    var title: String
    var category: String
    var amount: Decimal
    var dueDate: Date
    var recurrence: RecurrenceType
    var isPaid: Bool
    var lastPaidDate: Date?
    var notes: String?
    var createdAt: Date
    var modifiedAt: Date

    @Relationship(inverse: \Account.bills)
    var account: Account?

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        amount: Decimal,
        dueDate: Date,
        recurrence: RecurrenceType = .monthly,
        isPaid: Bool = false,
        lastPaidDate: Date? = nil,
        notes: String? = nil,
        account: Account? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.amount = amount
        self.dueDate = dueDate
        self.recurrence = recurrence
        self.isPaid = isPaid
        self.lastPaidDate = lastPaidDate
        self.notes = notes
        self.account = account
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// Extension with computed properties (not part of @Model)
extension Bill {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }

    var nextDueDate: Date {
        if recurrence == .oneTime {
            return dueDate
        }
        return recurrence.nextDate(from: dueDate)
    }

    var daysUntilDue: Int {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: dueDate)
        let components = calendar.dateComponents([.day], from: now, to: due)
        return components.day ?? 0
    }

    var isOverdue: Bool {
        return !isPaid && daysUntilDue < 0
    }

    var isDueSoon: Bool {
        return !isPaid && daysUntilDue >= 0 && daysUntilDue <= 7
    }
}
