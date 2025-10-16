//
//  ContentView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @State private var showOnboarding = false
    @Query private var userSettings: [UserSettings]

    var body: some View {
        MainTabView()
            .preferredColorScheme(appTheme.colorScheme)
            .tint(userSettings.first?.accentColor ?? .blue)
            .onAppear {
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
                    .interactiveDismissDisabled()
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Account.self, Transaction.self, Bill.self, UserSettings.self], inMemory: true)
}
