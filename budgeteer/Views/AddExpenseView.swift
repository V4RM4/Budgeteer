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
                    VStack(spacing: 24) {
                        formCard
                        
                        categoryCard
                        
                        dateCard
                        
                        locationCard
                        
                        photoCard
                        
                        descriptionCard
                        
                        saveButton
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Expense Added!", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Click OK to continue")
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
    
    // MARK: - Static Computed Properties
    
    private var headerCard: some View {
        VStack(spacing: 8) {
            Text("New Expense")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Add details about your expense")
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
                        Text("Photo attached")
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
                        
                        Text("Add Photo")
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
    
    private var saveButton: some View {
        Button(action: saveExpense) {
            HStack {
                if firebaseService.isLoading {
                    ProgressView()
                        .scaleEffect(0.9)
                } else {
                    Text("Save Expense")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!isFormValid || firebaseService.isLoading)
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

struct CategoryButton: View {
    let category: ExpenseCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : getCategoryColor())
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 80)
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
                        getCategoryColor().opacity(0.1)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? getCategoryColor() : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
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
