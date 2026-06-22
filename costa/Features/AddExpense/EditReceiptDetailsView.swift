//
//  EditReceiptDetailsView.swift
//  costa
//

import SwiftUI
import UIKit

// MARK: - Editable cost line

struct EditableCost: Identifiable {
    var id: String
    var name: String
    /// String representation so the user can type freely; parsed on save.
    var amountText: String
    var currency: String
    var category_id: String?
    var category: CostCategory?

    init(
        id: String,
        name: String,
        amountText: String,
        currency: String,
        category_id: String?,
        category: CostCategory?
    ) {
        self.id = id
        self.name = name
        self.amountText = amountText
        self.currency = currency
        self.category_id = category_id
        self.category = category
    }

    init(cost: Cost) {
        id = cost.id
        name = cost.name
        let a = cost.amount
        amountText = a.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(a)) : String(a)
        currency = cost.currency
        category_id = cost.category_id
        category = cost.category
    }

    var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
}

// MARK: - View

struct EditReceiptDetailsView: View {
    enum Source {
        case scanBill
        case manual
    }

    @Environment(AuthController.self) private var auth
    @Environment(\.dismiss) private var dismiss

    let originalExpense: Expense
    let extraction: BillExtraction?
    let thumbnail: UIImage
    var onRetake: () -> Void
    var source: Source = .scanBill
    var isReadOnly: Bool = false

    @State private var expenseName: String
    @State private var expenseDate: Date
    @State private var paymentMethod: String
    @State private var location: String
    @State private var notes: String
    @State private var editCosts: [EditableCost]

    @State private var isSaving = false
    @State private var saveError: String?
    @State private var transactionExpanded = true
    @State private var itemsExpanded = true
    @State private var selectedCost: EditableCost?
    @State private var summaryExpanded = true

