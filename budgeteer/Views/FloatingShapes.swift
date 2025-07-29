//
//  FloatingShapes.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import SwiftUI

struct FloatingShapes: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Floating circles
            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 120, height: 120)
                .position(x: 80, y: 200)
                .offset(y: animate ? -20 : 20)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animate)
            
            Circle()
                .fill(.white.opacity(0.03))
                .frame(width: 80, height: 80)
                .position(x: 300, y: 150)
                .offset(y: animate ? 15 : -15)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animate)
            
            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: 60, height: 60)
                .position(x: 350, y: 400)
                .offset(y: animate ? -25 : 25)
                .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: animate)
            
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.02))
                .frame(width: 100, height: 100)
                .position(x: 50, y: 500)
                .rotationEffect(.degrees(animate ? 10 : -10))
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animate)
        }
        .onAppear {
            animate = true
        }
    }
}
