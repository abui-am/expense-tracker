//
//  Expense.swift
//  costa
//

import Foundation

struct Expense: Codable, Sendable, Identifiable {
    var id: String
    var user_id: String?
    var name: String
    /// ISO date string `YYYY-MM-DD` — used as the reporting date for daily totals.
    var date: String
    var location: String?
    var payment_method: String?
    var notes: String?
    var is_draft: Bool
    var created_at: String?
    var updated_at: String?
    var costs: [Cost]
}

struct ExpenseListResponse: Codable, Sendable {
    var expenses: [Expense]
}
