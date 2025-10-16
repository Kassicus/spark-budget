//
//  AnalyticsViewModel.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import Foundation
import SwiftData
import Observation

@Observable
final class AnalyticsViewModel {
    var startDate: Date
    var endDate: Date
    var selectedPeriod: TimePeriod = .thisMonth

    // Cached data
    var totalIncome: Decimal = 0
    var totalExpenses: Decimal = 0
    var categoryBreakdown: [String: Decimal] = [:]
    var dailySpending: [Date: Decimal] = [:]
    var monthlyTrends: [MonthData] = []

    init() {
        // Default to current month
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        self.startDate = monthStart
        self.endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
    }

    func updatePeriod(_ period: TimePeriod) {
        selectedPeriod = period
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .thisWeek:
            startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            endDate = calendar.date(byAdding: .day, value: 6, to: startDate)!

        case .thisMonth:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate)!

        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonth))!
            endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate)!

        case .last3Months:
            startDate = calendar.date(byAdding: .month, value: -3, to: now)!
            endDate = now

        case .thisYear:
            startDate = calendar.date(from: calendar.dateComponents([.year], from: now))!
            endDate = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startDate)!

        case .custom:
            // Keep existing dates for custom
            break
        }
    }

    func calculateAnalytics(transactions: [Transaction]) {
        // Reset values
        totalIncome = 0
        totalExpenses = 0
        categoryBreakdown.removeAll()
        dailySpending.removeAll()

        // Filter transactions by date range
        let filteredTransactions = transactions.filter { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }

        for transaction in filteredTransactions {
            switch transaction.type {
            case .income:
                totalIncome += transaction.amount

            case .expense:
                totalExpenses += transaction.amount

                // Add to category breakdown
                let category = transaction.category
                categoryBreakdown[category, default: 0] += transaction.amount

                // Add to daily spending
                let day = Calendar.current.startOfDay(for: transaction.date)
                dailySpending[day, default: 0] += transaction.amount

            case .transfer:
                // Transfers don't count in income/expense totals
                break
            }
        }
    }

    func calculateMonthlyTrends(transactions: [Transaction], months: Int = 6) -> [MonthData] {
        let calendar = Calendar.current
        var trends: [MonthData] = []

        for i in (0..<months).reversed() {
            let monthStart = calendar.date(byAdding: .month, value: -i, to: startDate)!
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!

            let monthTransactions = transactions.filter { transaction in
                transaction.date >= monthStart && transaction.date <= monthEnd
            }

            var income: Decimal = 0
            var expenses: Decimal = 0

            for transaction in monthTransactions {
                switch transaction.type {
                case .income:
                    income += transaction.amount
                case .expense:
                    expenses += transaction.amount
                case .transfer:
                    break
                }
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            let monthName = formatter.string(from: monthStart)

            trends.append(MonthData(
                month: monthName,
                income: income,
                expenses: expenses,
                date: monthStart
            ))
        }

        return trends
    }

    func getTopCategories(limit: Int = 5) -> [(category: String, amount: Decimal)] {
        let sorted = categoryBreakdown.sorted { $0.value > $1.value }
        return Array(sorted.prefix(limit)).map { ($0.key, $0.value) }
    }

    var netCashFlow: Decimal {
        totalIncome - totalExpenses
    }

    var savingsRate: Double {
        guard totalIncome > 0 else { return 0 }
        return Double(truncating: (netCashFlow / totalIncome * 100) as NSDecimalNumber)
    }

    var averageDailySpending: Decimal {
        guard !dailySpending.isEmpty else { return 0 }
        let total = dailySpending.values.reduce(0, +)
        return total / Decimal(dailySpending.count)
    }

    func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Supporting Types

enum TimePeriod: String, CaseIterable {
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case last3Months = "Last 3 Months"
    case thisYear = "This Year"
    case custom = "Custom"
}

struct MonthData: Identifiable {
    let id = UUID()
    let month: String
    let income: Decimal
    let expenses: Decimal
    let date: Date

    var net: Decimal {
        income - expenses
    }
}

struct CategoryData: Identifiable {
    let id = UUID()
    let category: String
    let amount: Decimal
    let percentage: Double
}

struct DailySpendingData: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Decimal
}
