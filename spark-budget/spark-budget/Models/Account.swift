//
//  Account.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import Foundation
import SwiftData
import SwiftUI
import UIKit

@Model
final class Account {
    var id: UUID
    var name: String
    var type: AccountType
    var balance: Decimal
    var isPrimary: Bool
    var colorData: Data?
    var accountNumber: String?
    var createdAt: Date
    var modifiedAt: Date

    @Relationship(deleteRule: .cascade)
    var transactions: [Transaction]?

    @Relationship(deleteRule: .nullify)
    var bills: [Bill]?

    init(
        id: UUID = UUID(),
        name: String,
        type: AccountType,
        balance: Decimal = 0,
        isPrimary: Bool = false,
        color: Color? = nil,
        accountNumber: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.isPrimary = isPrimary
        self.accountNumber = accountNumber
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt

        // Encode color to Data if provided
        if let color = color {
            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false) {
                self.colorData = colorData
            }
        }
    }
}

// Extension with computed properties (not part of @Model)
extension Account {
    var color: Color {
        get {
            guard let colorData = colorData,
                  let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) else {
                return Color.blue // Default color
            }
            return Color(uiColor)
        }
        set {
            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(newValue), requiringSecureCoding: false) {
                self.colorData = colorData
            }
        }
    }

    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: balance as NSDecimalNumber) ?? "$0.00"
    }

    var displayAccountNumber: String {
        guard let accountNumber = accountNumber else { return "" }
        return "••••\(accountNumber.suffix(4))"
    }
}
