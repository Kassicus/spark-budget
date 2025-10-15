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
}
