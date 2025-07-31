//
//  AuthenticationViewModel.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-31.
//

import SwiftUI

@MainActor
final class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    
    var isEmailValid: Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines)) && !email.isEmpty
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        
        await firebaseService.signIn(email: email, password: password)
        
        // Update local state based on FirebaseService result
        await MainActor.run {
            self.isLoading = false
            if let error = firebaseService.errorMessage {
                self.errorMessage = error
            }
        }
    }
    
    // Create new account with email, password, and full name
    // Firebase Auth automatically prevents duplicate emails with emailAlreadyInUse error
    func createAccount(email: String, fullName: String, password: String) async {
        guard !email.isEmpty, !fullName.isEmpty, password.count >= 6 else { return }
        isLoading = true
        errorMessage = nil
        
        await firebaseService.signUp(email: email, password: password, username: fullName, monthlyBudget: 1000.0)
        
        // Update local state based on FirebaseService result
        await MainActor.run {
            self.isLoading = false
            if let error = firebaseService.errorMessage {
                self.errorMessage = error
            }
        }
    }
    
    // Clear error message
    func clearError() {
        errorMessage = nil
    }
    

}
