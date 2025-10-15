//
//  TransactionsListView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import SwiftUI
import SwiftData

struct TransactionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    var body: some View {
        NavigationStack {
            List {
                ForEach(transactions) { transaction in
                    Text(transaction.desc)
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Add new transaction
                    }) {
                        Label("Add Transaction", systemImage: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    TransactionsListView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
