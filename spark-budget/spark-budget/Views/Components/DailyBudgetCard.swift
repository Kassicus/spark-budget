//
//  DailyBudgetCard.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import SwiftUI
import SwiftData

struct DailyBudgetCard: View {
    @Query private var accounts: [Account]
    @Query private var settings: [UserSettings]

    var body: some View {
        let primaryAccount = accounts.first { $0.isPrimary }
        let userSettings = settings.first

        if let account = primaryAccount, let settings = userSettings {
            let daysUntilPayday = calculateDaysUntilPayday(settings: settings)
            let dailyBudget = daysUntilPayday > 0 ? account.balance / Decimal(daysUntilPayday) : 0

            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Budget")
                            .font(.headline)
                        Text(account.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "calendar.badge.clock")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                // Daily budget amount
                HStack(alignment: .firstTextBaseline) {
                    Text(formatCurrency(dailyBudget))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    Text("/day")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                // Days until payday
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                    Text("\(daysUntilPayday) days until payday")
                        .font(.subheadline)
                }

                // Account balance
                HStack {
                    Image(systemName: "banknote")
                        .foregroundStyle(.green)
                    Text("Available: \(account.formattedBalance)")
                        .font(.subheadline)
                }

                // Progress indicator
                if daysUntilPayday > 0 {
                    let paydayFrequency = settings.paydayFrequency
                    let totalDays = paydayFrequency.daysUntilNextPayday
                    let progress = 1.0 - (Double(daysUntilPayday) / Double(totalDays))

                    VStack(alignment: .leading, spacing: 4) {
                        ProgressView(value: progress)
                            .tint(.blue)

                        HStack {
                            Text("Last Payday")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("Next Payday")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
        } else {
            setupPrompt
        }
    }

    private var setupPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.blue)

            Text("Set Up Daily Budget")
                .font(.headline)

            Text("Mark an account as primary and configure your payday settings to track your daily budget.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }

    private func calculateDaysUntilPayday(settings: UserSettings) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextPayday = calendar.startOfDay(for: settings.nextPayday(from: today))

        let components = calendar.dateComponents([.day], from: today, to: nextPayday)
        return max(components.day ?? 0, 0)
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0"
    }
}

// Settings configuration view
struct PaydaySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [UserSettings]
    @Query private var accounts: [Account]

    @State private var selectedPayday = Date()
    @State private var selectedFrequency = PaydayFrequency.biweekly
    @State private var selectedAccountID: UUID?

    // Enhanced configuration
    @State private var selectedWeekday = 6 // Default to Friday
    @State private var semiMonthlyFirstDay = 1
    @State private var semiMonthlySecondDay = 15

    let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Primary Account") {
                    Picker("Account", selection: $selectedAccountID) {
                        Text("Select Account").tag(nil as UUID?)
                        ForEach(accounts) { account in
                            HStack {
                                Circle()
                                    .fill(account.color)
                                    .frame(width: 10, height: 10)
                                Text(account.name)
                            }
                            .tag(account.id as UUID?)
                        }
                    }

                    Text("This account will be used for daily budget calculations")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Payday Frequency") {
                    Picker("Frequency", selection: $selectedFrequency) {
                        ForEach(PaydayFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }

                // Configuration based on frequency
                if selectedFrequency == .weekly || selectedFrequency == .biweekly {
                    Section("Day of Week") {
                        Picker("Payday falls on", selection: $selectedWeekday) {
                            ForEach(1...7, id: \.self) { day in
                                Text(weekdays[day - 1]).tag(day)
                            }
                        }

                        DatePicker("Starting from", selection: $selectedPayday, displayedComponents: .date)
                            .onChange(of: selectedPayday) { oldValue, newValue in
                                // Automatically set weekday based on selected date
                                let calendar = Calendar.current
                                selectedWeekday = calendar.component(.weekday, from: newValue)
                            }

                        Text(selectedFrequency == .weekly ?
                            "You'll be paid every \(weekdays[selectedWeekday - 1])" :
                            "You'll be paid every other \(weekdays[selectedWeekday - 1]) starting from the date above")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if selectedFrequency == .semimonthly {
                    Section("Days of Month") {
                        Picker("First payday", selection: $semiMonthlyFirstDay) {
                            ForEach(1...28, id: \.self) { day in
                                Text("\(day)\(daySuffix(day))").tag(day)
                            }
                        }

                        Picker("Second payday", selection: $semiMonthlySecondDay) {
                            ForEach(1...28, id: \.self) { day in
                                Text("\(day)\(daySuffix(day))").tag(day)
                            }
                        }

                        Text("You'll be paid on the \(semiMonthlyFirstDay)\(daySuffix(semiMonthlyFirstDay)) and \(semiMonthlySecondDay)\(daySuffix(semiMonthlySecondDay)) of each month")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if selectedFrequency == .monthly {
                    Section("Day of Month") {
                        DatePicker("Payday", selection: $selectedPayday, displayedComponents: .date)

                        let calendar = Calendar.current
                        let day = calendar.component(.day, from: selectedPayday)
                        Text("You'll be paid on the \(day)\(daySuffix(day)) of each month")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text("Your daily budget will be calculated by dividing your primary account balance by the number of days until your next payday.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Payday Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                    }
                }
            }
            .onAppear {
                if let existing = settings.first {
                    selectedPayday = existing.payday
                    selectedFrequency = existing.paydayFrequency
                    selectedWeekday = existing.paydayWeekday ?? 6
                    semiMonthlyFirstDay = existing.semiMonthlyFirstDay ?? 1
                    semiMonthlySecondDay = existing.semiMonthlySecondDay ?? 15
                } else {
                    // Set weekday based on initial payday date
                    let calendar = Calendar.current
                    selectedWeekday = calendar.component(.weekday, from: selectedPayday)
                }
                selectedAccountID = accounts.first { $0.isPrimary }?.id
            }
        }
    }

    private func daySuffix(_ day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }

    private func saveSettings() {
        // Update primary account
        if let accountID = selectedAccountID {
            for account in accounts {
                account.isPrimary = (account.id == accountID)
            }
        }

        // Update or create settings
        if let existing = settings.first {
            existing.payday = selectedPayday
            existing.paydayFrequency = selectedFrequency
            existing.paydayWeekday = (selectedFrequency == .weekly || selectedFrequency == .biweekly) ? selectedWeekday : nil
            existing.semiMonthlyFirstDay = selectedFrequency == .semimonthly ? semiMonthlyFirstDay : nil
            existing.semiMonthlySecondDay = selectedFrequency == .semimonthly ? semiMonthlySecondDay : nil
            existing.modifiedAt = Date()
        } else {
            let newSettings = UserSettings(
                payday: selectedPayday,
                paydayFrequency: selectedFrequency,
                paydayWeekday: (selectedFrequency == .weekly || selectedFrequency == .biweekly) ? selectedWeekday : nil,
                semiMonthlyFirstDay: selectedFrequency == .semimonthly ? semiMonthlyFirstDay : nil,
                semiMonthlySecondDay: selectedFrequency == .semimonthly ? semiMonthlySecondDay : nil
            )
            modelContext.insert(newSettings)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving settings: \(error)")
        }
    }
}

#Preview("With Settings") {
    let container = try! ModelContainer(for: Account.self, UserSettings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)

    let account = Account(name: "Checking", type: .checking, balance: 1200, isPrimary: true)
    context.insert(account)

    let settings = UserSettings(
        payday: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
        paydayFrequency: .biweekly
    )
    context.insert(settings)

    return DailyBudgetCard()
        .modelContainer(container)
        .padding()
}

#Preview("No Settings") {
    DailyBudgetCard()
        .modelContainer(for: [Account.self, UserSettings.self], inMemory: true)
        .padding()
}
