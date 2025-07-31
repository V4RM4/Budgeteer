//
//  User.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    let id: String
    var email: String
    var username: String
    var monthlyBudget: Double
    let createdAt: Date
    
    init(id: String, email: String, username: String, monthlyBudget: Double = 1000.0, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.username = username
        self.monthlyBudget = monthlyBudget
        self.createdAt = createdAt
    }
}

extension User {
    // Converts the user object to a dictionary suitable for Firestore storage.
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "email": email,
            "username": username,
            "monthlyBudget": monthlyBudget,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
    
    // Creates a user object from a Firestore dictionary.
    // Returns User object if the dictionary contains valid data, nil otherwise.
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
