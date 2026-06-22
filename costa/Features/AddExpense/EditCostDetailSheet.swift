//
//  EditCostDetailSheet.swift
//  costa
//

import SwiftUI

struct EditCostDetailSheet: View {
    @Environment(AuthController.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: EditCostDetailViewModel
    /// Called with the server-updated `Cost` after a successful save, before the sheet dismisses.
    private let onSaved: ((Cost) -> Void)?

    init(
        cost: Cost,
        service: EditCostDetailServicing = LiveEditCostDetailService(),
        onSaved: ((Cost) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: EditCostDetailViewModel(cost: cost, service: service))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        StyledTextField(
                            title: "Name",
                            placeholder: "Item name",
                            text: $viewModel.nameText
                        )

                        StyledTextField(
                            title: "Quantity",
                            placeholder: "0",
                            text: $viewModel.quantityText,
                            keyboardType: .decimalPad
                        )

                        StyledTextField(
                            title: "Unit Price",
                            placeholder: "0",
                            text: $viewModel.unitPriceText,
                            leadingText: viewModel.cost.currency,
                            keyboardType: .decimalPad
                        )

                        // Total display
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Text(viewModel.calculatedTotal, format: .currency(code: viewModel.cost.currency))
                                .font(.body)
                                .foregroundStyle(.primary)
                        }

                        // Category selector with add mode
                        if viewModel.categories.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text("Add at least one category to classify this line item.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button {
                                    viewModel.isAddingCategory = true
                                } label: {
                                    Text("Add category")
                                        .font(.body.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        } else {
                            StyledSelectField(
                                title: "Category",
                                selection: $viewModel.selectedCategory,
                                options: viewModel.categories,
                                optionLabel: { $0.name },
                                onAddNew: { viewModel.isAddingCategory = true }
                            )
                        }

                        // Error message
                        if let error = viewModel.errorMessage {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.red)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                            .padding(12)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Edit cost")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveAndDismiss()
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(
                        viewModel.isLoading
                            || viewModel.nameText.trimmingCharacters(in: .whitespaces).isEmpty
                            || viewModel.selectedCategory.id == nil
                    )
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.12)
                            .ignoresSafeArea()
                        ProgressView()
                            .controlSize(.large)
                    }
                    .allowsHitTesting(true)
                }
            }
            .sheet(isPresented: $viewModel.isAddingCategory) {
                addCategorySheet
            }
            .task {
                guard let token = await auth.validToken() else { return }
                await viewModel.loadCategories(accessToken: token)
            }
        }
    }

    @ViewBuilder
    private var addCategorySheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    StyledTextField(
                        title: "Category Name",
                        placeholder: "Enter category name",
                        text: $viewModel.newCategoryName
                    )

                    StyledTextField(
                        title: "Emoji",
                        placeholder: "e.g. 🍔",
                        text: $viewModel.newCategoryEmoji
                    )

                    StyledTextField(
                        title: "Color",
                        placeholder: "#RRGGBB or RRGGBB",
                        text: $viewModel.newCategoryColor
                    )

                    if let hex = normalizedColorForSwatch(viewModel.newCategoryColor),
                       let chip = Color(hex: hex) {
                        HStack(spacing: 10) {
                            Text("Preview")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Circle()
                                .fill(chip)
                                .frame(width: 28, height: 28)
                                .overlay(Circle().strokeBorder(.separator, lineWidth: 1))
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetNewCategoryForm()
                        viewModel.isAddingCategory = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            guard let token = await auth.validToken() else {
                                viewModel.errorMessage = "Authentication failed."
                                return
                            }
                            await viewModel.addCategory(accessToken: token)
                        }
                    }
                    
                    .disabled(viewModel.isLoading || viewModel.newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundStyle(
                        viewModel.isLoading || viewModel.newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.secondary
                            : Color.blue
                    )
                }
            }
        }
    }

    /// Best-effort parse for preview chip (same rules as view model).
    private func normalizedColorForSwatch(_ raw: String) -> String? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !s.isEmpty else { return nil }
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8 else { return nil }
        guard s.allSatisfy(\.isHexDigit) else { return nil }
        return "#\(s)"
    }

    private func saveAndDismiss() async {
        guard let token = await auth.validToken() else {
            viewModel.errorMessage = "Authentication failed."
            return
        }

        do {
            try await viewModel.save(accessToken: token)
            onSaved?(viewModel.cost)
            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Previews

#if DEBUG
enum EditCostDetailSheetPreviewData {
    static let sampleCost = Cost(
        id: "1",
        user_id: nil,
        name: "Venti Mocha Latte",
        amount: 50000,
        currency: "IDR",
        created_at: nil,
        updated_at: nil,
        category_id: "food",
        category: CostCategory(
            id: "food",
            emoji: "🍔",
            name: "Food",
            color: "#FF9500",
            is_generated_by_ai: false
        )
    )

    static let mockCategories: [CostCategory] = [
        CostCategory(id: "food", emoji: "🍔", name: "Food", color: "#FF9500", is_generated_by_ai: false),
        CostCategory(id: "t", emoji: "🚗", name: "Transport", color: nil, is_generated_by_ai: false),
        CostCategory(id: "u", emoji: "🏠", name: "Utilities", color: nil, is_generated_by_ai: false)
    ]

    static var mockService: MockEditCostDetailService {
        MockEditCostDetailService(
            categories: mockCategories,
            createCategoryResult: .success(
                CostCategory(
                    id: "new-cat",
                    emoji: "🆕",
                    name: "New category",
                    color: "#2d7ef7",
                    is_generated_by_ai: false
                )
            ),
            patchResult: .success(sampleCost)
        )
    }
}

/// Presents like a real sheet so Safe Area + detents match the app.
private struct EditCostDetailSheetPreviewHost: View {
    @State private var isPresented = true

    var body: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
            .sheet(isPresented: $isPresented) {
                EditCostDetailSheet(
                    cost: EditCostDetailSheetPreviewData.sampleCost,
                    service: EditCostDetailSheetPreviewData.mockService
                )
                .environment(AuthController.previewAuthenticated())
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
    }
}

#Preview("Edit cost (mock + sheet)") {
    assert(!EditCostDetailSheetPreviewData.mockCategories.isEmpty, "Preview: need categories for picker")
    assert(EditCostDetailSheetPreviewData.sampleCost.currency == "IDR", "Preview: currency mismatch")
    return EditCostDetailSheetPreviewHost()
}
#endif
