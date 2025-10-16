//
//  ErrorHandler.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/16/25.
//

import Foundation
import SwiftUI

enum AppError: LocalizedError {
    case saveFailed(String)
    case deleteFailed(String)
    case invalidData(String)
    case networkError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "Save Failed: \(message)"
        case .deleteFailed(let message):
            return "Delete Failed: \(message)"
        case .invalidData(let message):
            return "Invalid Data: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .unknown:
            return "An unknown error occurred"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .saveFailed:
            return "Please check your data and try again."
        case .deleteFailed:
            return "This item may be in use. Please try again later."
        case .invalidData:
            return "Please check all required fields are filled correctly."
        case .networkError:
            return "Please check your internet connection and try again."
        case .unknown:
            return "Please restart the app and try again."
        }
    }
}

struct ErrorAlert: ViewModifier {
    @Binding var error: AppError?

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil), presenting: error) { error in
                Button("OK") {
                    self.error = nil
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    if let description = error.errorDescription {
                        Text(description)
                    }
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                    }
                }
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<AppError?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}
