//
//  ContentView.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appStateManager = AppStateManager.shared
    @StateObject private var firebaseService = FirebaseService.shared
    
    var body: some View {
        ZStack {
            // Always show splash screen first
            SplashScreenView()
                .opacity(appStateManager.currentState == .splash ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: appStateManager.currentState)
            
            // Overlay the appropriate view based on state
            Group {
                switch appStateManager.currentState {
                case .splash:
                    Color.clear
                        .onAppear {
                            // Show splash for 2 seconds, then move to next state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    if firebaseService.isAuthenticated {
                                        appStateManager.showMain()
                                    } else if appStateManager.hasSeenWalkthrough {
                                        appStateManager.showAuthentication()
                                    } else {
                                        appStateManager.showWalkthrough()
                                    }
                                }
                            }
                        }
                    
                case .walkthrough:
                    WalkthroughView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("walkthroughCompleted"))) { _ in
                            appStateManager.completeWalkthrough()
                        }
                    
                case .authentication:
                    AuthenticationView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("userAuthenticated"))) { _ in
                            appStateManager.showMain()
                        }
                    
                case .main:
                    MainTabView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .opacity(appStateManager.currentState == .splash ? 0 : 1)
            .animation(.easeInOut(duration: 0.5), value: appStateManager.currentState)
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Dashboard")
                }
            
            ExpenseListView()
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("Expenses")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
}
