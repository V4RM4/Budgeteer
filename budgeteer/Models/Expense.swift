//
//  Expense.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import Foundation
import FirebaseFirestore

struct Expense: Codable, Identifiable {
    let id: String
    let userId: String
    var name: String
    var amount: Double
    var category: ExpenseCategory
    let createdAt: Date
    var expenseDate: Date
    var description: String?
    var photoURL: String?
    var location: String?
    
    init(id: String = UUID().uuidString, userId: String, name: String, amount: Double, category: ExpenseCategory, expenseDate: Date = Date(), description: String? = nil, photoURL: String? = nil, location: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.category = category
        self.expenseDate = expenseDate
        self.description = description
        self.photoURL = photoURL
        self.location = location
        self.createdAt = createdAt
    }
}

enum ExpenseCategory: String, CaseIterable, Codable {
    case food = "Food & Dining"
    case transportation = "Transportation"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case bills = "Bills & Utilities"
    case healthcare = "Healthcare"
    case travel = "Travel"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "tv.fill"
        case .bills: return "bolt.fill"
        case .healthcare: return "cross.case.fill"
        case .travel: return "airplane"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .food: return "orange"
        case .transportation: return "blue"
        case .shopping: return "pink"
        case .entertainment: return "purple"
        case .bills: return "yellow"
        case .healthcare: return "red"
        case .travel: return "green"
        case .other: return "gray"
        }
    }
}

extension Expense {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "userId": userId,
            "name": name,
            "amount": amount,
            "category": category.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "expenseDate": Timestamp(date: expenseDate)
        ]
        
        if let description = description {
            dict["description"] = description
        }
        
        if let photoURL = photoURL {
            dict["photoURL"] = photoURL
        }
        
        if let location = location {
            dict["location"] = location
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> Expense? {
        guard let id = dict["id"] as? String,
              let userId = dict["userId"] as? String,
              let name = dict["name"] as? String,
              let amount = dict["amount"] as? Double,
              let categoryString = dict["category"] as? String,
              let category = ExpenseCategory(rawValue: categoryString),
              let createdAtTimestamp = dict["createdAt"] as? Timestamp else {
            return nil
        }
        
        let description = dict["description"] as? String
        let photoURL = dict["photoURL"] as? String
        let location = dict["location"] as? String
        
        // Handle backward compatibility for expenseDate
        let expenseDate: Date
        if let expenseDateTimestamp = dict["expenseDate"] as? Timestamp {
            expenseDate = expenseDateTimestamp.dateValue()
        } else {
            // Fallback to createdAt for existing expenses
            expenseDate = createdAtTimestamp.dateValue()
        }
        
        return Expense(
            id: id,
            userId: userId,
            name: name,
            amount: amount,
            category: category,
            expenseDate: expenseDate,
            description: description,
            photoURL: photoURL,
            location: location,
            createdAt: createdAtTimestamp.dateValue()
        )
    }
}
