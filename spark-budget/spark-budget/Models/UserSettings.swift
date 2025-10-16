//
//  UserSettings.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import Foundation
import SwiftData
import SwiftUI
import UIKit

@Model
final class UserSettings {
    var id: UUID
    var payday: Date
    var paydayFrequency: PaydayFrequency

    // Enhanced payday configuration
    var paydayWeekday: Int? // For weekly/biweekly: 1=Sunday, 2=Monday, etc.
    var semiMonthlyFirstDay: Int? // For semi-monthly: first day of month (e.g., 1)
    var semiMonthlySecondDay: Int? // For semi-monthly: second day of month (e.g., 15)

    var accentColorData: Data?
    var notificationsEnabled: Bool
    var useBiometricAuth: Bool
    var currencyCode: String
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        payday: Date = Date(),
        paydayFrequency: PaydayFrequency = .biweekly,
        paydayWeekday: Int? = nil,
        semiMonthlyFirstDay: Int? = 1,
        semiMonthlySecondDay: Int? = 15,
        accentColor: Color? = nil,
        notificationsEnabled: Bool = true,
        useBiometricAuth: Bool = false,
        currencyCode: String = "USD",
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.payday = payday
        self.paydayFrequency = paydayFrequency
        self.paydayWeekday = paydayWeekday
        self.semiMonthlyFirstDay = semiMonthlyFirstDay
        self.semiMonthlySecondDay = semiMonthlySecondDay
        self.notificationsEnabled = notificationsEnabled
        self.useBiometricAuth = useBiometricAuth
        self.currencyCode = currencyCode
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt

        // Encode accent color to Data if provided
        if let color = accentColor {
            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false) {
                self.accentColorData = colorData
            }
        }
    }
}

// Extension with computed properties (not part of @Model)
extension UserSettings {
    var accentColor: Color {
        get {
            guard let colorData = accentColorData,
                  let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) else {
                return Color.blue // Default accent color
            }
            return Color(uiColor)
        }
        set {
            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(newValue), requiringSecureCoding: false) {
                self.accentColorData = colorData
            }
        }
    }

    var nextPayday: Date {
        return paydayFrequency.nextPayday(from: payday)
    }

    var daysUntilPayday: Int {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let next = calendar.startOfDay(for: nextPayday)
        let components = calendar.dateComponents([.day], from: now, to: next)
        return max(components.day ?? 0, 1) // Always at least 1 day
    }

    func dailyBudget(primaryAccountBalance: Decimal) -> Decimal {
        let days = Decimal(daysUntilPayday)
        return days > 0 ? primaryAccountBalance / days : 0
    }

    var formattedNextPayday: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: nextPayday)
    }

    // Helper to get weekday name
    var paydayWeekdayName: String? {
        guard let weekday = paydayWeekday else { return nil }
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[weekday - 1]
    }

    // Helper to check if a given date is a payday
    func isPayday(date: Date) -> Bool {
        let calendar = Calendar.current

        switch paydayFrequency {
        case .weekly:
            // Check if the weekday matches
            if let targetWeekday = paydayWeekday {
                let dateWeekday = calendar.component(.weekday, from: date)
                return dateWeekday == targetWeekday
            }
            return false

        case .biweekly:
            // Check if the weekday matches and it's the right week
            if let targetWeekday = paydayWeekday {
                let dateWeekday = calendar.component(.weekday, from: date)
                guard dateWeekday == targetWeekday else { return false }

                // Check if this is the correct biweekly cycle
                // Calculate absolute days between the reference payday and the date
                let daysBetween = abs(calendar.dateComponents([.day], from: calendar.startOfDay(for: payday), to: calendar.startOfDay(for: date)).day ?? 0)
                return daysBetween % 14 == 0
            }
            return false

        case .semimonthly:
            // Check if the day of month matches either configured day
            let dayOfMonth = calendar.component(.day, from: date)
            let firstDay = semiMonthlyFirstDay ?? 1
            let secondDay = semiMonthlySecondDay ?? 15
            return dayOfMonth == firstDay || dayOfMonth == secondDay

        case .monthly:
            // Check if the day of month matches the payday
            let paydayDay = calendar.component(.day, from: payday)
            let dateDay = calendar.component(.day, from: date)
            return paydayDay == dateDay
        }
    }

    // Calculate next payday from a given date
    func nextPayday(from date: Date) -> Date {
        let calendar = Calendar.current

        switch paydayFrequency {
        case .weekly:
            if let targetWeekday = paydayWeekday {
                // Find the next occurrence of the target weekday
                var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
                components.weekday = targetWeekday
                if let nextDate = calendar.date(from: components), nextDate > date {
                    return nextDate
                } else {
                    // Move to next week
                    components.weekOfYear = (components.weekOfYear ?? 0) + 1
                    return calendar.date(from: components) ?? date
                }
            }
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date

        case .biweekly:
            if let targetWeekday = paydayWeekday {
                // Find the next occurrence of the target weekday that's on the 14-day cycle
                let today = calendar.startOfDay(for: date)
                let referencePayday = calendar.startOfDay(for: payday)

                // Find the next occurrence of the target weekday
                var candidateDate = today
                for _ in 0..<14 {
                    candidateDate = calendar.date(byAdding: .day, value: 1, to: candidateDate) ?? candidateDate
                    if calendar.component(.weekday, from: candidateDate) == targetWeekday {
                        // Check if it's on the correct biweekly cycle
                        let daysBetween = abs(calendar.dateComponents([.day], from: referencePayday, to: candidateDate).day ?? 0)
                        if daysBetween % 14 == 0 {
                            return candidateDate
                        }
                    }
                }
            }
            return calendar.date(byAdding: .day, value: 14, to: date) ?? date

        case .semimonthly:
            let currentDay = calendar.component(.day, from: date)
            let firstDay = semiMonthlyFirstDay ?? 1
            let secondDay = semiMonthlySecondDay ?? 15

            // If we're before the first day, return first day of current month
            if currentDay < firstDay {
                var components = calendar.dateComponents([.year, .month], from: date)
                components.day = firstDay
                return calendar.date(from: components) ?? date
            }
            // If we're between first and second day, return second day
            else if currentDay < secondDay {
                var components = calendar.dateComponents([.year, .month], from: date)
                components.day = secondDay
                return calendar.date(from: components) ?? date
            }
            // Otherwise, return first day of next month
            else {
                var components = calendar.dateComponents([.year, .month], from: date)
                components.month = (components.month ?? 0) + 1
                components.day = firstDay
                return calendar.date(from: components) ?? date
            }

        case .monthly:
            let paydayDay = calendar.component(.day, from: payday)
            let currentDay = calendar.component(.day, from: date)

            // If we haven't reached payday this month, return it
            if currentDay < paydayDay {
                var components = calendar.dateComponents([.year, .month], from: date)
                components.day = paydayDay
                return calendar.date(from: components) ?? date
            }
            // Otherwise, return payday of next month
            else {
                return calendar.date(byAdding: .month, value: 1, to: payday) ?? payday
            }
        }
    }
}
