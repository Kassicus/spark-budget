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
    @Query(sort: \Bill.dueDate) private var allBills: [Bill]

    @State private var showAddBill = false
    @State private var searchText = ""
    @State private var filterStatus: BillStatus? = nil
    @State private var showFilterSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if filteredBills.isEmpty {
                    ContentUnavailableView {
                        Label("No Bills", systemImage: "doc.text")
                    } description: {
                        Text("Add your first bill to get started tracking your recurring payments.")
                    } actions: {
                        Button("Add Bill") {
                            showAddBill = true
                        }
                    }
                } else {
                    List {
                        // Overdue bills
                        if !overdueBills.isEmpty {
                            Section {
                                ForEach(overdueBills) { bill in
                                    NavigationLink(destination: BillDetailView(bill: bill)) {
                                        BillRowView(bill: bill)
                                    }
                                }
                            } header: {
                                Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                            }
                        }

                        // Due Soon (within 7 days)
                        if !dueSoonBills.isEmpty {
                            Section {
                                ForEach(dueSoonBills) { bill in
                                    NavigationLink(destination: BillDetailView(bill: bill)) {
                                        BillRowView(bill: bill)
                                    }
                                }
                            } header: {
                                Label("Due Soon", systemImage: "clock.fill")
                                    .foregroundStyle(.orange)
                            }
                        }

                        // Upcoming (more than 7 days away)
                        if !upcomingBills.isEmpty {
                            Section {
                                ForEach(upcomingBills) { bill in
                                    NavigationLink(destination: BillDetailView(bill: bill)) {
                                        BillRowView(bill: bill)
                                    }
                                }
                            } header: {
                                Text("Upcoming")
                            }
                        }

                        // Paid bills
                        if !paidBills.isEmpty {
                            Section {
                                ForEach(paidBills) { bill in
                                    NavigationLink(destination: BillDetailView(bill: bill)) {
                                        BillRowView(bill: bill)
                                    }
                                }
                            } header: {
                                Text("Paid")
                            }
                        }
                    }
                    .refreshable {
                        await refreshBills()
                    }
                    .searchable(text: $searchText, prompt: "Search bills")
                }
            }
            .navigationTitle("Bills")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if filterStatus != nil {
                        Button {
                            showFilterSheet = true
                        } label: {
                            Label("Filters Active", systemImage: "line.3.horizontal.decrease.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    } else {
                        Button {
                            showFilterSheet = true
                        } label: {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddBill = true
                    } label: {
                        Label("Add Bill", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddBill) {
                AddEditBillView()
            }
            .sheet(isPresented: $showFilterSheet) {
                BillFilterSheet(filterStatus: $filterStatus)
            }
        }
    }

    private var filteredBills: [Bill] {
        var bills = allBills

        // Filter by search text
        if !searchText.isEmpty {
            bills = bills.filter { bill in
                bill.title.localizedCaseInsensitiveContains(searchText) ||
                bill.category.localizedCaseInsensitiveContains(searchText) ||
                (bill.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Filter by status
        if let filterStatus = filterStatus {
            switch filterStatus {
            case .overdue:
                bills = bills.filter { $0.isOverdue }
            case .dueSoon:
                bills = bills.filter { $0.isDueSoon }
            case .upcoming:
                bills = bills.filter { !$0.isPaid && !$0.isOverdue && !$0.isDueSoon }
            case .paid:
                bills = bills.filter { $0.isPaid }
            }
        }

        return bills
    }

    private var overdueBills: [Bill] {
        filteredBills.filter { $0.isOverdue }
    }

    private var dueSoonBills: [Bill] {
        filteredBills.filter { $0.isDueSoon }
    }

    private var upcomingBills: [Bill] {
        filteredBills.filter { !$0.isPaid && !$0.isOverdue && !$0.isDueSoon }
    }

    private var paidBills: [Bill] {
        filteredBills.filter { $0.isPaid }
    }

    private func refreshBills() async {
        // Simulate a brief refresh delay for smooth animation
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        // SwiftData automatically refreshes queries
    }
}

enum BillStatus {
    case overdue
    case dueSoon
    case upcoming
    case paid
}

struct BillFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var filterStatus: BillStatus?

    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Button {
                        filterStatus = nil
                        dismiss()
                    } label: {
                        HStack {
                            Text("All Bills")
                            Spacer()
                            if filterStatus == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)

                    Button {
                        filterStatus = .overdue
                        dismiss()
                    } label: {
                        HStack {
                            Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Spacer()
                            if filterStatus == .overdue {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)

                    Button {
                        filterStatus = .dueSoon
                        dismiss()
                    } label: {
                        HStack {
                            Label("Due Soon", systemImage: "clock.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            if filterStatus == .dueSoon {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)

                    Button {
                        filterStatus = .upcoming
                        dismiss()
                    } label: {
                        HStack {
                            Label("Upcoming", systemImage: "calendar")
                            Spacer()
                            if filterStatus == .upcoming {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)

                    Button {
                        filterStatus = .paid
                        dismiss()
                    } label: {
                        HStack {
                            Label("Paid", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Spacer()
                            if filterStatus == .paid {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Filter Bills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview("With Bills") {
    let container = try! ModelContainer(for: Bill.self, Account.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)

    let checking = Account(name: "Checking", type: .checking, balance: 2500)
    context.insert(checking)

    let bills = [
        Bill(title: "Rent", category: "Rent/Mortgage", amount: 1500, dueDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!, recurrence: .monthly, account: checking),
        Bill(title: "Electric", category: "Utilities", amount: 120, dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!, recurrence: .monthly, account: checking),
        Bill(title: "Credit Card", category: "Credit Card", amount: 450, dueDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, recurrence: .monthly, account: checking),
        Bill(title: "Phone", category: "Phone", amount: 85, dueDate: Date(), recurrence: .monthly, isPaid: true, lastPaidDate: Date(), account: checking)
    ]

    bills.forEach { context.insert($0) }

    return BillsListView()
        .modelContainer(container)
}

#Preview("Empty State") {
    BillsListView()
        .modelContainer(for: [Bill.self, Account.self], inMemory: true)
}
