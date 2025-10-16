//
//  TransactionRowView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Transaction type icon
            Image(systemName: transaction.type.iconName)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())

            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.displayDescription)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    // Category
                    Text(transaction.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Separator
                    if let payee = transaction.payee, !payee.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(payee)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Account info
                if let account = transaction.account {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(account.color)
                            .frame(width: 6, height: 6)
                        Text(account.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        // Show transfer destination if applicable
                        if transaction.type == .transfer, let toAccount = transaction.transferToAccount {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Circle()
                                .fill(toAccount.color)
                                .frame(width: 6, height: 6)
                            Text(toAccount.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Amount and date
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.formattedAmount)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(amountColor)

                Text(transaction.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view transaction details")
    }

    private var accessibilityDescription: String {
        var description = "\(transaction.type.rawValue), \(transaction.displayDescription), \(transaction.formattedAmount)"

        if let account = transaction.account {
            description += ", from \(account.name)"
        }

        if transaction.type == .transfer, let toAccount = transaction.transferToAccount {
            description += " to \(toAccount.name)"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        description += ", \(dateFormatter.string(from: transaction.date))"

        return description
    }

    private var iconColor: Color {
        switch transaction.type {
        case .income:
            return .green
        case .expense:
            return .red
        case .transfer:
            return .blue
        }
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income:
            return .green
        case .expense:
            return .red
        case .transfer:
            return .primary
        }
    }
}

#Preview("Income Transaction") {
    let account = Account(name: "Checking", type: .checking, balance: 1000)
    let transaction = Transaction(
        amount: 2500.00,
        date: Date(),
        description: "Monthly Salary",
        category: "Salary",
        type: .income,
        payee: "ACME Corp",
        account: account
    )

    return List {
        TransactionRowView(transaction: transaction)
    }
}

#Preview("Expense Transaction") {
    let account = Account(name: "Credit Card", type: .creditCard, balance: -350)
    let transaction = Transaction(
        amount: 45.99,
        date: Date(),
        description: "Grocery Shopping",
        category: "Groceries",
        type: .expense,
        payee: "Whole Foods",
        account: account
    )

    return List {
        TransactionRowView(transaction: transaction)
    }
}

#Preview("Transfer Transaction") {
    let fromAccount = Account(name: "Checking", type: .checking, balance: 1000)
    let toAccount = Account(name: "Savings", type: .savings, balance: 5000)
    let transaction = Transaction(
        amount: 500.00,
        date: Date(),
        description: "Monthly Savings",
        category: "Transfer",
        type: .transfer,
        account: fromAccount,
        transferToAccount: toAccount
    )

    return List {
        TransactionRowView(transaction: transaction)
    }
}
