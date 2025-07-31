//
//  ContentView.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import SwiftUI

/// The root view that manages authentication state and displays appropriate content.
struct ContentView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    
    var body: some View {
        Group {
            if firebaseService.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: firebaseService.isAuthenticated)
    }
}

/// The main tab view containing the primary app navigation.
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
