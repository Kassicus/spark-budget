//
//  AnalyticsView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]

    @State private var viewModel = AnalyticsViewModel()
    @State private var showDatePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    periodSelector

                    // Summary Cards
                    summaryCards

                    // Income vs Expenses Chart
                    incomeExpensesChart

                    // Category Breakdown
                    categoryBreakdown

                    // Monthly Trends
                    monthlyTrendsChart
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .onAppear {
                viewModel.calculateAnalytics(transactions: transactions)
            }
            .onChange(of: viewModel.selectedPeriod) { oldValue, newValue in
                viewModel.updatePeriod(newValue)
                viewModel.calculateAnalytics(transactions: transactions)
            }
            .sheet(isPresented: $showDatePicker) {
                DateRangePickerView(
                    startDate: $viewModel.startDate,
                    endDate: $viewModel.endDate
                ) {
                    viewModel.calculateAnalytics(transactions: transactions)
                }
            }
        }
    }

    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimePeriod.allCases.filter { $0 != .custom }, id: \.self) { period in
                    Button {
                        viewModel.selectedPeriod = period
                    } label: {
                        Text(period.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedPeriod == period ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundStyle(viewModel.selectedPeriod == period ? .white : .primary)
                            .cornerRadius(8)
                    }
                }

                Button {
                    showDatePicker = true
                } label: {
                    Label("Custom", systemImage: "calendar")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewModel.selectedPeriod == .custom ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundStyle(viewModel.selectedPeriod == .custom ? .white : .primary)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Income",
                    amount: viewModel.formatCurrency(viewModel.totalIncome),
                    icon: "arrow.down.circle.fill",
                    color: .green
                )

                SummaryCard(
                    title: "Expenses",
                    amount: viewModel.formatCurrency(viewModel.totalExpenses),
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
            }

            HStack(spacing: 12) {
                SummaryCard(
                    title: "Net Cash Flow",
                    amount: viewModel.formatCurrency(viewModel.netCashFlow),
                    icon: "chart.line.uptrend.xyaxis",
                    color: viewModel.netCashFlow >= 0 ? .green : .red
                )

                SummaryCard(
                    title: "Savings Rate",
                    amount: String(format: "%.1f%%", viewModel.savingsRate),
                    icon: "percent",
                    color: .blue
                )
            }
        }
    }

    private var incomeExpensesChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income vs Expenses")
                .font(.headline)

            Chart {
                BarMark(
                    x: .value("Type", "Income"),
                    y: .value("Amount", Double(truncating: viewModel.totalIncome as NSDecimalNumber))
                )
                .foregroundStyle(.green)

                BarMark(
                    x: .value("Type", "Expenses"),
                    y: .value("Amount", Double(truncating: viewModel.totalExpenses as NSDecimalNumber))
                )
                .foregroundStyle(.red)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Spending Categories")
                .font(.headline)

            if viewModel.categoryBreakdown.isEmpty {
                Text("No spending data available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(viewModel.getTopCategories(), id: \.category) { item in
                    BarMark(
                        x: .value("Amount", Double(truncating: item.amount as NSDecimalNumber)),
                        y: .value("Category", item.category)
                    )
                    .foregroundStyle(.blue.gradient)
                }
                .frame(height: CGFloat(viewModel.getTopCategories().count) * 40 + 40)
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var monthlyTrendsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Trends")
                .font(.headline)

            let trends = viewModel.calculateMonthlyTrends(transactions: transactions)

            Chart(trends) { month in
                BarMark(
                    x: .value("Month", month.month),
                    y: .value("Income", Double(truncating: month.income as NSDecimalNumber))
                )
                .foregroundStyle(.green)
                .position(by: .value("Type", "Income"))

                BarMark(
                    x: .value("Month", month.month),
                    y: .value("Expenses", Double(truncating: month.expenses as NSDecimalNumber))
                )
                .foregroundStyle(.red)
                .position(by: .value("Type", "Expenses"))
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// Summary Card Component
struct SummaryCard: View {
    let title: String
    let amount: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(amount)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// Date Range Picker
struct DateRangePickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var startDate: Date
    @Binding var endDate: Date
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Transaction.self, Account.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)

    let checking = Account(name: "Checking", type: .checking, balance: 2500)
    context.insert(checking)

    // Create sample transactions
    let transactions = [
        Transaction(amount: 2500, date: Date(), description: "Salary", category: "Salary", type: .income, account: checking),
        Transaction(amount: 1500, date: Date(), description: "Rent", category: "Rent/Mortgage", type: .expense, account: checking),
        Transaction(amount: 150, date: Date(), description: "Groceries", category: "Groceries", type: .expense, account: checking),
        Transaction(amount: 80, date: Date(), description: "Gas", category: "Transportation", type: .expense, account: checking),
        Transaction(amount: 45, date: Date(), description: "Dinner", category: "Food & Dining", type: .expense, account: checking)
    ]

    transactions.forEach { context.insert($0) }

    return AnalyticsView()
        .modelContainer(container)
}
