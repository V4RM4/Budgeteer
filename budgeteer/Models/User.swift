//
//  User.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import Foundation
import FirebaseFirestore

/// A model representing a user account with profile information and budget settings.
struct User: Codable, Identifiable {
    /// Unique identifier for the user
    let id: String
    /// User's email address
    var email: String
    /// User's display name
    var username: String
    /// User's monthly budget limit
    var monthlyBudget: Double
    /// When this user account was created
    let createdAt: Date
    
    /// Creates a new user with the specified parameters.
    /// - Parameters:
    ///   - id: Unique identifier for the user.
    ///   - email: User's email address.
    ///   - username: User's display name.
    ///   - monthlyBudget: User's monthly budget limit. Defaults to 1000.0.
    ///   - createdAt: When this user account was created. Defaults to current date.
    init(id: String, email: String, username: String, monthlyBudget: Double = 1000.0, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.username = username
        self.monthlyBudget = monthlyBudget
        self.createdAt = createdAt
    }
}

extension User {
    /// Converts the user object to a dictionary suitable for Firestore storage.
    /// - Returns: A dictionary representation of the user object.
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "email": email,
            "username": username,
            "monthlyBudget": monthlyBudget,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
    
    /// Creates a user object from a Firestore dictionary.
    /// - Parameter dict: The dictionary containing user data from Firestore.
    /// - Returns: A User object if the dictionary contains valid data, nil otherwise.
    static func fromDictionary(_ dict: [String: Any]) -> User? {
        guard let id = dict["id"] as? String,
              let email = dict["email"] as? String,
              let username = dict["username"] as? String,
              let monthlyBudget = dict["monthlyBudget"] as? Double,
              let timestamp = dict["createdAt"] as? Timestamp else {
            return nil
        }
        
        return User(id: id, email: email, username: username, monthlyBudget: monthlyBudget, createdAt: timestamp.dateValue())
    }
}
