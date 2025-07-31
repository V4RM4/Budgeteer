//
//  AppStateManager.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-01-27.
//

import SwiftUI
import Foundation

enum AppState {
    case splash
    case walkthrough
    case authentication
    case main
}

@MainActor
class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    @Published var currentState: AppState = .splash
    @Published var hasSeenWalkthrough = false
    
    private let firebaseService = FirebaseService.shared
    
    private init() {
        // Check if user has seen walkthrough
        hasSeenWalkthrough = UserDefaults.standard.bool(forKey: "hasSeenWalkthrough")
        
        // Always start with splash screen for smooth transition
        currentState = .splash
    }
    
    func showSplash() {
        currentState = .splash
    }
    
    func showWalkthrough() {
        currentState = .walkthrough
    }
    
    func showAuthentication() {
        currentState = .authentication
        hasSeenWalkthrough = true
        UserDefaults.standard.set(true, forKey: "hasSeenWalkthrough")
    }
    
    func showMain() {
        currentState = .main
    }
    
    func completeWalkthrough() {
        hasSeenWalkthrough = true
        UserDefaults.standard.set(true, forKey: "hasSeenWalkthrough")
        showAuthentication()
    }
    
    func resetToSplash() {
        currentState = .splash
        hasSeenWalkthrough = false
        UserDefaults.standard.set(false, forKey: "hasSeenWalkthrough")
    }
} 