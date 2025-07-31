//
//  BudgeteerApp.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import SwiftUI
import Firebase

@main
struct BudgeteerApp: App {
    @StateObject private var darkModeManager = DarkModeManager.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(darkModeManager.isDarkMode ? .dark : .light)
        }
    }
}
