//
//  AuthenticationViewModel.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-31.
//

import SwiftUI
import GoogleSignIn
import FirebaseAuth

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
    
    // MARK: - Google Sign-In Methods
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        // Check if Google Sign-In is available
        guard GIDSignIn.sharedInstance.hasPreviousSignIn() || GIDSignIn.sharedInstance.configuration != nil else {
            await MainActor.run {
                self.errorMessage = "Google Sign-In is not properly configured"
                self.isLoading = false
            }
            return
        }
        
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            await MainActor.run {
                self.errorMessage = "Unable to present Google Sign-In"
                self.isLoading = false
            }
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                await MainActor.run {
                    self.errorMessage = "Failed to get ID token from Google"
                    self.isLoading = false
                }
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            
            // Sign in to Firebase with Google credential
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // Check if user exists in Firestore
            let userDoc = try await firebaseService.db.collection("users").document(authResult.user.uid).getDocument()
            
            if let data = userDoc.data(), let user = AppUser.fromDictionary(data) {
                // User exists, update local state
                await MainActor.run {
                    firebaseService.user = user
                    firebaseService.isAuthenticated = true
                    self.isLoading = false
                }
                firebaseService.loadExpenses()
            } else {
                // New user, create account in Firestore
                let newUser = AppUser(
                    id: authResult.user.uid,
                    email: authResult.user.email ?? "",
                    username: result.user.profile?.name ?? "User",
                    monthlyBudget: 1000.0,
                    createdAt: Date()
                )
                
                try await firebaseService.saveUser(newUser)
                
                await MainActor.run {
                    firebaseService.user = newUser
                    firebaseService.isAuthenticated = true
                    self.isLoading = false
                }
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = self.getUserFriendlyErrorMessage(error)
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getUserFriendlyErrorMessage(_ error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        // Handle Google Sign-In specific errors
        if errorDescription.contains("canceled") || errorDescription.contains("cancelled") {
            return "Sign-in was cancelled"
        }
        
        if errorDescription.contains("network") || errorDescription.contains("internet") {
            return "Please check your internet connection and try again"
        }
        
        // Handle Firebase Auth errors
        if let authError = error as NSError?, authError.domain == "FIRAuthErrorDomain" {
            switch authError.code {
            case 17007: // FIRAuthErrorCodeEmailAlreadyInUse
                return "This email is already in use with a different sign-in method"
            case 17008: // FIRAuthErrorCodeInvalidEmail
                return "Invalid email address"
            case 17009: // FIRAuthErrorCodeWrongPassword
                return "Incorrect password"
            case 17011: // FIRAuthErrorCodeUserNotFound
                return "No account found with this email"
            case 17010: // FIRAuthErrorCodeInvalidCredential
                return "Invalid credentials"
            case 17020: // FIRAuthErrorCodeNetworkError
                return "Network error. Please check your connection"
            case 17999: // FIRAuthErrorCodeInternalError
                return "An unexpected error occurred. Please try again"
            default:
                return "Authentication failed. Please try again"
            }
        }
        
        return "Something went wrong. Please try again"
    }
    
    // Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    // Sign out from Google and Firebase
    func signOut() async {
        isLoading = true
        
        do {
            // Sign out from Google (not async)
            GIDSignIn.sharedInstance.signOut()
            
            // Sign out from Firebase (not async)
            try Auth.auth().signOut()
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}
