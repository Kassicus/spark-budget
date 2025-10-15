//
//  MainTabView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            AccountsListView()
                .tabItem {
                    Label("Accounts", systemImage: "creditcard.fill")
                }
                .tag(0)

            TransactionsListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
                .tag(1)

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(2)

            BillsListView()
                .tabItem {
                    Label("Bills", systemImage: "doc.text.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Account.self, Transaction.self, Bill.self, UserSettings.self], inMemory: true)
}
