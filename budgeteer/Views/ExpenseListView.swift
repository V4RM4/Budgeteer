//
//  ExpenseListView.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import SwiftUI

/// A view displaying a list of user expenses with search, filter, and management capabilities.
struct ExpenseListView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var searchText = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var selectedMonth = Date()
    @State private var showingFilters = false
    @State private var showingAddExpense = false
    @State private var expenseToEdit: Expense?
    @State private var showingExpenseDetail = false
    @State private var expenseIdToView: String?
    
    var filteredExpenses: [Expense] {
        var expenses = firebaseService.expenses
        
        // Filter by month
        let calendar = Calendar.current
        expenses = expenses.filter { expense in
            calendar.isDate(expense.expenseDate, equalTo: selectedMonth, toGranularity: .month)
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            expenses = expenses.filter { expense in
                expense.name.localizedCaseInsensitiveContains(searchText) ||
                expense.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
                expense.categoryDisplayName.localizedCaseInsensitiveContains(searchText) ||
                (expense.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (expense.location?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            expenses = expenses.filter { $0.category == selectedCategory }
        }
        
        return expenses
    }
    
    var groupedExpenses: [String: [Expense]] {
        Dictionary(grouping: filteredExpenses) { expense in
            DateFormatter.sectionDate.string(from: expense.expenseDate)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month Selector
                monthSelector
                
                // Search and Filter Bar
                searchAndFilterBar
                
                // Expenses List
                if filteredExpenses.isEmpty {
                    emptyStateView
                } else {
                    expensesList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddExpense = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(selectedCategory: $selectedCategory)
            }
            .sheet(item: $expenseToEdit) { expense in
                EditExpenseView(expense: expense)
            }
            .sheet(isPresented: $showingExpenseDetail) {
                if let expenseId = expenseIdToView {
                    ExpenseDetailView(expenseId: expenseId)
                }
            }
            .onChange(of: showingExpenseDetail) {
                if !showingExpenseDetail {
                    expenseIdToView = nil
                }
            }
        }
    }
    
    private var monthSelector: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Viewing expenses for")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(DateFormatter.monthYear.string(from: selectedMonth))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray4)),
            alignment: .bottom
        )
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search expenses...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Filter Button
                Button(action: { showingFilters = true }) {
                    Image(systemName: selectedCategory != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(selectedCategory != nil ? .blue : .gray)
                }
            }
            
            // Active Filter Chip
            if let selectedCategory = selectedCategory {
                HStack {
                    FilterChip(category: selectedCategory) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            self.selectedCategory = nil
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    private var expensesList: some View {
        List {
            ForEach(groupedExpenses.keys.sorted(by: >), id: \.self) { dateKey in
                Section(dateKey) {
                    ForEach(groupedExpenses[dateKey] ?? []) { expense in
                        ExpenseListRowView(expense: expense)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                expenseIdToView = expense.id
                                showingExpenseDetail = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button("Delete", role: .destructive) {
                                    deleteExpense(expense)
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button("Edit") {
                                    expenseToEdit = expense
                                }
                                .tint(.orange)
                            }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "list.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No expenses found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(searchText.isEmpty ? "Start tracking your expenses by adding your first expense." : "Try adjusting your search or filters.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if searchText.isEmpty && selectedCategory == nil {
                Button(action: { showingAddExpense = true }) {
                    Text("Add Your First Expense")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func deleteExpense(_ expense: Expense) {
        Task {
            await firebaseService.deleteExpense(expense)
        }
    }
}

struct ExpenseListRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: expense.category.icon)
                .font(.title2)
                .foregroundColor(getCategoryColor())
                .frame(width: 36, height: 36)
                .background(getCategoryColor().opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                // Location (if available)
                if let location = expense.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                HStack(spacing: 8) {
                    // Category tag with capsule styling
                    Text(expense.categoryDisplayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(getCategoryColor().opacity(0.15))
                        .foregroundColor(getCategoryColor())
                        .clipShape(Capsule())
                    
                    if expense.photoURL != nil {
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", expense.amount))")
                    .font(.body)
                    .fontWeight(.semibold)
                
                Text(DateFormatter.timeFormat.string(from: expense.expenseDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func getCategoryColor() -> Color {
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
}

struct FilterView: View {
    @Binding var selectedCategory: ExpenseCategory?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Filter Expenses")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Filter by category to find specific expenses")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Category Filters
                VStack(alignment: .leading, spacing: 16) {
                    Text("Category")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        // All Categories Option
                        FilterCategoryButton(
                            title: "All Categories",
                            icon: "list.bullet",
                            color: .gray,
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }
                        
                        // Individual Categories
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            FilterCategoryButton(
                                title: category.rawValue,
                                icon: category.icon,
                                color: getCategoryColor(category),
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Apply Button
                Button("Apply Filters") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.blue)
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        selectedCategory = nil
                    }
                    .disabled(selectedCategory == nil)
                }
            }
        }
    }
    
    private func getCategoryColor(_ category: ExpenseCategory) -> Color {
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

struct FilterCategoryButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        color
                    } else {
                        color.opacity(0.1)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let category: ExpenseCategory
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .font(.caption)
            
            Text(category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(getCategoryColor().opacity(0.15))
        .foregroundColor(getCategoryColor())
        .clipShape(Capsule())
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
    ExpenseListView()
}
