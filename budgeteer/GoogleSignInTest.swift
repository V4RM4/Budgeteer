//
//  GoogleSignInTest.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-01-27.
//

import Foundation
import GoogleSignIn
import FirebaseAuth

// Test class for Google Sign-In functionality
class GoogleSignInTest {
    
    static func testGoogleSignInConfiguration() {
        // Test 1: Check if Google Sign-In is configured
        let isConfigured = GIDSignIn.sharedInstance.configuration != nil
        print("Google Sign-In Configuration: \(isConfigured ? "PASSED" : "FAILED")")
        
        // Test 2: Check if we have a valid client ID
        if let configuration = GIDSignIn.sharedInstance.configuration {
            let hasClientID = !configuration.clientID.isEmpty
            print("Client ID Configuration: \(hasClientID ? "PASSED" : "FAILED")")
        }
        
        // Test 3: Check if user is already signed in
        let isSignedIn = GIDSignIn.sharedInstance.hasPreviousSignIn()
        print("Previous Sign-In Check: \(isSignedIn ? "User signed in" : "No previous sign-in")")
        
        // Test 4: Check Firebase Auth state
        let firebaseUser = Auth.auth().currentUser
        print("Firebase Auth State: \(firebaseUser != nil ? "User authenticated" : "No Firebase user")")
    }
    
    static func testURLSchemeConfiguration() {
        // Test URL scheme configuration
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String,
              let reversedClientId = plist["REVERSED_CLIENT_ID"] as? String else {
            print("GoogleService-Info.plist configuration: FAILED")
            return
        }
        
        print("GoogleService-Info.plist configuration: PASSED")
        print("   - Client ID: \(clientId)")
        print("   - Reversed Client ID: \(reversedClientId)")
    }
    
    static func runAllTests() {
        print("Running Google Sign-In Tests...")
        print("=====================================")
        
        testURLSchemeConfiguration()
        print("")
        testGoogleSignInConfiguration()
        
        print("=====================================")
        print("All tests completed!")
    }
}

// Usage in your app:
// GoogleSignInTest.runAllTests() 