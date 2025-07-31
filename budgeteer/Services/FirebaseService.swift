//
//  FirebaseService.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

// Avoid naming conflicts with Firebase.User
typealias AppUser = User

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    @Published var user: AppUser?
    @Published var expenses: [Expense] = []
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var expenseListener: ListenerRegistration?
    private var authListener: AuthStateDidChangeListenerHandle?
    
    init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.isAuthenticated = true
                self?.loadUser(userId: user.uid)
                // Also try to load expenses directly in case user data loading fails
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    if self?.expenses.isEmpty == true {
                        self?.loadExpensesDirectly(userId: user.uid)
                    }
                }
            } else {
                self?.isAuthenticated = false
                self?.user = nil
                self?.expenses = []
                self?.expenseListener?.remove()
            }
        }
    }
    
    deinit {
        if let authListener = authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
        expenseListener?.remove()
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, username: String, monthlyBudget: Double) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let newUser = AppUser(id: authResult.user.uid, email: email, username: username, monthlyBudget: monthlyBudget, createdAt: Date())
            try await saveUser(newUser)
            await MainActor.run {
                self.user = newUser
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                // Filter out Firebase internal errors from user display
                let errorMessage = self.getUserFriendlyErrorMessage(error)
                self.errorMessage = errorMessage
                self.isLoading = false
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                // Filter out Firebase internal errors from user display
                let errorMessage = self.getUserFriendlyErrorMessage(error)
                self.errorMessage = errorMessage
                self.isLoading = false
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func deleteAccount() async {
        guard let user = Auth.auth().currentUser,
              let appUser = self.user else {
            await MainActor.run {
                self.errorMessage = "No user found to delete"
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // 1. Delete all user's expenses from Firestore
            let expensesQuery = db.collection("expenses").whereField("userId", isEqualTo: appUser.id)
            let expensesSnapshot = try await expensesQuery.getDocuments()
            
            // Delete expenses in batches for better performance
            let batch = db.batch()
            for document in expensesSnapshot.documents {
                batch.deleteDocument(document.reference)
            }
            try await batch.commit()
            
            // 2. Delete user document from Firestore
            try await db.collection("users").document(appUser.id).delete()
            
            // 3. Delete Firebase Auth account
            try await user.delete()
            
            // 4. Clear local state
            await MainActor.run {
                self.user = nil
                self.expenses = []
                self.isAuthenticated = false
                self.isLoading = false
                self.expenseListener?.remove()
            }
            
        } catch {
            await MainActor.run {
                let errorMessage = self.getUserFriendlyErrorMessage(error)
                self.errorMessage = errorMessage
                self.isLoading = false
            }
        }
    }
    
    // MARK: - User Management
    
    private func saveUser(_ user: AppUser) async throws {
        try await db.collection("users").document(user.id).setData(user.toDictionary())
    }
    
    private func loadUser(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let error = error {
                // Only log internal errors, don't show to user
                print("Firebase Error (internal): \(error.localizedDescription)")
                return
            }
            
            if let data = snapshot?.data(), let user = AppUser.fromDictionary(data) {
                self?.user = user
                self?.loadExpenses()
            }
        }
    }
    
    func updateUser(_ user: AppUser) async {
        do {
            try await db.collection("users").document(user.id).setData(user.toDictionary())
            await MainActor.run {
                self.user = user
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Expense Management
    
    private func loadExpensesDirectly(userId: String) {
        expenseListener?.remove() // Remove any existing listener
        expenseListener = db.collection("expenses")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    // Only log internal errors, don't show to user
                    print("Firebase Error (internal): \(error.localizedDescription)")
                    return
                }
                
                let expenses = snapshot?.documents.compactMap { doc in
                    Expense.fromDictionary(doc.data())
                } ?? []
                
                self?.expenses = expenses
            }
    }
    
    private func loadExpenses() {
        guard let userId = user?.id else { return }
        loadExpensesDirectly(userId: userId)
    }
    
    func addExpense(_ expense: Expense) async {
        do {
            // Add the expense to the local array immediately for instant UI update
            await MainActor.run {
                self.expenses.insert(expense, at: 0) // Add to beginning for newest first
            }
            
            // Then save to Firebase
            try await db.collection("expenses").document(expense.id).setData(expense.toDictionary())
        } catch {
            // If Firebase save fails, remove from local array
            await MainActor.run {
                if let index = self.expenses.firstIndex(where: { $0.id == expense.id }) {
                    self.expenses.remove(at: index)
                }
                self.errorMessage = self.getUserFriendlyErrorMessage(error)
            }
        }
    }
    
    func uploadExpensePhoto(_ image: UIImage, expenseId: String) async -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            await MainActor.run {
                self.errorMessage = "Failed to process image"
            }
            return nil
        }
        
        let storageRef = storage.reference().child("expense_photos/\(expenseId).jpg")
        
        return await withCheckedContinuation { continuation in
            print("Starting photo upload for expense: \(expenseId)")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            _ = storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    Task { @MainActor in
                        self.errorMessage = "Failed to upload photo: \(error.localizedDescription)"
                    }
                    print("Photo upload failed: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard metadata != nil else {
                    Task { @MainActor in
                        self.errorMessage = "Failed to upload photo: No metadata received"
                    }
                    print("Photo upload failed: No metadata received")
                    continuation.resume(returning: nil)
                    return
                }
                
                // Get download URL
                storageRef.downloadURL { url, error in
                    if let error = error {
                        Task { @MainActor in
                            self.errorMessage = "Failed to get download URL: \(error.localizedDescription)"
                        }
                        print("Failed to get download URL: \(error.localizedDescription)")
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    guard let downloadURL = url else {
                        Task { @MainActor in
                            self.errorMessage = "Failed to get download URL: No URL received"
                        }
                        print("Failed to get download URL: No URL received")
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    print("Photo upload successful: \(downloadURL.absoluteString)")
                    continuation.resume(returning: downloadURL.absoluteString)
                }
            }
        }
    }
    
    func updateExpense(_ expense: Expense) async {
        do {
            // Update local array immediately for instant UI update
            await MainActor.run {
                if let index = self.expenses.firstIndex(where: { $0.id == expense.id }) {
                    self.expenses[index] = expense
                }
            }
            
            // Then update Firebase
            try await db.collection("expenses").document(expense.id).setData(expense.toDictionary())
        } catch {
            // If Firebase update fails, revert local changes
            await MainActor.run {
                // Trigger a refresh from Firebase to restore original state
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteExpense(_ expense: Expense) async {
        do {
            // Remove from local array immediately for instant UI update
            await MainActor.run {
                self.expenses.removeAll { $0.id == expense.id }
            }
            
            // Then delete from Firebase
            try await db.collection("expenses").document(expense.id).delete()
        } catch {
            // If Firebase delete fails, add back to local array
            await MainActor.run {
                self.expenses.insert(expense, at: 0)
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func totalSpentThisMonth() -> Double {
        return totalSpentForMonth(Date())
    }
    
    func totalSpentForMonth(_ selectedMonth: Date) -> Double {
        let calendar = Calendar.current
        
        return expenses
            .filter { calendar.isDate($0.expenseDate, equalTo: selectedMonth, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
    
    func spendingByCategory() -> [String: Double] {
        return spendingByCategoryForMonth(Date())
    }
    
    func spendingByCategoryForMonth(_ selectedMonth: Date) -> [String: Double] {
        let calendar = Calendar.current
        
        let monthlyExpenses = expenses.filter { 
            calendar.isDate($0.expenseDate, equalTo: selectedMonth, toGranularity: .month)
        }
        
        var categorySpending: [String: Double] = [:]
        for expense in monthlyExpenses {
            categorySpending[expense.category.rawValue, default: 0] += expense.amount
        }
        
        return categorySpending
    }
    
    func recentExpenses(limit: Int = 5) -> [Expense] {
        return recentExpensesForMonth(Date(), limit: limit)
    }
    
    func recentExpensesForMonth(_ selectedMonth: Date, limit: Int = 5) -> [Expense] {
        let calendar = Calendar.current
        
        let monthlyExpenses = expenses
            .filter { calendar.isDate($0.expenseDate, equalTo: selectedMonth, toGranularity: .month) }
            .sorted { $0.expenseDate > $1.expenseDate }
        
        return Array(monthlyExpenses.prefix(limit))
    }
    
    func dailySpendingForMonth(_ selectedMonth: Date) -> [Date: Double] {
        let calendar = Calendar.current
        
        let monthlyExpenses = expenses.filter { 
            calendar.isDate($0.expenseDate, equalTo: selectedMonth, toGranularity: .month)
        }
        
        var dailySpending: [Date: Double] = [:]
        
        for expense in monthlyExpenses {
            // Get the start of the day for the expense date
            let dayStart = calendar.startOfDay(for: expense.expenseDate)
            dailySpending[dayStart, default: 0] += expense.amount
        }
        
        return dailySpending
    }
    
    // MARK: - Helper Methods
    
    private func getUserFriendlyErrorMessage(_ error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        // Filter out Firebase indexing errors and other internal messages
        if errorDescription.contains("query requires an index") ||
           errorDescription.contains("create_composite") ||
           errorDescription.contains("firestore") ||
           errorDescription.contains("firebase") ||
           errorDescription.contains("console.firebase.google.com") {
            return "Unable to complete request. Please try again."
        }
        
        // Handle network connectivity issues
        if errorDescription.contains("network") ||
           errorDescription.contains("internet") ||
           errorDescription.contains("connection") {
            return "Please check your internet connection and try again."
        }
        
        // Handle account deletion specific errors
        if errorDescription.contains("requires-recent-login") ||
           errorDescription.contains("credential-too-old") {
            return "For security, please sign out and sign back in before deleting your account."
        }
        
        // Handle common Firebase Auth errors
        if let authError = error as NSError?, authError.domain == "FIRAuthErrorDomain" {
            switch authError.code {
            case 17007: // FIRAuthErrorCodeEmailAlreadyInUse
                return "This email is already in use"
            case 17008: // FIRAuthErrorCodeInvalidEmail
                return "Invalid email address"
            case 17026: // FIRAuthErrorCodeWeakPassword
                return "Password is too weak"
            case 17009: // FIRAuthErrorCodeWrongPassword
                return "Incorrect password"
            case 17011: // FIRAuthErrorCodeUserNotFound
                return "No account found with this email"
            case 17010: // FIRAuthErrorCodeInvalidCredential
                return "Invalid email or password"
            case 17020: // FIRAuthErrorCodeNetworkError
                return "Network error. Please check your connection."
            case 17999: // FIRAuthErrorCodeInternalError
                return "An unexpected error occurred. Please try again."
            default:
                return "Authentication failed. Please try again."
            }
        }
        
        // Generic fallback for unknown errors
        return "Something went wrong. Please try again."
    }
}
