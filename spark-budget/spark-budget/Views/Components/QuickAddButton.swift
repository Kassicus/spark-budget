//
//  QuickAddButton.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import SwiftUI

struct QuickAddButton: View {
    @State private var showTransactionSheet = false
    @State private var showTransferSheet = false
    @State private var showAccountSheet = false
    @State private var showMenu = false

    var body: some View {
        Menu {
            Button {
                showTransactionSheet = true
            } label: {
                Label("Add Transaction", systemImage: "dollarsign.circle")
            }

            Button {
                showTransferSheet = true
            } label: {
                Label("Transfer Money", systemImage: "arrow.left.arrow.right")
            }

            Button {
                showAccountSheet = true
            } label: {
                Label("Add Account", systemImage: "creditcard")
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue.gradient)
                .background(
                    Circle()
                        .fill(.white)
                        .frame(width: 48, height: 48)
                )
        } primaryAction: {
            // Primary action is to add a transaction
            showTransactionSheet = true
        }
        .sheet(isPresented: $showTransactionSheet) {
            AddEditTransactionView()
        }
        .sheet(isPresented: $showTransferSheet) {
            TransferView()
        }
        .sheet(isPresented: $showAccountSheet) {
            AddEditAccountView()
        }
    }
}

/// A floating action button that can be overlaid on views
struct FloatingActionButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                QuickAddButton()
                    .padding()
            }
    }
}

extension View {
    func floatingActionButton() -> some View {
        modifier(FloatingActionButton())
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                QuickAddButton()
                    .padding()
            }
        }
    }
}
