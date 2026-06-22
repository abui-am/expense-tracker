//
//  MockEditCostDetailService.swift
//  costa
//

import Foundation

/// Deterministic mock for previews, UI tests, and unit tests.
struct MockEditCostDetailService: EditCostDetailServicing {
    var categoriesResult: Result<[CostCategory], Error>
    var createCategoryResult: Result<CostCategory, Error>
    var patchResult: Result<Cost, Error>

    init(
        categories: [CostCategory],
        createCategoryResult: Result<CostCategory, Error> = .failure(MockEditCostDetailServiceError.createNotConfigured),
        patchResult: Result<Cost, Error> = .failure(MockEditCostDetailServiceError.notConfigured)
    ) {
        self.categoriesResult = .success(categories)
        self.createCategoryResult = createCategoryResult
        self.patchResult = patchResult
    }

    init(
        categoriesResult: Result<[CostCategory], Error>,
        createCategoryResult: Result<CostCategory, Error> = .failure(MockEditCostDetailServiceError.createNotConfigured),
        patchResult: Result<Cost, Error> = .failure(MockEditCostDetailServiceError.notConfigured)
    ) {
        self.categoriesResult = categoriesResult
        self.createCategoryResult = createCategoryResult
        self.patchResult = patchResult
    }

    func listCategories(accessToken: String) async throws -> [CostCategory] {
        try categoriesResult.get()
    }

    func createCategory(_ request: CreateCategoryRequest, accessToken: String) async throws -> CostCategory {
        try createCategoryResult.get()
    }

    func patchCost(id: String, patch: CostPatch, accessToken: String) async throws -> Cost {
        try patchResult.get()
    }
}

enum MockEditCostDetailServiceError: LocalizedError {
    case notConfigured
    case createNotConfigured

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Mock patch not configured"
        case .createNotConfigured:
            "Mock create category not configured"
        }
    }
}
