//
//  SettingsView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @Query private var accounts: [Account]
    @Query private var transactions: [Transaction]
    @Query private var bills: [Bill]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false

    private var accentColorBinding: Binding<Color> {
        Binding(
            get: {
                userSettings.first?.accentColor ?? .blue
            },
            set: { newColor in
                if let settings = userSettings.first {
                    settings.accentColor = newColor
                } else {
                    // Create new UserSettings if none exists
                    let newSettings = UserSettings(accentColor: newColor)
                    modelContext.insert(newSettings)
                }
                try? modelContext.save()
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Payday Settings") {
                    NavigationLink {
                        PaydaySettingsView()
                    } label: {
                        HStack {
                            Label("Configure Payday", systemImage: "calendar.badge.clock")

                            Spacer()

                            if let settings = userSettings.first {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(settings.paydayFrequency.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(settings.payday, style: .date)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Text("Not configured")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if let primaryAccount = accounts.first(where: { $0.isPrimary }) {
                        HStack {
                            Label("Primary Account", systemImage: "banknote")
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(primaryAccount.color)
                                    .frame(width: 8, height: 8)
                                Text(primaryAccount.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: $appTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            HStack {
                                switch theme {
                                case .system:
                                    Label("System", systemImage: "circle.lefthalf.filled")
                                case .light:
                                    Label("Light", systemImage: "sun.max.fill")
                                case .dark:
                                    Label("Dark", systemImage: "moon.fill")
                                }
                            }
                            .tag(theme)
                        }
                    }
                    .pickerStyle(.inline)

                    Text("Choose between light, dark, or automatic based on your system settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ColorPicker("Accent Color", selection: accentColorBinding)

                    Text("Customize the accent color used throughout the app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Total Data")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(accounts.count) accounts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(transactions.count) transactions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(bills.count) bills")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        HStack {
                            Label("Reset All Data", systemImage: "trash.fill")
                            Spacer()
                        }
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("This will permanently delete all accounts, transactions, bills, and settings. The app will return to a fresh install state and show the onboarding screen.")
                        .font(.caption)
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Data?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    performReset()
                }
            } message: {
                Text("This will permanently delete all your data including accounts, transactions, bills, and settings. This action cannot be undone.")
            }
            .alert("Reset Complete", isPresented: $showResetSuccess) {
                Button("OK") { }
            } message: {
                Text("All data has been deleted. The app will show the onboarding screen on next launch.")
            }
        }
    }

    private func performReset() {
        // Delete all accounts
        for account in accounts {
            modelContext.delete(account)
        }

        // Delete all transactions
        for transaction in transactions {
            modelContext.delete(transaction)
        }

        // Delete all bills
        for bill in bills {
            modelContext.delete(bill)
        }

        // Delete all user settings
        for settings in userSettings {
            modelContext.delete(settings)
        }

        // Save the deletion
        do {
            try modelContext.save()
        } catch {
            print("Error during reset: \(error)")
        }

        // Reset onboarding flag
        hasCompletedOnboarding = false

        // Show success message
        showResetSuccess = true
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: UserSettings.self, inMemory: true)
}
