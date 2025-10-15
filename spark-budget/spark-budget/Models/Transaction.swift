//
//  Transaction.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var amount: Decimal
    var date: Date
    var desc: String // 'description' is reserved in SwiftData
    var category: String
    var type: TransactionType
    var payee: String?
    var notes: String?
    var receiptPhotoData: Data?
    var createdAt: Date
    var modifiedAt: Date

    @Relationship(inverse: \Account.transactions)
    var account: Account?

    // For transfers - the account money is being transferred TO
    @Relationship
    var transferToAccount: Account?

    init(
        id: UUID = UUID(),
        amount: Decimal,
        date: Date = Date(),
        description: String,
        category: String,
        type: TransactionType,
        payee: String? = nil,
        notes: String? = nil,
        receiptPhotoData: Data? = nil,
        account: Account? = nil,
        transferToAccount: Account? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.desc = description
        self.category = category
        self.type = type
        self.payee = payee
        self.notes = notes
        self.receiptPhotoData = receiptPhotoData
        self.account = account
        self.transferToAccount = transferToAccount
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// Extension with computed properties (not part of @Model)
extension Transaction {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let formattedValue = formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"

        // For expenses, show as negative
        if type == .expense {
            return "-\(formattedValue)"
        }
        return formattedValue
    }

    var amountWithSign: Decimal {
        return type == .expense ? -amount : amount
    }

    var displayDescription: String {
        if desc.isEmpty {
            return payee ?? "Transaction"
        }
        return desc
    }
}
