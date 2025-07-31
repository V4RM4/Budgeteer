//
//  AddExpenseView.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import SwiftUI
import PhotosUI
import CoreLocation

struct AddExpenseView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
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
    @State private var hasRequestedLocation = false
    @StateObject private var locationManager = LocationManager()
    
    private var isFormValid: Bool {
        let baseValid = !name.isEmpty && !amount.isEmpty && Double(amount) != nil && Double(amount)! > 0
        
        // If "Other" category is selected, custom name is required
        if selectedCategory == .other {
            return baseValid && !customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        return baseValid
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
                        
                        // Save Button
                        saveButtonSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .alert("Expense Added!", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your expense has been successfully added to your budget.")
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedPhoto, sourceType: imagePickerSourceType)
            }
            .confirmationDialog("Add Photo", isPresented: $showingActionSheet) {
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
                    hasRequestedLocation = true
                    locationManager.requestLocation()
                    print("Location button clicked, hasRequestedLocation: \(hasRequestedLocation)")
                    
                    // Add a small delay to allow location to be processed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let currentLocation = locationManager.locationString {
                            print("Setting location after delay: \(currentLocation)")
                            self.location = currentLocation
                        }
                    }
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
            // Only populate if user has clicked the location button
            if hasRequestedLocation, let newLocation = locationManager.locationString {
                print("Location updated via onChange: \(newLocation)")
                self.location = newLocation
            }
        }
        .onChange(of: locationManager.isLoading) {
            // When loading stops, check if we have location
            if !locationManager.isLoading && hasRequestedLocation {
                if let currentLocation = locationManager.locationString {
                    print("Location found after loading stopped: \(currentLocation)")
                    self.location = currentLocation
                }
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
                        Text("Photo attached")
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
                            Text("Add Photo")
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
    
    // MARK: - Save Button Section
    private var saveButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: saveExpense) {
                HStack(spacing: 12) {
                    if firebaseService.isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        
                        Text("Save Expense")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isFormValid ? Color.blue : Color(.systemGray4))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!isFormValid || firebaseService.isLoading)
            .scaleEffect(firebaseService.isLoading ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: firebaseService.isLoading)
            
            if !isFormValid {
                Text("Please fill in all required fields")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Functions
    
    private func saveExpense() {
        guard let userId = firebaseService.user?.id,
              let amountValue = Double(amount) else { return }
        
        Task {
            var photoURL: String? = nil
            
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
            
            if let selectedPhoto = selectedPhoto {
                let expenseId = UUID().uuidString
                photoURL = await firebaseService.uploadExpensePhoto(selectedPhoto, expenseId: expenseId)
                
                let expense = Expense(
                    id: expenseId,
                    userId: userId,
                    name: name,
                    amount: amountValue,
                    category: selectedCategory,
                    expenseDate: finalExpenseDate,
                    description: description.isEmpty ? nil : description,
                    photoURL: photoURL,
                    location: location.isEmpty ? nil : location,
                    customCategoryName: customCategory
                )
                
                await firebaseService.addExpense(expense)
            } else {
                let expense = Expense(
                    userId: userId,
                    name: name,
                    amount: amountValue,
                    category: selectedCategory,
                    expenseDate: finalExpenseDate,
                    description: description.isEmpty ? nil : description,
                    photoURL: nil,
                    location: location.isEmpty ? nil : location,
                    customCategoryName: customCategory
                )
                
                await firebaseService.addExpense(expense)
            }
            
            await MainActor.run {
                showingSuccessAlert = true
                
                self.name = ""
                self.amount = ""
                self.description = ""
                self.location = ""
                self.customCategoryName = ""
                self.selectedPhoto = nil
                self.expenseDate = Date()
                self.expenseTime = Date()
                self.selectedCategory = .food
            }
        }
    }
}

// MARK: - Modern Category Button
struct ModernCategoryButton: View {
    let category: ExpenseCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : getCategoryColor())
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 90)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [getCategoryColor(), getCategoryColor().opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(.systemGray6)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? getCategoryColor() : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(color: isSelected ? getCategoryColor().opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getCategoryColor() -> Color {
        switch category.color {
        case "orange": return .orange
        case "blue": return .blue
        case "pink": return .pink
        case "purple": return .purple
        case "yellow": return .yellow
        case "red": return .red
        case "green": return .green
        default: return .gray
        }
    }
}

#Preview {
    AddExpenseView()
}
