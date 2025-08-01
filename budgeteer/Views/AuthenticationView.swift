//
//  AuthenticationView.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-31.
//

import SwiftUI
import FirebaseAuth
import Combine

struct AuthenticationView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @FocusState private var emailFocused: Bool
    @FocusState private var passwordFocused: Bool
    @FocusState private var nameFocused: Bool
    @FocusState private var confirmPasswordFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var password = ""
    @State private var fullName = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var authFlow: AuthFlow = .email
    @State private var keyboardHeight: CGFloat = 0
    
    enum AuthFlow {
        case email          // Show email field only
        case signIn         // Show email + password fields (sign in flow)
        case signUp         // Show email + name + password + confirm password fields (sign up flow)
    }
    
    private var canProceedWithEmail: Bool {
        authViewModel.isEmailValid && !authViewModel.isEmailLoading
    }
    
    private var canSignIn: Bool {
        !password.isEmpty && !authViewModel.isEmailLoading
    }
    
    private var canSignUp: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        !authViewModel.isEmailLoading
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.top, max(50, geometry.safeAreaInsets.top))
                            .padding(.bottom, 48)
                        
                        mainContentSection
                            .padding(.horizontal, 24)
                            .padding(.bottom, max(20, geometry.safeAreaInsets.bottom))
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .animation(.smooth(duration: 0.4), value: authFlow)
        .animation(.smooth(duration: 0.3), value: authViewModel.errorMessage)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 18) {
            // App icon
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.blue.gradient)
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white)
                }
                .shadow(color: .blue.opacity(0.25), radius: 20, x: 0, y: 8)
            
            VStack(spacing: 8) {
                Text("Budgeteer")
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text("Take control of your finances")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Main Content Section
    
    private var mainContentSection: some View {
        VStack(spacing: 24) {
            inputFieldsSection
            
            if let errorMessage = authViewModel.errorMessage {
                errorMessageView(errorMessage)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            actionButtonsSection
        }
    }
    
    // MARK: - Input Fields Section
    
    private var inputFieldsSection: some View {
        VStack(spacing: 16) {
            // Email field - always visible and always first
            emailInputField
            
            // Name field - only for sign up, appears after email
            if authFlow == .signUp {
                nameInputField
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            
            // Password field - for both sign in and sign up
            if authFlow == .signIn || authFlow == .signUp {
                passwordInputField
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            
            // Confirm password field - only for sign up
            if authFlow == .signUp {
                confirmPasswordInputField
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                
                if !password.isEmpty || !confirmPassword.isEmpty {
                    passwordRequirements
                }
            }
        }
    }
    
    // MARK: - Input Fields
    
    private var emailInputField: some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            TextField("Email address", text: $authViewModel.email)
                .textFieldStyle(.plain)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($emailFocused)
                .submitLabel(.continue)
                .onSubmit {
                    if canProceedWithEmail && authFlow == .email {
                        proceedToSignIn()
                    } else if authFlow == .signUp {
                        nameFocused = true
                    }
                }
            
            if !authViewModel.email.isEmpty {
                Button(action: clearForm) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(authViewModel.isEmailValid ? .blue : .clear, lineWidth: 1)
                }
        }
    }
    
    private var nameInputField: some View {
        HStack(spacing: 12) {
            Image(systemName: "person")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            TextField("Full name", text: $fullName)
                .textFieldStyle(.plain)
                .textContentType(.name)
                .focused($nameFocused)
                .submitLabel(.next)
                .onSubmit {
                    passwordFocused = true
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        }
    }
    
    private var passwordInputField: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Group {
                if showPassword {
                    TextField(authFlow == .signUp ? "Create a password" : "Enter your password", text: $password)
                } else {
                    SecureField(authFlow == .signUp ? "Create a password" : "Enter your password", text: $password)
                }
            }
            .textFieldStyle(.plain)
            .textContentType(authFlow == .signUp ? .newPassword : .password)
            .focused($passwordFocused)
            .submitLabel(authFlow == .signUp ? .next : .go)
            .onSubmit {
                if authFlow == .signIn && canSignIn {
                    attemptSignIn()
                } else if authFlow == .signUp {
                    confirmPasswordFocused = true
                }
            }
            
            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    if authFlow == .signUp && !password.isEmpty {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(password.count >= 6 ? .green : .orange, lineWidth: 1)
                    }
                }
        }
    }
    
    private var confirmPasswordInputField: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Group {
                if showConfirmPassword {
                    TextField("Confirm password", text: $confirmPassword)
                } else {
                    SecureField("Confirm password", text: $confirmPassword)
                }
            }
            .textFieldStyle(.plain)
            .textContentType(.newPassword)
            .focused($confirmPasswordFocused)
            .submitLabel(.go)
            .onSubmit {
                if canSignUp {
                    signUp()
                }
            }
            
            Button(action: { showConfirmPassword.toggle() }) {
                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    if !confirmPassword.isEmpty {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(password == confirmPassword ? .green : .red, lineWidth: 1)
                    }
                }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Main action button
            if authFlow == .email {
                continueButton
            } else if authFlow == .signIn {
                signInButton
                switchToSignUpButton
            } else if authFlow == .signUp {
                createAccountButton
                switchToSignInButton
            }
            
            // Divider
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.secondary.opacity(0.3))
                
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.secondary.opacity(0.3))
            }
            
            // Google Sign-In button - always visible
            googleSignInButton
        }
    }
    
    // MARK: - Buttons
    
    private var continueButton: some View {
        Button(action: proceedToSignIn) {
            HStack {
                if authViewModel.isEmailLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text("Continue with Email")
                        .font(.body.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(canProceedWithEmail ? .blue : .gray)
            }
        }
        .disabled(!canProceedWithEmail)
        .buttonStyle(.plain)
    }
    
    private var signInButton: some View {
        Button(action: attemptSignIn) {
            HStack {
                if authViewModel.isEmailLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text("Sign In")
                        .font(.body.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(canSignIn ? .blue : .gray)
            }
        }
        .disabled(!canSignIn)
        .buttonStyle(.plain)
    }
    
    private var createAccountButton: some View {
        Button(action: signUp) {
            HStack {
                if authViewModel.isEmailLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text("Create Account")
                        .font(.body.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(canSignUp ? .blue : .gray)
            }
        }
        .disabled(!canSignUp)
        .buttonStyle(.plain)
    }
    
    private var switchToSignUpButton: some View {
        Button("Don't have an account? Create one") {
            switchToSignUp()
        }
        .font(.subheadline)
        .foregroundStyle(.blue)
        .buttonStyle(.plain)
    }
    
    private var switchToSignInButton: some View {
        Button("Already have an account? Sign in") {
            switchToSignIn()
        }
        .font(.subheadline)
        .foregroundStyle(.blue)
        .buttonStyle(.plain)
    }
    
    private var googleSignInButton: some View {
        Button(action: signInWithGoogle) {
            HStack(spacing: 12) {
                if authViewModel.isGoogleLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        .scaleEffect(0.9)
                } else {
                    // Official Google logo from assets - different for light/dark mode
                    Image(colorScheme == .dark ? "google_logo_dark" : "google_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                    
                    Text("Continue with Google")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(colorScheme == .dark ? Color(.systemGray4) : .secondary.opacity(0.3), lineWidth: 1)
                    }
            }
        }
        .disabled(authViewModel.isGoogleLoading)
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Views
    
    private var passwordRequirements: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !password.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: password.count >= 6 ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundStyle(password.count >= 6 ? .green : .secondary)
                    
                    Text("At least 6 characters")
                        .font(.caption)
                        .foregroundStyle(password.count >= 6 ? .green : .secondary)
                }
            }
            
            if !confirmPassword.isEmpty && password != confirmPassword {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                    
                    Text("Passwords don't match")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func errorMessageView(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.red.opacity(0.1))
        }
    }
    
    // MARK: - Actions
    
    private func proceedToSignIn() {
        guard canProceedWithEmail else { return }
        authFlow = .signIn
        passwordFocused = true
        authViewModel.clearError()
    }
    
    private func switchToSignUp() {
        authFlow = .signUp
        nameFocused = true
        authViewModel.clearError()
    }
    
    private func switchToSignIn() {
        authFlow = .signIn
        passwordFocused = true
        authViewModel.clearError()
    }
    
    private func attemptSignIn() {
        guard canSignIn else { return }
        Task {
            await authViewModel.signIn(email: authViewModel.email, password: password)
        }
    }
    
    private func signUp() {
        guard canSignUp else { return }
        Task {
            await authViewModel.createAccount(
                email: authViewModel.email,
                fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
        }
    }
    
    private func signInWithGoogle() {
        Task {
            await authViewModel.signInWithGoogle()
        }
    }
    
    private func clearForm() {
        authViewModel.email = ""
        authFlow = .email
        password = ""
        fullName = ""
        confirmPassword = ""
        showPassword = false
        showConfirmPassword = false
        authViewModel.clearError()
        emailFocused = true
    }
}

#Preview {
    AuthenticationView()
}
