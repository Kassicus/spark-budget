//
//  AccountCard.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import SwiftUI
import UIKit

struct AccountCard: View {
    let account: Account

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: account.type.iconName)
                    .foregroundColor(account.color)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.headline)

                    if account.accountNumber != nil {
                        Text(account.displayAccountNumber)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(account.formattedBalance)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(account.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if account.isPrimary {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("Primary Account")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.name), \(account.type.rawValue)\(account.isPrimary ? ", Primary account" : ""), Balance: \(account.formattedBalance)")
        .accessibilityHint("Double tap to view account details")
    }
}

#Preview {
    let account = Account(
        name: "Chase Checking",
        type: .checking,
        balance: 1234.56,
        isPrimary: true,
        accountNumber: "1234"
    )

    return AccountCard(account: account)
        .padding()
}
