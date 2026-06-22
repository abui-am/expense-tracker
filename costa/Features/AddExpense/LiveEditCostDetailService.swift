//
//  LiveEditCostDetailService.swift
//  costa
//

import Foundation

struct LiveEditCostDetailService: EditCostDetailServicing {
    func listCategories(accessToken: String) async throws -> [CostCategory] {
        let client = CostAPIClient(accessToken: accessToken)
        return try await client.listCategories()
    }

    func createCategory(_ request: CreateCategoryRequest, accessToken: String) async throws -> CostCategory {
        let client = CostAPIClient(accessToken: accessToken)
        return try await client.createCategory(request)
    }

    func patchCost(id: String, patch: CostPatch, accessToken: String) async throws -> Cost {
        let client = CostAPIClient(accessToken: accessToken)
        return try await client.patchCost(id: id, patch: patch)
    }
}
