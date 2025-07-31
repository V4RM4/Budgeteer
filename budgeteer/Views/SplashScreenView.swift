//
//  SplashScreenView.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-01-27.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var isAnimating = false
    
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
            
            // App logo only
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.blue.gradient)
                .frame(width: 120, height: 120)
                .overlay {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 54, weight: .medium))
                        .foregroundStyle(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Set animation state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAnimating = true
        }
        
        // Add a subtle pulse animation
        withAnimation(.easeInOut(duration: 1.0).repeatCount(2, autoreverses: true).delay(1.0)) {
            logoScale = 1.05
        }
    }
}

#Preview {
    SplashScreenView()
} 