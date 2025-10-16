//
//  BillRowView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import SwiftUI

struct BillRowView: View {
    let bill: Bill

    var body: some View {
        HStack(spacing: 12) {
            // Bill status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: statusIcon)
                    .font(.system(size: 16))
                    .foregroundStyle(statusColor)
            }

            // Bill details
            VStack(alignment: .leading, spacing: 4) {
                Text(bill.title)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    // Category
                    Text(bill.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Separator
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Recurrence
                    Text(bill.recurrence.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Account info
                if let account = bill.account {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(account.color)
                            .frame(width: 6, height: 6)
                        Text(account.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Due date status
                if bill.isOverdue {
                    Label("Overdue", systemImage: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                } else if bill.isDueSoon {
                    Label("Due Soon", systemImage: "clock.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            // Amount and due date
            VStack(alignment: .trailing, spacing: 4) {
                Text(bill.formattedAmount)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor)

                Text(bill.dueDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if bill.isPaid {
                    Text("Paid")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        if bill.isPaid {
            return .green
        } else if bill.isOverdue {
            return .red
        } else if bill.isDueSoon {
            return .orange
        }
        return .blue
    }

    private var statusIcon: String {
        if bill.isPaid {
            return "checkmark.circle.fill"
        } else if bill.isOverdue {
            return "exclamationmark.triangle.fill"
        } else if bill.isDueSoon {
            return "clock.fill"
        }
        return "doc.text.fill"
    }
}

#Preview("Unpaid Bill") {
    let account = Account(name: "Checking", type: .checking, balance: 2500)
    let bill = Bill(
        title: "Rent",
        category: "Rent/Mortgage",
        amount: 1500.00,
        dueDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
        recurrence: .monthly,
        account: account
    )

    return List {
        BillRowView(bill: bill)
    }
}

#Preview("Due Soon") {
    let account = Account(name: "Checking", type: .checking, balance: 2500)
    let bill = Bill(
        title: "Internet",
        category: "Utilities",
        amount: 79.99,
        dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
        recurrence: .monthly,
        account: account
    )

    return List {
        BillRowView(bill: bill)
    }
}

#Preview("Overdue") {
    let account = Account(name: "Credit Card", type: .creditCard, balance: -1200)
    let bill = Bill(
        title: "Credit Card Payment",
        category: "Credit Card",
        amount: 350.00,
        dueDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
        recurrence: .monthly,
        account: account
    )

    return List {
        BillRowView(bill: bill)
    }
}

#Preview("Paid") {
    let account = Account(name: "Checking", type: .checking, balance: 2500)
    let bill = Bill(
        title: "Phone Bill",
        category: "Phone",
        amount: 85.00,
        dueDate: Date(),
        recurrence: .monthly,
        isPaid: true,
        lastPaidDate: Date(),
        account: account
    )

    return List {
        BillRowView(bill: bill)
    }
}
