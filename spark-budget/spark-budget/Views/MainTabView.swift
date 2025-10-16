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

    // MARK: - Feature Flags
    private let showQuickAddButton = false // Set to true to re-enable floating action button

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab.animation(.smooth)) {
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

            // Quick Add Button - only show on main tabs, hide on Settings
            // Currently disabled - set showQuickAddButton to true to re-enable
            if showQuickAddButton && selectedTab != 4 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        QuickAddButton()
                            .padding(.trailing, 16)
                            .padding(.bottom, 70) // Position above tab bar
                    }
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Account.self, Transaction.self, Bill.self, UserSettings.self], inMemory: true)
}
