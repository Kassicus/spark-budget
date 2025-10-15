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

    var body: some View {
        NavigationStack {
            Form {
                Section("Payday Settings") {
                    Text("Configure payday")
                }

                Section("Preferences") {
                    Text("App preferences")
                }

                Section("About") {
                    Text("Spark Budget")
                    Text("Version 1.0")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: UserSettings.self, inMemory: true)
}