    init(
        expense: Expense,
        extraction: BillExtraction?,
        thumbnail: UIImage,
        onRetake: @escaping () -> Void,
        source: Source = .scanBill,
        isReadOnly: Bool = false
    ) {
        originalExpense = expense
        self.extraction = extraction
        self.thumbnail = thumbnail
        self.onRetake = onRetake
        self.source = source
        self.isReadOnly = isReadOnly

        let merchant = extraction?.merchant?.isEmpty == false
            ? extraction!.merchant!
            : expense.name
        _expenseName = State(initialValue: merchant)

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        _expenseDate = State(initialValue: parser.date(from: expense.date) ?? Date())

        let pm = extraction?.payment_method ?? expense.payment_method ?? "UNSPECIFIED"
        _paymentMethod = State(initialValue: pm)

        let loc = extraction?.location?.isEmpty == false
            ? extraction!.location!
            : (expense.location ?? "")
        _location = State(initialValue: loc)
        _notes = State(initialValue: expense.notes ?? "")
        _editCosts = State(initialValue: expense.costs.map { EditableCost(cost: $0) })
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                Section {
                    headerCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                transactionCard
                itemsCard
                summaryCard
                notesCard
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(12)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .sheet(item: $selectedCost) { cost in
                let costModel = Cost(
                    id: cost.id,
                    user_id: nil,
                    name: cost.name,
                    amount: cost.amount,
                    currency: cost.currency,
                    created_at: nil,
                    updated_at: nil,
                    category_id: cost.category_id,
                    category: cost.category
                )
                EditCostDetailSheet(cost: costModel, onSaved: { updated in
                    if let i = editCosts.firstIndex(where: { $0.id == updated.id }) {
                        editCosts[i] = EditableCost(cost: updated)
                    } else {
                        editCosts.append(EditableCost(cost: updated))
                    }
                })
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 20)
            }
            .navigationTitle("EDIT RECEIPT DETAILS")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Back")
                }
                if !isReadOnly {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task { await performSave() }
                        }
                        label: {
                            Group {
                                if isSaving {
                                    ProgressView()
                                        .controlSize(.mini)
                                        .tint(.white)
                                } else {
                                    Text("Save")
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(isSaving)
                        .tint(.blue)
                    }
                }
            }
            .alert("Save Failed", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                if let err = saveError { Text(err) }
            }
        }
    }


    // MARK: - Header card

    private var headerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnailOverlay
            VStack(alignment: .leading, spacing: 8) {
                if extraction != nil && source == .scanBill {
                    HStack(spacing: 4) {
                      
                        Text("Auto-detected")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.darkGreen)
                        Image(systemName: "checkmark")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(.darkGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.darkGreen.opacity(0.12))
                    .overlay(
                        Capsule()
                            .stroke(.darkGreen, lineWidth: 1)
                    )
                    .clipShape(.capsule)
                }
                if source == .scanBill {
                    HStack(spacing: 4) {
                        Text("Confidence")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Image(systemName: "info.circle")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("92%")
                            .font(.caption)
                            .foregroundColor(.darkGreen)
                    }
                }
                TextField("Merchant name", text: $expenseName)
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .receiptCard()
    }

    private var thumbnailOverlay: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            if source == .scanBill {
                Button(action: onRetake) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(.blue, in: Circle())
                        .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                }
                .offset(x: 4, y: 4)
                .accessibilityLabel("Retake photo")
            }
        }
    }

    // MARK: - Transaction details card

    private var transactionCard: some View {
        Section {
            if transactionExpanded {
                HStack {
                    Text("Date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    DatePicker("", selection: $expenseDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
                .rowPadding()
                .listRowInsets(EdgeInsets())

                HStack {
                    Text("Payment Method")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(PaymentMethodOption.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                }
                .rowPadding()
                .listRowInsets(EdgeInsets())

                HStack {
                    Text("Location")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("Location", text: $location)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 200)
                }
                .rowPadding()
                .listRowInsets(EdgeInsets())
            }
        } header: {
            sectionHeader(icon: "calendar", title: "Transaction Details", isExpanded: $transactionExpanded)
                .textCase(nil)
                .listRowInsets(EdgeInsets())
        }
    }

    // MARK: - Items card

    private var itemsCard: some View {
        Section {
            if itemsExpanded {
                if editCosts.isEmpty {
                    VStack(spacing: 10) {
                        Text("No items extracted")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)

                        if !isReadOnly {
                            Button {
                                selectedCost = makeNewCostDraft()
                            } label: {
                                Label("Add item", systemImage: "plus")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(16)
                    .listRowInsets(EdgeInsets())
                } else {
                    ForEach(editCosts) { cost in
                        Button(action: { selectedCost = cost }) {
                            HStack(spacing: 10) {
                                Text("1×")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 5))

                                Text(cost.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(cost.amountText)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: 90, alignment: .trailing)
                            }
                            .rowPadding()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if !isReadOnly {
                                Button(role: .destructive) {
                                    deleteCost(cost)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets())
                    }
                }
            }
        } header: {
            sectionHeader(icon: "bag.fill", title: "Items", isExpanded: $itemsExpanded)
                .textCase(nil)
                .listRowInsets(EdgeInsets())
        }
    }

    // MARK: - Summary card

    private var summaryCard: some View {
        let currency = editCosts.first?.currency ?? "IDR"
        let total = editCosts.reduce(0) { $0 + $1.amount }

        return Section {
            if summaryExpanded {
                HStack {
                    Text("Subtotal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatAmount(total, currency: currency))
                        .font(.subheadline)
                }
                .rowPadding()
                .listRowInsets(EdgeInsets())

                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text(formatAmount(total, currency: currency))
                        .font(.headline)
                        .foregroundStyle(.green)
                }
                .rowPadding()
                .listRowInsets(EdgeInsets())
            }
        } header: {
            sectionHeader(
                icon: "clock.fill",
                title: "Summary",
                subtitle: "Auto Calculated",
                isExpanded: $summaryExpanded
            )
            .textCase(nil)
            .listRowInsets(EdgeInsets())
        }
    }

    // MARK: - Notes card

    private var notesCard: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.green, in: RoundedRectangle(cornerRadius: 8))
                Text("Notes")
                    .font(.headline)
            }
            .rowPadding()
            .listRowInsets(EdgeInsets())

            TextField("Add a note…", text: $notes, axis: .vertical)
                .font(.subheadline)
                .lineLimit(3...)
                .rowPadding()
                .listRowInsets(EdgeInsets())
        }
    }

    // MARK: - Section header builder

    @ViewBuilder
    private func sectionHeader(
        icon: String,
        title: String,
        subtitle: String? = nil,
        isExpanded: Binding<Bool>
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { isExpanded.wrappedValue.toggle() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.darkGreen)

                if let subtitle {
                    HStack(spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Text("(\(subtitle))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(title)
                        .font(.headline)
                }

                Spacer()

                Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .rowPadding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets())
    }

    // MARK: - Save

    private func performSave() async {
        guard let token = await auth.validToken() else {
            saveError = "You are not signed in."
            return
        }

        isSaving = true
        defer { isSaving = false }

        let dateStr = isoDateString(from: expenseDate)
        let patch = ExpensePatch(
            name: expenseName,
            date: dateStr,
            location: location,
            notes: notes.isEmpty ? nil : notes,
            payment_method: paymentMethod,
            is_draft: false
        )

        let client = CostAPIClient(accessToken: token)

        do {
            _ = try await client.patchExpense(id: originalExpense.id, patch: patch)

            for editCost in editCosts {
                guard let original = originalExpense.costs.first(where: { $0.id == editCost.id }) else { continue }
                let nameChanged = editCost.name != original.name
                let amountChanged = abs(editCost.amount - original.amount) > 0.001
                guard nameChanged || amountChanged else { continue }
                _ = try await client.patchCost(
                    id: editCost.id,
                    patch: CostPatch(
                        name: editCost.name,
                        amount: editCost.amount,
                        currency: editCost.currency,
                        category_id: editCost.category_id
                    )
                )
            }

            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func formatAmount(_ amount: Double, currency: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "id_ID")
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }

    private func isoDateString(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func deleteCost(_ cost: EditableCost) {
        withAnimation {
            editCosts.removeAll { $0.id == cost.id }
        }

        if selectedCost?.id == cost.id {
            selectedCost = nil
        }
    }

    private func makeNewCostDraft() -> EditableCost {
        EditableCost(
            id: UUID().uuidString,
            name: "",
            amountText: "0",
            currency: editCosts.first?.currency ?? originalExpense.costs.first?.currency ?? "IDR",
            category_id: nil,
            category: nil
        )
    }
}

// MARK: - View modifiers

private extension View {
    func receiptCard() -> some View {
        self
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
    }

    func rowPadding() -> some View {
        self.padding(.horizontal, 16).padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    let sampleCosts: [Cost] = [
        Cost(id: "c1", name: "Venti Mocha Latte", amount: 50_000, currency: "IDR"),
        Cost(id: "c2", name: "Oat Milk",          amount: 50_000, currency: "IDR"),
        Cost(id: "c3", name: "Venti",              amount: 50_000, currency: "IDR"),
        Cost(id: "c4", name: "Gr White Mocha",     amount: 50_000, currency: "IDR")
    ]
    let expense = Expense(
        id: "e1",
        name: "Starbucks",
        date: "2026-05-25",
        location: "Jakarta, Indonesia",
        payment_method: "CREDIT_CARD",
        notes: "Meeting with client",
        is_draft: true,
        costs: sampleCosts
    )
    let extraction = BillExtraction(
        merchant: "Starbucks",
        transaction_date: "2026-05-25",
        location: "Jakarta, Indonesia",
        payment_method: "CREDIT_CARD",
        line_count: 4
    )
    EditReceiptDetailsView(
        expense: expense,
        extraction: extraction,
        thumbnail: UIImage(systemName: "doc.text.viewfinder")!,
        onRetake: {}
    )
    .environment(AuthController())
}
