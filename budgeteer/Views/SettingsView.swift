//
//  SettingsView.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var showingBudgetEditor = false
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingErrorAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    profileContent
                }
                
                // Budget Section
                Section {
                    budgetContent
                } header: {
                    Text("Budget")
                }
                
                // Statistics Section
                Section {
                    statisticsContent
                } header: {
                    Text("Statistics")
                }
                
                // Account Actions Section
                Section {
                    // Sign Out Button
                    Button(action: { showingSignOutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.orange)
                                .font(.title3)
                                .frame(width: 24, height: 24)
                            
                            Text("Sign Out")
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Account")
                } footer: {
                    Text("You can sign back in anytime with your credentials.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                // Danger Zone Section with more spacing and warning styling
                Section {
                    Button(action: { showingDeleteAccountAlert = true }) {
                        HStack {
                            if firebaseService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.red)
                            } else {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                                    .font(.title3)
                                    .frame(width: 24, height: 24)
                            }
                            
                            Text("Delete Account")
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(firebaseService.isLoading)
                } header: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("Danger Zone")
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WARNING: This action cannot be undone")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                        
                        Text("All your data including expenses, budget settings, and account information will be permanently deleted from our servers.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    firebaseService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Forever", role: .destructive) {
                    Task {
                        await firebaseService.deleteAccount()
                        // Show error if deletion failed
                        if firebaseService.errorMessage != nil {
                            showingErrorAlert = true
                        }
                    }
                }
            } message: {
                Text("⚠️ WARNING: This will permanently delete your account, all expenses, and cannot be undone. You will lose all your data forever.")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) {
                    firebaseService.errorMessage = nil
                }
            } message: {
                Text(firebaseService.errorMessage ?? "An unknown error occurred")
            }
            .sheet(isPresented: $showingBudgetEditor) {
                BudgetEditorView()
            }
        }
    }
    
    private var profileContent: some View {
        HStack(spacing: 16) {
            // Profile Avatar
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(firebaseService.user?.username.prefix(1).uppercased() ?? "U")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(firebaseService.user?.username ?? "Unknown User")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(firebaseService.user?.email ?? "No email")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Member since \(DateFormatter.memberSince.string(from: firebaseService.user?.createdAt ?? Date()))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var budgetContent: some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Monthly Budget")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("$\(Int(firebaseService.user?.monthlyBudget ?? 0))")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            Button("Edit") {
                showingBudgetEditor = true
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
    
    private var statisticsContent: some View {
        VStack(spacing: 0) {
            StatisticRowView(
                icon: "calendar.circle",
                title: "Total Expenses",
                value: "\(firebaseService.expenses.count)",
                color: .blue
            )
            
            StatisticRowView(
                icon: "dollarsign.circle.fill",
                title: "Total Spent",
                value: "$\(String(format: "%.2f", firebaseService.expenses.reduce(0) { $0 + $1.amount }))",
                color: .orange
            )
            
            StatisticRowView(
                icon: "chart.bar.fill",
                title: "This Month",
                value: "$\(String(format: "%.2f", firebaseService.totalSpentThisMonth()))",
                color: .purple
            )
            
            StatisticRowView(
                icon: "star.circle.fill",
                title: "Average per Day",
                value: "$\(String(format: "%.2f", averagePerDay()))",
                color: .pink
            )
        }
    }
    
    private func averagePerDay() -> Double {
        let expenses = firebaseService.expenses
        guard !expenses.isEmpty else { return 0 }
        
        let totalAmount = expenses.reduce(0) { $0 + $1.amount }
        let oldestDate = expenses.map(\.createdAt).min() ?? Date()
        let daysSinceStart = max(1, Calendar.current.dateComponents([.day], from: oldestDate, to: Date()).day ?? 1)
        
        return totalAmount / Double(daysSinceStart)
    }
}

struct StatisticRowView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BudgetEditorView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var budgetText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Set Monthly Budget")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Set a realistic monthly spending limit to help track your expenses better.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Budget Input
                VStack(spacing: 16) {
                    Text("Monthly Budget")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text("$")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        TextField("1000", text: $budgetText)
                            .font(.title)
                            .fontWeight(.semibold)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Suggestions
                    VStack(spacing: 8) {
                        Text("Quick Suggestions")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach([500, 1000, 2000, 5000], id: \.self) { amount in
                                Button("$\(amount)") {
                                    budgetText = "\(amount)"
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                // Save Button
                Button(action: saveBudget) {
                    HStack {
                        if firebaseService.isLoading {
                            ProgressView()
                                .scaleEffect(0.9)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Budget")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isValidBudget ? .green : .gray)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isValidBudget || firebaseService.isLoading)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                budgetText = "\(firebaseService.user?.monthlyBudget ?? 1000)"
            }
        }
    }
    
    private var isValidBudget: Bool {
        guard let budget = Double(budgetText) else { return false }
        return budget > 0
    }
    
    private func saveBudget() {
        guard var user = firebaseService.user,
              let budget = Double(budgetText) else { return }
        
        user.monthlyBudget = budget
        
        Task {
            await firebaseService.updateUser(user)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

extension DateFormatter {
    static let memberSince: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

#Preview {
    SettingsView()
}
