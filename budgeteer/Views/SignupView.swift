//
//  SignupView.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import SwiftUI

struct SignupView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = "" 
    @State private var email = "" 
    @State private var password = "" 
    @State private var confirmPassword = "" 
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var localErrorMessage: String?
    
    private var isFormValid: Bool {
        !username.isEmpty && 
        !email.isEmpty && 
        !password.isEmpty && 
        password == confirmPassword && 
        password.count >= 6 &&
        isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                            
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 35, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Join thousands managing their finances")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Form Card
                    VStack(spacing: 24) {
                        VStack(spacing: 20) {
                            // Username Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter your full name", text: $username)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .autocapitalization(.words)
                                    .disableAutocorrection(true)
                                
                                if !username.isEmpty && username.count < 2 {
                                    Label("Name must be at least 2 characters", systemImage: "exclamationmark.circle")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                
                                if !email.isEmpty && !isValidEmail(email) {
                                    Label("Please enter a valid email address", systemImage: "exclamationmark.circle")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Group {
                                        if isPasswordVisible {
                                            TextField("Create a password", text: $password)
                                        } else {
                                            SecureField("Create a password", text: $password)
                                        }
                                    }
                                    .textFieldStyle(CustomTextFieldStyle(hasTrailingButton: true))
                                    
                                    Button(action: { isPasswordVisible.toggle() }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.secondary)
                                            .font(.title3)
                                    }
                                    .padding(.trailing, 12)
                                }
                                
                                if !password.isEmpty && password.count < 6 {
                                    Label("Password must be at least 6 characters", systemImage: "exclamationmark.circle")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Group {
                                        if isConfirmPasswordVisible {
                                            TextField("Confirm your password", text: $confirmPassword)
                                        } else {
                                            SecureField("Confirm your password", text: $confirmPassword)
                                        }
                                    }
                                    .textFieldStyle(CustomTextFieldStyle(hasTrailingButton: true))
                                    
                                    Button(action: { isConfirmPasswordVisible.toggle() }) {
                                        Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.secondary)
                                            .font(.title3)
                                    }
                                    .padding(.trailing, 12)
                                }
                                
                                if !confirmPassword.isEmpty && password != confirmPassword {
                                    Label("Passwords don't match", systemImage: "exclamationmark.circle")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // Error Message
                            if let errorMessage = localErrorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(errorMessage)
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        
                        // Create Account Button
                        Button(action: signUp) {
                            HStack {
                                if firebaseService.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.9)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "person.badge.plus.fill")
                                        .font(.title3)
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: isFormValid ? [.blue, .purple] : [.gray, .gray]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .scaleEffect(isFormValid ? 1.0 : 0.98)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFormValid)
                        }
                        .disabled(firebaseService.isLoading || !isFormValid)
                        
                        // Login Link
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.secondary)
                            
                            Button("Sign In") {
                                // Clear errors before dismissing
                                firebaseService.errorMessage = nil
                                localErrorMessage = nil
                                dismiss()
                            }
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Clear any existing error messages when view appears
                firebaseService.errorMessage = nil
                localErrorMessage = nil
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Clear errors before dismissing
                        firebaseService.errorMessage = nil
                        localErrorMessage = nil
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func signUp() {
        // Clear any existing error
        localErrorMessage = nil
        
        let defaultBudget = 1000.0 // Default budget
        
        Task {
            await firebaseService.signUp(
                email: email, 
                password: password, 
                username: username, 
                monthlyBudget: defaultBudget
            )
            
            // Check for errors after signup attempt
            await MainActor.run {
                if let error = firebaseService.errorMessage {
                    localErrorMessage = error
                    firebaseService.errorMessage = nil // Clear shared error
                }
            }
        }
    }
}

#Preview {
    SignupView()
}
