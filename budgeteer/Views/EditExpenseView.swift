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
                    VStack(spacing: 24) {
                        formCard
                        
                        categoryCard
                        
                        dateCard
                        
                        locationCard
                        
                        photoCard
                        
                        descriptionCard
                        
                        updateButton
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
                name = expense.name
                amount = String(format: "%.2f", expense.amount)
                selectedCategory = expense.category
                description = expense.description ?? ""
                location = expense.location ?? ""
                customCategoryName = expense.customCategoryName ?? ""
                
                let calendar = Calendar.current
                expenseDate = calendar.startOfDay(for: expense.expenseDate)
                expenseTime = expense.expenseDate
            }
            .onAppear {
                // Pre-populate form with existing expense data
                name = expense.name
                amount = String(format: "%.2f", expense.amount)
                selectedCategory = expense.category
                expenseDate = expense.expenseDate
                description = expense.description ?? ""
                location = expense.location ?? ""
                
                // Load existing photo if available
                if let photoURL = expense.photoURL {
                    loadImageFromURL(photoURL)
                }
            }
        }
    }
    
    // MARK: - Static Computed Properties
    
    private var headerCard: some View {
        VStack(spacing: 8) {
            Text("Edit Expense")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Update your expense details")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
    
    private var formCard: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Expense Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                TextField("e.g., Coffee, Lunch, Gas", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("$")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(ExpenseCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                            if category != .other {
                                customCategoryName = ""
                            }
                        }
                    }
                }
            }
            
            if selectedCategory == .other {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Category Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter category name", text: $customCategoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var dateCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date & Time")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $expenseDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $expenseTime, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location (Optional)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("Enter location...", text: $location)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    locationManager.requestLocation()
                }) {
                    Image(systemName: "location.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(locationManager.isLoading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onChange(of: locationManager.locationString) {
            if let newLocation = locationManager.locationString {
                self.location = newLocation
            }
        }
    }
    
    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Receipt Photo (Optional)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            if let selectedPhoto = selectedPhoto {
                HStack {
                    Image(uiImage: selectedPhoto)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading) {
                        Text("Photo updated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Change Photo") {
                            showingActionSheet = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        self.selectedPhoto = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            } else {
                Button(action: {
                    showingActionSheet = true
                }) {
                    HStack {
                        Image(systemName: "camera.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text(expense.photoURL != nil ? "Update Photo" : "Add Photo")
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description (Optional)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            TextField("Add a note about this expense...", text: $description, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var updateButton: some View {
        Button(action: updateExpense) {
            HStack {
                if firebaseService.isLoading {
                    ProgressView()
                        .scaleEffect(0.9)
                } else {
                    Text("Update Expense")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!(isFormValid && hasChanges) || firebaseService.isLoading)
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