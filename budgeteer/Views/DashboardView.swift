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

/// The main dashboard view displaying expense summaries, budgets, and charts.
struct DashboardView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var showingAddExpense = false
    @State private var selectedMonth = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    welcomeHeader
                    
                    monthSelector
                    
                    budgetOverviewCard
                    
                    spendingChartCard
                    
                    spendingTrendsCard
                    
                    recentExpensesCard
                    
                    Spacer(minLength: 100) // Space for floating button
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .overlay(
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddExpense = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
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
            Button(action: {
                // Future: Navigate to profile/settings
            }) {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(firebaseService.user?.username.prefix(1).uppercased() ?? "U")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    )
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
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
        let budget = max(firebaseService.user?.monthlyBudget ?? 1000, 1.0) // Prevent division by zero
        let remaining = budget - totalSpent
        let progress = max(0.0, min(totalSpent / budget, 2.0)) // Allow over-budget display up to 200%
        
        // Calculate daily average
        let calendar = Calendar.current
        let today = Date()
        let isCurrentMonth = calendar.isDate(selectedMonth, equalTo: today, toGranularity: .month)
        
        let daysToUse: Int
        if isCurrentMonth {
            // For current month - days passed so far (minimum 1)
            daysToUse = max(calendar.component(.day, from: today), 1)
        } else {
            // For past/future months - total days in month
            daysToUse = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        }
        
        let dailyAvg = daysToUse > 0 ? totalSpent / Double(daysToUse) : 0.0
        
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
            VStack(spacing: 12) {
                HStack {
                    Text("$\(String(format: "%.0f", totalSpent))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(progress > 0.8 ? .red : .primary)
                    
                    Text("of $\(String(format: "%.0f", budget))")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(progress > 0.8 ? .red : .blue)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(CustomProgressViewStyle(color: progress > 0.8 ? .red : .blue))
                    .scaleEffect(x: 1, y: 2.5, anchor: .center)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(remaining >= 0 ? "Budget Remaining" : "Over Budget")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(remaining >= 0 ? "$\(String(format: "%.0f", remaining))" : "$\(String(format: "%.0f", abs(remaining)))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(remaining >= 0 ? .green : .red)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Daily Average")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("$\(String(format: "%.0f", dailyAvg))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.top, 4)
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
                    Image(systemName: "chart.bar")
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
                                angularInset: 1.0
                            )
                            .foregroundStyle(self.getColorForCategory(category))
                            .opacity(0.9)
                        }
                    }
                    .frame(height: 240)
                    .chartBackground { chartProxy in
                        GeometryReader { geometry in
                            if let plotFrame = chartProxy.plotFrame {
                                let frame = geometry[plotFrame]
                                VStack {
                                    Text("Total")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("$\(Int(categoryData.values.reduce(0, +)))")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                                .position(x: frame.midX, y: frame.midY)
                            }
                        }
                    }
                    #else
                    // Fallback for when Charts is not available
                    alternativeChartView(categoryData: categoryData)
                    #endif
                } else {
                    // Fallback for iOS < 16
                    alternativeChartView(categoryData: categoryData)
                }
                
                // Legend
                let totalAmount = categoryData.values.reduce(0, +)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(categoryData.sorted(by: { $0.value > $1.value }), id: \.key) { category, amount in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(self.getColorForCategory(category))
                                .frame(width: 14, height: 14)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 4) {
                                    Text("$\(Int(amount))")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text("(\(String(format: "%.1f", (amount / totalAmount) * 100))%)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
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
    
    private var spendingTrendsCard: some View {
        let dailySpending = firebaseService.dailySpendingForMonth(selectedMonth)
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            if dailySpending.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No spending data this month")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
            } else {
                if #available(iOS 16.0, *) {
                    #if canImport(Charts)
                    Chart {
                        ForEach(dailySpending.sorted(by: { $0.key < $1.key }), id: \.key) { date, amount in
                            LineMark(
                                x: .value("Date", date),
                                y: .value("Amount", amount)
                            )
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            
                            AreaMark(
                                x: .value("Date", date),
                                y: .value("Amount", amount)
                            )
                            .foregroundStyle(.blue.opacity(0.1))
                        }
                    }
                    .frame(height: 150)
                    .chartYScale(domain: .automatic(includesZero: true))
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 5)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day())
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let doubleValue = value.as(Double.self) {
                                    Text("$\(Int(doubleValue))")
                                }
                            }
                        }
                    }
                    #else
                    alternativeLineChartView(dailySpending: dailySpending)
                    #endif
                } else {
                    alternativeLineChartView(dailySpending: dailySpending)
                }
                
                // Summary stats
                let totalDays = dailySpending.count
                let avgDaily = dailySpending.values.reduce(0, +) / Double(max(totalDays, 1))
                let maxDaily = dailySpending.values.max() ?? 0
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Avg Daily")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.0f", avgDaily))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Max Daily")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.0f", maxDaily))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Active Days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(totalDays)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .padding(.top, 8)
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
    
    private func alternativeLineChartView(dailySpending: [Date: Double]) -> some View {
        let sortedData = dailySpending.sorted(by: { $0.key < $1.key })
        let maxAmount = dailySpending.values.max() ?? 1
        
        return VStack(spacing: 12) {
            // Simple line chart representation using rectangles
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(Array(sortedData.enumerated()), id: \.offset) { index, data in
                    let (date, amount) = data
                    let height = (amount / maxAmount) * 100
                    
                    VStack {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue, .blue.opacity(0.6)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(width: 8, height: max(height, 2))
                        
                        if index % 3 == 0 {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 120)
        }
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
        let maxWidth = UIScreen.main.bounds.width * 0.75
        let progress = configuration.fractionCompleted ?? 0
        let clampedProgress = min(progress, 1.0) // Cap at 100% visual width
        
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 12)
            
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(width: clampedProgress * maxWidth, height: 12)
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
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
