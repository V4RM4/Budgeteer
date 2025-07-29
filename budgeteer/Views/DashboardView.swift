//
//  DashboardView.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import SwiftUI
#if canImport(Charts)
import Charts
#endif

struct DashboardView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var showingAddExpense = false
    @State private var selectedMonth = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Month Selector
                    monthSelector
                    
                    // Budget Overview Card
                    budgetOverviewCard
                    
                    // Spending Chart
                    spendingChartCard
                    
                    // Recent Expenses
                    recentExpensesCard
                    
                    Spacer(minLength: 100) // Space for floating button
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .overlay(
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddExpense = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 30)
                    }
                }
            )
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
        }
    }
    
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text(firebaseService.user?.username ?? "User")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Profile image placeholder
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(firebaseService.user?.username.prefix(1).uppercased() ?? "U")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
        }
        .padding(.horizontal, 4)
    }
    
    private var monthSelector: some View {
        VStack(spacing: 8) {
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var budgetOverviewCard: some View {
        let totalSpent = firebaseService.totalSpentForMonth(selectedMonth)
        let budget = firebaseService.user?.monthlyBudget ?? 1000
        let remaining = budget - totalSpent
        let progress = min(totalSpent / budget, 1.0)
        
        return VStack(spacing: 16) {
            HStack {
                Text("Monthly Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(DateFormatter.monthYear.string(from: selectedMonth))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress Bar
            VStack(spacing: 8) {
                HStack {
                    Text("$\(Int(totalSpent))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(progress > 0.8 ? .red : .primary)
                    
                    Text("of $\(Int(budget))")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(CustomProgressViewStyle(color: progress > 0.8 ? .red : .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                HStack {
                    Text(remaining >= 0 ? "$\(Int(remaining)) left" : "Over budget by $\(Int(abs(remaining)))")
                        .font(.subheadline)
                        .foregroundColor(remaining >= 0 ? .green : .red)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var spendingChartCard: some View {
        let categoryData = firebaseService.spendingByCategoryForMonth(selectedMonth)
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category")
                .font(.headline)
                .fontWeight(.semibold)
            
            if categoryData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No expenses this month")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
            } else {
                // Chart view for iOS 16+
                if #available(iOS 16.0, *) {
                    #if canImport(Charts)
                    Chart {
                        ForEach(categoryData.sorted(by: { $0.value > $1.value }), id: \.key) { category, amount in
                            SectorMark(
                            angle: .value("Amount", amount),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(self.getColorForCategory(category))
                        .opacity(0.8)
                        }
                    }
                    .frame(height: 200)
                    #else
                    // Fallback for when Charts is not available
                    alternativeChartView(categoryData: categoryData)
                    #endif
                } else {
                    // Fallback for iOS < 16
                    alternativeChartView(categoryData: categoryData)
                }
                
                // Legend
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(categoryData.sorted(by: { $0.value > $1.value }), id: \.key) { category, amount in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(self.getColorForCategory(category))
                                .frame(width: 12, height: 12)
                            
                            Text(category)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("$\(Int(amount))")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var recentExpensesCard: some View {
        let recentExpenses = firebaseService.recentExpensesForMonth(selectedMonth)
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Expenses")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                NavigationLink("See All") {
                    ExpenseListView()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if recentExpenses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No expenses yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Tap the + button to add your first expense")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    ForEach(recentExpenses) { expense in
                        ExpenseRowView(expense: expense)
                        
                        if expense.id != recentExpenses.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func alternativeChartView(categoryData: [String: Double]) -> some View {
        VStack(spacing: 16) {
            // Simple bar chart representation
            VStack(spacing: 8) {
                ForEach(categoryData.sorted(by: { $0.value > $1.value }).prefix(5), id: \.key) { category, amount in
                    let maxAmount = categoryData.values.max() ?? 1
                    let percentage = amount / maxAmount
                    
                    HStack {
                        Text(category)
                            .font(.caption)
                            .frame(width: 80, alignment: .leading)
                        
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 20)
                            
                            Rectangle()
                                .fill(self.getColorForCategory(category))
                                .frame(width: percentage * 150, height: 20)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        Text("$\(Int(amount))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .frame(height: 200)
    }
    
    private func getColorForCategory(_ categoryName: String) -> Color {
        if let category = ExpenseCategory.allCases.first(where: { $0.rawValue == categoryName }) {
            return getColorForCategory(category)
        }
        return .gray
    }
    
    private func getColorForCategory(_ category: ExpenseCategory) -> Color {
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

struct CustomProgressViewStyle: ProgressViewStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
            
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.7)]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(width: (configuration.fractionCompleted ?? 0) * UIScreen.main.bounds.width * 0.8)
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: expense.category.icon)
                .font(.title2)
                .foregroundColor(getColorForCategory(expense.category))
                .frame(width: 32, height: 32)
                .background(getColorForCategory(expense.category).opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(expense.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", expense.amount))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(DateFormatter.shortDate.string(from: expense.expenseDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func getColorForCategory(_ category: ExpenseCategory) -> Color {
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


extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

#Preview {
    DashboardView()
}
