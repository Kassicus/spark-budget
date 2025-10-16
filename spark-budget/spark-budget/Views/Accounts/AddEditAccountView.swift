//
//  AddEditAccountView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import SwiftUI
import SwiftData

struct AddEditAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]

    @State private var name: String
    @State private var type: AccountType
    @State private var balance: String
    @State private var accountNumber: String
    @State private var isPrimary: Bool
    @State private var selectedColor: Color
    @State private var savedSuccessfully = false
    @State private var error: AppError?

    let account: Account?
    let isEditing: Bool

    init(account: Account? = nil) {
        self.account = account
        self.isEditing = account != nil

        _name = State(initialValue: account?.name ?? "")
        _type = State(initialValue: account?.type ?? .checking)
        _balance = State(initialValue: account != nil ? String(describing: account!.balance) : "0")
        _accountNumber = State(initialValue: account?.accountNumber ?? "")
        _isPrimary = State(initialValue: account?.isPrimary ?? false)
        _selectedColor = State(initialValue: account?.color ?? .blue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Account Name", text: $name)

                    Picker("Account Type", selection: $type) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }

                    TextField("Account Number (Last 4 digits)", text: $accountNumber)
                        .keyboardType(.numberPad)
                }

                Section("Balance") {
                    TextField("Current Balance", text: $balance)
                        .keyboardType(.decimalPad)
                }

                Section("Appearance") {
                    ColorPicker("Account Color", selection: $selectedColor)
                }

                Section("Settings") {
                    Toggle("Primary Account", isOn: $isPrimary)
                    Text("Primary account is used for daily spending calculations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(isEditing ? "Edit Account" : "New Account")
            .navigationBarTitleDisplayMode(.inline)
            .sensoryFeedback(.success, trigger: savedSuccessfully)
            .errorAlert($error)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAccount()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveAccount() {
        // Validation
        guard !name.isEmpty else {
            error = .invalidData("Account name is required")
            return
        }

        guard let balanceDecimal = Decimal(string: balance) else {
            error = .invalidData("Please enter a valid balance amount")
            return
        }

        do {
            if let account = account {
                // Update existing account
                account.name = name
                account.type = type
                account.balance = balanceDecimal
                account.accountNumber = accountNumber.isEmpty ? nil : accountNumber
                account.isPrimary = isPrimary
                account.color = selectedColor
                account.modifiedAt = Date()
            } else {
                // Create new account
                let newAccount = Account(
                    name: name,
                    type: type,
                    balance: balanceDecimal,
                    isPrimary: isPrimary,
                    color: selectedColor,
                    accountNumber: accountNumber.isEmpty ? nil : accountNumber
                )
                modelContext.insert(newAccount)
            }

            // If this account is set as primary, unset all others
            if isPrimary {
                for acc in accounts where acc.id != account?.id {
                    acc.isPrimary = false
                }
            }

            try modelContext.save()
            savedSuccessfully.toggle()
            dismiss()
        } catch {
            self.error = .saveFailed(error.localizedDescription)
        }
    }
}

#Preview {
    AddEditAccountView()
        .modelContainer(for: Account.self, inMemory: true)
}
