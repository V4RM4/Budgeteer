//
//  EditExpenseView.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import SwiftUI
import PhotosUI
import CoreLocation

struct EditExpenseView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let expense: Expense
    
    @State private var name = ""
    @State private var amount = ""
    @State private var selectedCategory = ExpenseCategory.food
    @State private var expenseDate = Date()
    @State private var expenseTime = Date()
    @State private var description = ""
    @State private var location = ""
    @State private var customCategoryName = ""
    @State private var selectedPhoto: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingSuccessAlert = false
    @StateObject private var locationManager = LocationManager()
    
    var isFormValid: Bool {
        let baseValid = !name.isEmpty && !amount.isEmpty && Double(amount) != nil
        
        // If "Other" category is selected, custom name is required
        if selectedCategory == .other {
            return baseValid && !customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        return baseValid
    }
    
    var hasChanges: Bool {
        let calendar = Calendar.current
        let originalDateTime = expense.expenseDate
        
        // Combine current date and time selections
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: expenseDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: expenseTime)
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        let currentDateTime = calendar.date(from: combinedComponents) ?? expenseDate
        
        return name != expense.name ||
        amount != String(format: "%.2f", expense.amount) ||
        selectedCategory != expense.category ||
        abs(currentDateTime.timeIntervalSince(originalDateTime)) > 60 || // 1 minute tolerance
        description != (expense.description ?? "") ||
        location != (expense.location ?? "") ||
        customCategoryName != (expense.customCategoryName ?? "") ||
        selectedPhoto != nil ||
        (expense.photoURL != nil && selectedPhoto == nil)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Main Form Section
                        VStack(spacing: 16) {
                            expenseNameSection
                            amountSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        
                        // Category Section
                        categorySection
                        
                        // Date & Time Section
                        dateTimeSection
                        
                        // Optional Sections
                        VStack(spacing: 16) {
                            locationSection
                            photoSection
                            descriptionSection
                        }
                        
                        // Update Button
                        updateButtonSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .alert("Expense Updated!", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your expense has been successfully updated.")
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedPhoto, sourceType: imagePickerSourceType)
            }
            .confirmationDialog("Update Photo", isPresented: $showingActionSheet) {
                Button("Camera") {
                    imagePickerSourceType = .camera
                    showingImagePicker = true
                }
                Button("Photo Library") {
                    imagePickerSourceType = .photoLibrary
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .onAppear {
                // Pre-populate form with existing expense data
                name = expense.name
                amount = String(format: "%.2f", expense.amount)
                selectedCategory = expense.category
                expenseDate = expense.expenseDate
                description = expense.description ?? ""
                location = expense.location ?? ""
                customCategoryName = expense.customCategoryName ?? ""
                
                let calendar = Calendar.current
                expenseDate = calendar.startOfDay(for: expense.expenseDate)
                expenseTime = expense.expenseDate
                
                // Load existing photo if available
                if let photoURL = expense.photoURL {
                    loadImageFromURL(photoURL)
                }
            }
        }
    }
    
    // MARK: - Form Sections
    private var expenseNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Expense Name")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            TextField("e.g., Coffee, Lunch, Gas", text: $name)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }
    
    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                
                Text("Amount")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            HStack(spacing: 0) {
                Text("$")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)
                
                TextField("0.00", text: $amount)
                    .font(.title)
                    .fontWeight(.semibold)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                Text("Category")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(ExpenseCategory.allCases, id: \.self) { category in
                    ModernCategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedCategory = category
                            if category != .other {
                                customCategoryName = ""
                            }
                        }
                    }
                }
            }
            
            if selectedCategory == .other {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundColor(.purple)
                        
                        Text("Custom Category")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    TextField("Enter category name", text: $customCategoryName)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Date & Time Section
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red)
                
                Text("Date & Time")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $expenseDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $expenseTime, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Optional Sections
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Location (Optional)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            HStack(spacing: 12) {
                TextField("Enter location...", text: $location)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                
                Button(action: {
                    locationManager.requestLocation()
                }) {
                    Image(systemName: "location.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .disabled(locationManager.isLoading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onChange(of: locationManager.locationString) {
            if let newLocation = locationManager.locationString {
                self.location = newLocation
            }
        }
    }
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "camera.circle.fill")
                    .font(.title3)
                    .foregroundColor(.purple)
                
                Text("Receipt Photo (Optional)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            if let selectedPhoto = selectedPhoto {
                HStack(spacing: 16) {
                    Image(uiImage: selectedPhoto)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Photo updated")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Button("Change Photo") {
                            showingActionSheet = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            self.selectedPhoto = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            } else {
                Button(action: {
                    showingActionSheet = true
                }) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(expense.photoURL != nil ? "Update Photo" : "Add Photo")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Capture or select a receipt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "line.3.horizontal.circle.fill")
                    .font(.title3)
                    .foregroundColor(.indigo)
                
                Text("Description (Optional)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            TextField("Add a note about this expense...", text: $description, axis: .vertical)
                .font(.body)
                .lineLimit(3...6)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Update Button Section
    private var updateButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: updateExpense) {
                HStack(spacing: 12) {
                    if firebaseService.isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        
                        Text("Update Expense")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background((isFormValid && hasChanges) ? Color.orange : Color(.systemGray4))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!(isFormValid && hasChanges) || firebaseService.isLoading)
            .scaleEffect(firebaseService.isLoading ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: firebaseService.isLoading)
            
            if !isFormValid {
                Text("Please fill in all required fields")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else if !hasChanges {
                Text("No changes detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Functions
    
    private func updateExpense() {
        guard let amountValue = Double(amount) else { return }
        
        Task {
            var photoURL: String? = expense.photoURL
            
            if let selectedPhoto = selectedPhoto {
                photoURL = await firebaseService.uploadExpensePhoto(selectedPhoto, expenseId: expense.id)
            }
            
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: expenseDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: expenseTime)
            
            var combinedComponents = DateComponents()
            combinedComponents.year = dateComponents.year
            combinedComponents.month = dateComponents.month
            combinedComponents.day = dateComponents.day
            combinedComponents.hour = timeComponents.hour
            combinedComponents.minute = timeComponents.minute
            
            let finalExpenseDate = calendar.date(from: combinedComponents) ?? expenseDate
            
            let customCategory = selectedCategory == .other && !customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines) : nil
            
            let updatedExpense = Expense(
                id: expense.id,
                userId: expense.userId,
                name: name,
                amount: amountValue,
                category: selectedCategory,
                expenseDate: finalExpenseDate,
                description: description.isEmpty ? nil : description,
                photoURL: photoURL,
                location: location.isEmpty ? nil : location,
                customCategoryName: customCategory,
                createdAt: expense.createdAt
            )
            
            await firebaseService.updateExpense(updatedExpense)
            
            await MainActor.run {
                showingSuccessAlert = true
            }
        }
    }
    
    private func loadImageFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let _ = UIImage(data: data) {
                DispatchQueue.main.async {
                    // Don't set selectedPhoto here as it would trigger hasChanges
                    // We'll show the existing photo through the URL instead
                }
            }
        }.resume()
    }
}

#Preview {
    let sampleExpense = Expense(
        userId: "sample",
        name: "Coffee",
        amount: 4.50,
        category: .food,
        description: "Morning coffee"
    )
    return EditExpenseView(expense: sampleExpense)
} 