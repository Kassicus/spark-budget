//
//  BillsListView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import SwiftUI
import SwiftData

struct BillsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bill.dueDate) private var bills: [Bill]

    var body: some View {
        NavigationStack {
            List {
                ForEach(bills) { bill in
                    Text(bill.title)
                }
            }
            .navigationTitle("Bills")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Add new bill
                    }) {
                        Label("Add Bill", systemImage: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    BillsListView()
        .modelContainer(for: Bill.self, inMemory: true)
}
