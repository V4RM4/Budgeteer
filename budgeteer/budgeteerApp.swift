//
//  BudgeteerApp.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct BudgeteerApp: App {
    @StateObject private var darkModeManager = DarkModeManager.shared
    
    init() {
        FirebaseApp.configure()
        
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            fatalError("Could not load GoogleService-Info.plist or CLIENT_ID")
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        

    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(darkModeManager.isDarkMode ? .dark : .light)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("userSignedOut"))) { _ in
                    AppStateManager.shared.resetToSplash()
                }
        }
    }
}
