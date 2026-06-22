//
//  Cost.swift
//  costa
//

import Foundation

struct Cost: Codable, Sendable, Identifiable {
    var id: String
    var user_id: String?
    var name: String
    var amount: Double
    var currency: String
    var created_at: String?
    var updated_at: String?
    var category_id: String?
    var category: CostCategory?
}

struct CostCategory: Codable, Sendable, Equatable, Hashable {
    var id: String?
    var emoji: String
    var name: String
    /// Hex `#RGB`, `#RRGGBB`, or `#RRGGBBAA` from API; empty or null when unset.
    var color: String?
    var is_generated_by_ai: Bool?
}

struct DailySummaryResponse: Codable, Sendable {
    var points: [DailyPoint]
    var from: String
    var to: String
    var days: Int
}

struct DailyPoint: Codable, Sendable {
    var date: String
    var total: Double
    var currency: String?
    var breakdown: [String: Double]?
}
