//
//  EditCostDetailViewModel.swift
//  costa
//

import Foundation
import Observation

@Observable
final class EditCostDetailViewModel {
    private let service: EditCostDetailServicing

    var cost: Cost
    var nameText: String
    var quantityText: String
    var unitPriceText: String
    var selectedCategory: CostCategory

    var isLoading = false
    var errorMessage: String?
    var categories: [CostCategory] = []
    var isAddingCategory = false
    var newCategoryName = ""
    var newCategoryEmoji = "💳"
    var newCategoryColor = ""

    init(cost: Cost, service: EditCostDetailServicing = LiveEditCostDetailService()) {
        self.service = service
        self.cost = cost
        self.nameText = cost.name
        self.quantityText = "1"
        self.unitPriceText = String(format: "%.0f", cost.amount)
        self.selectedCategory = cost.category ?? CostCategory(
            id: nil,
            emoji: "💳",
            name: "Other",
            color: nil,
            is_generated_by_ai: false
        )
    }

    var calculatedTotal: Double {
        parsedQuantity * parsedUnitPrice
    }

    private var parsedQuantity: Double {
        Double(quantityText.replacingOccurrences(of: ",", with: "")) ?? 1
    }

    private var parsedUnitPrice: Double {
        Double(unitPriceText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    func loadCategories(accessToken: String) async {
        do {
            categories = try await service.listCategories(accessToken: accessToken)
            if !categories.isEmpty && selectedCategory.id == nil {
                selectedCategory = categories[0]
            }
        } catch {
            errorMessage = "Failed to load categories: \(error.localizedDescription)"
        }
    }

    func addCategory(accessToken: String) async {
        let name = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let emojiRaw = newCategoryEmoji.trimmingCharacters(in: .whitespaces)
        let emoji = emojiRaw.isEmpty ? "💳" : emojiRaw

        let request = CreateCategoryRequest(
            name: name,
            emoji: emoji,
            color: Self.normalizedHexColor(newCategoryColor)
        )

        do {
            let created = try await service.createCategory(request, accessToken: accessToken)
            categories.append(created)
            categories.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            selectedCategory = created
            resetNewCategoryForm()
            isAddingCategory = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetNewCategoryForm() {
        newCategoryName = ""
        newCategoryEmoji = "💳"
        newCategoryColor = ""
    }

    /// Accepts `#RRGGBB`, `#RRGGBBAA`, or without `#`. Returns nil if empty or invalid.
    private static func normalizedHexColor(_ raw: String) -> String? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !s.isEmpty else { return nil }
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8 else { return nil }
        guard s.allSatisfy(\.isHexDigit) else { return nil }
        return "#\(s)"
    }

    func save(accessToken: String) async throws {
        guard let categoryId = selectedCategory.id?.trimmingCharacters(in: .whitespaces), !categoryId.isEmpty else {
            throw EditCostDetailViewModelError.missingCategory
        }

        isLoading = true
        defer { isLoading = false }

        let qty = parsedQuantity
        let patch = CostPatch(
            name: nameText.trimmingCharacters(in: .whitespaces),
            amount: calculatedTotal,
            currency: cost.currency,
            category_id: categoryId,
            qty: qty > 0 ? qty : nil
        )

        let updated = try await service.patchCost(id: cost.id, patch: patch, accessToken: accessToken)
        cost = updated
    }

    func resetToOriginal() {
        nameText = cost.name
        quantityText = "1"
        unitPriceText = String(format: "%.0f", cost.amount)
        selectedCategory = cost.category ?? CostCategory(
            id: nil,
            emoji: "💳",
            name: "Other",
            color: nil,
            is_generated_by_ai: false
        )
        errorMessage = nil
    }
}

enum EditCostDetailViewModelError: LocalizedError {
    case missingCategory

    var errorDescription: String? {
        switch self {
        case .missingCategory:
            "Choose or create a category before saving."
        }
    }
}
