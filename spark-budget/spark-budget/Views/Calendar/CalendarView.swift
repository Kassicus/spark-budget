//
//  CalendarView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var bills: [Bill]
    @Query private var settings: [UserSettings]

    @State private var selectedDate = Date()
    @State private var selectedMonth = Date()
    @State private var showAnalytics = false
    @State private var showPaydaySettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month navigation
                monthNavigator

                // Calendar grid
                calendarGrid

                Divider()

                // Selected date details
                selectedDateDetails
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showPaydaySettings = true
                    } label: {
                        Label("Payday Settings", systemImage: "calendar.badge.clock")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAnalytics = true
                    } label: {
                        Label("Analytics", systemImage: "chart.bar.fill")
                    }
                }
            }
            .sheet(isPresented: $showAnalytics) {
                AnalyticsView()
            }
            .sheet(isPresented: $showPaydaySettings) {
                PaydaySettingsView()
            }
        }
    }

    private var monthNavigator: some View {
        HStack {
            Button {
                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth)!
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(selectedMonth, format: .dateTime.month(.wide).year())
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            Button {
                selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth)!
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
    }

    private var calendarGrid: some View {
        let calendar = Calendar.current
        let _ = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            // Weekday headers
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }

            // Calendar days
            ForEach(Array(daysInMonth(for: selectedMonth).enumerated()), id: \.offset) { index, date in
                if let date = date {
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        spending: dailySpending(for: date),
                        hasBills: hasRecurringBills(on: date),
                        isPayday: isPayday(date: date),
                        accentColor: settings.first?.accentColor ?? .blue
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                } else {
                    Color.clear
                        .frame(height: 60)
                }
            }
        }
        .padding(.horizontal)
    }

    private var selectedDateDetails: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Date header
                HStack {
                    Text(selectedDate, style: .date)
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    let spending = dailySpending(for: selectedDate)
                    if spending > 0 {
                        Text(formatCurrency(spending))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Payday indicator
                if isPayday(date: selectedDate) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Payday", systemImage: "dollarsign.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                            .padding(.horizontal)

                        if let userSettings = settings.first {
                            HStack {
                                Text("Next paycheck day")
                                    .font(.subheadline)
                                Spacer()
                                Text(userSettings.paydayFrequency.rawValue)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                // Bills due
                let dueBills = billsDue(on: selectedDate)
                if !dueBills.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Bills Due", systemImage: "doc.text.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                            .padding(.horizontal)

                        ForEach(dueBills) { bill in
                            BillRowView(bill: bill)
                                .padding(.horizontal)
                        }
                    }
                }

                // Transactions
                let dayTransactions = transactionsFor(date: selectedDate)
                if !dayTransactions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Transactions", systemImage: "dollarsign.circle.fill")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(dayTransactions) { transaction in
                            TransactionRowView(transaction: transaction)
                                .padding(.horizontal)
                        }
                    }
                }

                if dueBills.isEmpty && dayTransactions.isEmpty && !isPayday(date: selectedDate) {
                    ContentUnavailableView {
                        Label("No Activity", systemImage: "calendar")
                    } description: {
                        Text("No transactions or bills for this date")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func daysInMonth(for date: Date) -> [Date?] {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let monthRange = calendar.range(of: .day, in: .month, for: monthStart)!

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingEmptyDays = firstWeekday - calendar.firstWeekday
        let adjustedLeadingDays = leadingEmptyDays >= 0 ? leadingEmptyDays : leadingEmptyDays + 7

        var days: [Date?] = Array(repeating: nil, count: adjustedLeadingDays)

        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }

        return days
    }

    private func dailySpending(for date: Date) -> Decimal {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return transactions
            .filter { $0.date >= dayStart && $0.date < dayEnd && $0.type == .expense }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    private func hasRecurringBills(on date: Date) -> Bool {
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: date)

        return bills.contains { bill in
            let billDay = calendar.component(.day, from: bill.dueDate)
            return billDay == dayOfMonth
        }
    }

    private func billsDue(on date: Date) -> [Bill] {
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: date)

        // Return bills that match this day of month
        return bills.filter { bill in
            let billDay = calendar.component(.day, from: bill.dueDate)
            return billDay == dayOfMonth
        }
    }

    private func isPayday(date: Date) -> Bool {
        guard let userSettings = settings.first else { return false }
        return userSettings.isPayday(date: date)
    }

    private func transactionsFor(date: Date) -> [Transaction] {
        let calendar = Calendar.current
        return transactions.filter { transaction in
            calendar.isDate(transaction.date, inSameDayAs: date)
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

// Day Cell Component
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let spending: Decimal
    let hasBills: Bool
    let isPayday: Bool
    let accentColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(date, format: .dateTime.day())
                .font(.body)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)

            if spending > 0 || hasBills || isPayday {
                HStack(spacing: 2) {
                    if isPayday {
                        Circle()
                            .fill(.green)
                            .frame(width: 4, height: 4)
                    }
                    if spending > 0 {
                        Circle()
                            .fill(.red)
                            .frame(width: 4, height: 4)
                    }
                    if hasBills {
                        Circle()
                            .fill(.orange)
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? accentColor : isToday ? accentColor.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday && !isSelected ? accentColor : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    let container = try! ModelContainer(for: Transaction.self, Bill.self, Account.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)

    let checking = Account(name: "Checking", type: .checking, balance: 2500)
    context.insert(checking)

    // Add some sample data
    let transaction = Transaction(amount: 45.99, date: Date(), description: "Groceries", category: "Food", type: .expense, account: checking)
    context.insert(transaction)

    let bill = Bill(title: "Rent", category: "Rent/Mortgage", amount: 1500, dueDate: Date(), recurrence: .monthly, account: checking)
    context.insert(bill)

    return CalendarView()
        .modelContainer(container)
}
