//
//  WalkthroughView.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-01-27.
//

import SwiftUI

struct WalkthroughView: View {
    @State private var currentPage = 0
    
    private let walkthroughData = [
        WalkthroughPage(
            title: "Track Your Expenses",
            subtitle: "Easily log your daily expenses with categories and photos",
            icon: "chart.bar.fill",
            color: .blue
        ),
        WalkthroughPage(
            title: "Smart Budget Management",
            subtitle: "Set monthly budgets and get insights into your spending patterns",
            icon: "creditcard.fill",
            color: .green
        ),
        WalkthroughPage(
            title: "Beautiful Analytics",
            subtitle: "Visualize your spending with charts and detailed reports",
            icon: "chart.pie.fill",
            color: .purple
        ),
        WalkthroughPage(
            title: "Secure & Private",
            subtitle: "Your financial data is protected with industry-standard security",
            icon: "lock.shield.fill",
            color: .orange
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                // Ensure smooth transition from splash
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        // Any additional entrance animations can go here
                    }
                }
            }
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                                            Button("Skip") {
                            NotificationCenter.default.post(name: Notification.Name("walkthroughCompleted"), object: nil)
                        }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<walkthroughData.count, id: \.self) { index in
                        WalkthroughPageView(page: walkthroughData[index])
                            .tag(index)
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        let threshold: CGFloat = 50
                                        if value.translation.width < -threshold && currentPage < walkthroughData.count - 1 {
                                            withAnimation {
                                                currentPage += 1
                                            }
                                        } else if value.translation.width > threshold && currentPage > 0 {
                                            withAnimation {
                                                currentPage -= 1
                                            }
                                        }
                                    }
                            )
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Page indicators - always show
                    HStack(spacing: 8) {
                        ForEach(0..<walkthroughData.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.primary : Color.secondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }
                    
                    // Get Started button - only show on last page
                    if currentPage == walkthroughData.count - 1 {
                        Button(action: {
                            NotificationCenter.default.post(name: Notification.Name("walkthroughCompleted"), object: nil)
                        }) {
                            HStack {
                                Text("Get Started")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 40)
            }
        }

    }
}

struct WalkthroughPageView: View {
    let page: WalkthroughPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Circle()
                .fill(page.color.gradient)
                .frame(width: 120, height: 120)
                .overlay {
                    Image(systemName: page.icon)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(.white)
                }
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct WalkthroughPage {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

#Preview {
    WalkthroughView()
} 