//
//  Enums.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum AccountType: String, Codable, CaseIterable {
    case checking = "Checking"
    case savings = "Savings"
    case creditCard = "Credit Card"
    case loan = "Loan"
    case cash = "Cash"

    var iconName: String {
        switch self {
        case .checking:
            return "banknote"
        case .savings:
            return "piggybank"
        case .creditCard:
            return "creditcard"
        case .loan:
            return "doc.text"
        case .cash:
            return "dollarsign.circle"
        }
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "Income"
    case expense = "Expense"
    case transfer = "Transfer"

    var iconName: String {
        switch self {
        case .income:
            return "arrow.down.circle.fill"
        case .expense:
            return "arrow.up.circle.fill"
        case .transfer:
            return "arrow.left.arrow.right.circle.fill"
        }
    }
}

enum RecurrenceType: String, Codable, CaseIterable {
    case oneTime = "One Time"
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"

    func nextDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .oneTime:
            return date
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .day, value: 14, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
}

enum PaydayFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case semimonthly = "Semi-monthly"
    case monthly = "Monthly"

    var daysUntilNextPayday: Int {
        switch self {
        case .weekly:
            return 7
        case .biweekly:
            return 14
        case .semimonthly:
            return 15
        case .monthly:
            return 30
        }
    }

    func nextPayday(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .day, value: 14, to: date) ?? date
        case .semimonthly:
            return calendar.date(byAdding: .day, value: 15, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
    }
}
