//
//  EditCostDetailServicing.swift
//  costa
//

import Foundation

/// Dependencies for editing a cost line item (categories + persist). Injected for tests and previews.
protocol EditCostDetailServicing: Sendable {
    func listCategories(accessToken: String) async throws -> [CostCategory]
    func createCategory(_ request: CreateCategoryRequest, accessToken: String) async throws -> CostCategory
    func patchCost(id: String, patch: CostPatch, accessToken: String) async throws -> Cost
}
