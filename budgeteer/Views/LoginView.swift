//
//  LoginView.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingSignup = false
    @State private var isPasswordVisible = false
    @State private var localErrorMessage: String?
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    Spacer(minLength: 60)
                    
                    // Header
                    VStack(spacing: 24) {
                        // App Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 12) {
                            Text("Budgeteer")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Track expenses beautifully")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Form Card
                    VStack(spacing: 24) {
                        VStack(spacing: 20) {
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
                                            TextField("Enter your password", text: $password)
                                        } else {
                                            SecureField("Enter your password", text: $password)
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
                        
                        // Sign In Button
                        Button(action: signIn) {
                            HStack {
                                if firebaseService.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.9)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title3)
                                    Text("Sign In")
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
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.secondary)
                            
                            Button("Sign Up") {
                                // Clear errors before showing signup
                                firebaseService.errorMessage = nil
                                localErrorMessage = nil
                                isShowingSignup = true
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
            .onAppear {
                // Clear any existing error messages when view appears
                firebaseService.errorMessage = nil
                localErrorMessage = nil
            }
        }
        .sheet(isPresented: $isShowingSignup) {
            SignupView()
        }
    }
    
    private func signIn() {
        // Clear any existing error
        localErrorMessage = nil
        
        Task {
            await firebaseService.signIn(email: email, password: password)
            
            // Check for errors after signin attempt
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
    LoginView()
}
