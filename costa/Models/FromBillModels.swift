//
//  FromBillModels.swift
//  costa
//

import Foundation

// MARK: - from-bill response

struct FromBillResponse: Codable, Sendable {
    var expense: Expense
    var extraction: BillExtraction?
}

struct BillExtraction: Codable, Sendable {
    var merchant: String?
    var summary: String?
    var transaction_date: String?
    var location: String?
    var payment_method: String?
    var line_count: Int?
}

// MARK: - Create expense request

struct CreateExpenseCostInput: Encodable, Sendable {
    var name: String
    var category_id: String
    var amount: Double
    var currency: String = "IDR"
}

struct CreateExpenseRequest: Encodable, Sendable {
    var date: String
    var name: String
    var location: String = ""
    var notes: String?
    var payment_method: String = "UNSPECIFIED"
    var is_draft: Bool = true
    var costs: [CreateExpenseCostInput]
}

struct CreateExpenseResponse: Codable, Sendable {
    var expense: Expense
    var costs: [Cost]
}

// MARK: - PATCH request bodies

struct ExpensePatch: Encodable, Sendable {
    var name: String
    var date: String
    var location: String
    var notes: String?
    var payment_method: String
    var is_draft: Bool
}

struct CostPatch: Encodable, Sendable {
    var name: String
    var amount: Double
    var currency: String
    var category_id: String?
    /// Line quantity when the API stores `qty` separately from extended amount.
    var qty: Double? = nil
}

/// Request body for `POST /api/cost/categories`.
struct CreateCategoryRequest: Encodable, Sendable {
    var name: String
    var emoji: String?
    var color: String?
}

// MARK: - Single-resource response wrappers

struct ExpenseOneResponse: Codable, Sendable {
    var expense: Expense
}

struct CostOneResponse: Codable, Sendable {
    var cost: Cost
}

struct CategoriesResponse: Codable, Sendable {
    var categories: [CostCategory]
}

struct CategoryOneResponse: Codable, Sendable {
    var category: CostCategory
}

// MARK: - Payment method

enum PaymentMethodOption: String, CaseIterable, Identifiable {
    case unspecified = "UNSPECIFIED"
    case cash = "CASH"
    case creditCard = "CREDIT_CARD"
    case debitCard = "DEBIT_CARD"
    case bankTransfer = "BANK_TRANSFER"
    case eWallet = "E_WALLET"
    case qrPay = "QR_PAY"
    case other = "OTHER"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unspecified:   "Unspecified"
        case .cash:          "Cash"
        case .creditCard:    "Credit Card"
        case .debitCard:     "Debit Card"
        case .bankTransfer:  "Bank Transfer"
        case .eWallet:       "E-Wallet"
        case .qrPay:         "QR Pay"
        case .other:         "Other"
        }
    }

    static func from(_ raw: String?) -> PaymentMethodOption {
        PaymentMethodOption(rawValue: raw ?? "") ?? .unspecified
    }
}
