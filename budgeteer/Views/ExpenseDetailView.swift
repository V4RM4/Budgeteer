//
//  ExpenseDetailView.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-31.
//

import SwiftUI

struct ExpenseDetailView: View {
    let expenseId: String
    @StateObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingImageViewer = false
    
    // Computed property to get the current expense from Firebase
    private var expense: Expense? {
        firebaseService.expenses.first { $0.id == expenseId }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let expense = expense {
                    ScrollView {
                        VStack(spacing: 24) {
                            headerCard
                            
                            detailsSection
                            
                            if expense.photoURL != nil {
                                photoSection
                            }
                            
                            Spacer(minLength: 20)
                        }
                        .padding()
                    }
                    .sheet(isPresented: $showingEditSheet) {
                        EditExpenseView(expense: expense)
                    }
                    .sheet(isPresented: $showingImageViewer) {
                        if let photoURL = expense.photoURL {
                            ImageViewerSheet(imageURL: photoURL)
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button {
                                    showingEditSheet = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .alert("Delete Expense", isPresented: $showingDeleteAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            deleteExpense()
                        }
                    } message: {
                        Text("Are you sure you want to delete this expense? This action cannot be undone.")
                    }
                } else {
                    // Show error state if expense not found
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Expense Not Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("This expense may have been deleted or is no longer available.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Expense Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerCard: some View {
        Group {
            if let expense = expense {
                VStack(spacing: 16) {
                    // Category Icon and Amount
                    HStack {
                        Image(systemName: expense.category.icon)
                            .font(.system(size: 32))
                            .foregroundColor(getCategoryColor())
                            .frame(width: 60, height: 60)
                            .background(getCategoryColor().opacity(0.15))
                            .clipShape(Circle())
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("$\(String(format: "%.2f", expense.amount))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Amount")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Expense Name
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Expense")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        Text(expense.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            }
        }
    }
    
    private var detailsSection: some View {
        Group {
            if let expense = expense {
                VStack(spacing: 16) {
                    // Section Header
                    HStack {
                        Text("Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        // Category
                        DetailRow(
                            title: "Category",
                            value: expense.categoryDisplayName,
                            icon: "tag.fill",
                            iconColor: getCategoryColor()
                        )
                        
                        // Date & Time
                        DetailRow(
                            title: "Date & Time",
                            value: "\(DateFormatter.fullDate.string(from: expense.expenseDate)) at \(DateFormatter.timeFormat.string(from: expense.expenseDate))",
                            icon: "calendar",
                            iconColor: .blue
                        )
                        
                        // Location (if available)
                        if let location = expense.location, !location.isEmpty {
                            DetailRow(
                                title: "Location",
                                value: location,
                                icon: "location.fill",
                                iconColor: .green
                            )
                        }
                        
                        // Description (if available)
                        if let description = expense.description, !description.isEmpty {
                            DetailRow(
                                title: "Description",
                                value: description,
                                icon: "text.bubble.fill",
                                iconColor: .orange,
                                isMultiline: true
                            )
                        }
                        
                        // Created Date
                        DetailRow(
                            title: "Created",
                            value: DateFormatter.fullDateTime.string(from: expense.createdAt),
                            icon: "clock.fill",
                            iconColor: .secondary
                        )
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            }
        }
    }
    
    private var photoSection: some View {
        Group {
            if let expense = expense {
                VStack(spacing: 16) {
                    // Section Header
                    HStack {
                        Text("Receipt Photo")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        
                        Button("View Full Size") {
                            showingImageViewer = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    // Photo Preview
                    if let photoURL = expense.photoURL {
                        AsyncImage(url: URL(string: photoURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .onTapGesture {
                                    showingImageViewer = true
                                }
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(height: 200)
                                .overlay(
                                    ProgressView()
                                )
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            }
        }
    }
    
    private func getCategoryColor() -> Color {
        guard let expense = expense else { return .gray }
        switch expense.category.color {
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
    
    private func deleteExpense() {
        guard let expense = expense else { return }
        Task {
            await firebaseService.deleteExpense(expense)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    var isMultiline: Bool = false
    
    var body: some View {
        HStack(alignment: isMultiline ? .top : .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .fontWeight(.semibold)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(isMultiline ? nil : 1)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ImageViewerSheet: View {
    let imageURL: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZoomableImageView(imageURL: imageURL)
                .background(Color.black)
                .navigationTitle("Receipt")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                }
        }
    }
}

struct ZoomableImageView: View {
    let imageURL: String
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale < 1.0 {
                                        withAnimation(.spring()) {
                                            scale = 1.0
                                            lastScale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    } else if scale > 3.0 {
                                        withAnimation(.spring()) {
                                            scale = 3.0
                                            lastScale = 3.0
                                        }
                                    }
                                },
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            if scale > 1.0 {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.0
                                lastScale = 2.0
                            }
                        }
                    }
            } placeholder: {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    ExpenseDetailView(expenseId: "preview-expense-id")
}
