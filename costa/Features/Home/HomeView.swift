//
//  HomeView.swift
//  costa
//

import Charts
import SwiftUI

struct HomeView: View {
    enum TimeFilter: String, CaseIterable, Hashable {
        case last7Days
        case last30Days
        case all

        var label: String {
            switch self {
            case .last7Days:  "Expenses last 7 days"
            case .last30Days: "Expenses last 30 days"
            case .all:        "Expenses all time"
            }
        }

        var chartDays: Int {
            switch self {
            case .last7Days:  7
            case .last30Days: 30
            case .all:        90
            }
        }

        var cutoffDate: Date? {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            switch self {
            case .last7Days:  return calendar.date(byAdding: .day, value: -6, to: today)
            case .last30Days: return calendar.date(byAdding: .day, value: -29, to: today)
            case .all:        return nil
            }
        }
    }

    @Environment(AuthController.self) private var auth
    @State private var viewModel = HomeViewModel()
    @State private var showSignOutConfirmation = false
    @State private var selectedFilter: TimeFilter = .last7Days
    @Binding var selectedCost: Cost?
    /// Parent increments this after a cost line is edited so we refetch lists and chart.
    var refreshCostsToken: Int = 0

    private var firstName: String {
        auth.user?.email?.components(separatedBy: "@").first?.capitalized ?? "there"
    }

    private var currencyCode: String {
        displayedRows.first?.cost.currency ?? viewModel.rows.first?.cost.currency ?? "IDR"
    }

    private var displayedRows: [HomeCostRow] {
        guard let cutoff = selectedFilter.cutoffDate else { return viewModel.rows }
        let cutoffDay = Calendar.current.startOfDay(for: cutoff)
        return viewModel.rows.filter { row in
            guard let date = row.expenseDate else { return false }
            return Calendar.current.startOfDay(for: date) >= cutoffDay
        }
    }

    private var displayedTotalAmount: Double {
        displayedRows.reduce(0) { $0 + $1.cost.amount }
    }

    /// Distinct parent expenses represented in the filtered rows.
    private var displayedExpenseCount: Int {
        Set(displayedRows.map(\.expenseId)).count
    }

    private var displayedRecentCosts: [Cost] {
        Array(displayedRows.prefix(10).map(\.cost))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                summaryCard
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    // Extra vertical padding so the shadow isn't clipped
                    // by adjacent scroll content
                    .padding(.bottom, 6)

                recentSection
                    .padding(.top, 18)
                    .padding(.bottom, 24)
            }
            // Horizontal padding so card side-shadows aren't cut off
            .padding(.horizontal, 2)
        }
        // Allow shadows to render outside the scroll view's clip region
        .scrollClipDisabled()
        .background(Color(.systemGroupedBackground))
        .refreshable { await reload() }
        .task(id: selectedFilter) {
            guard let token = await auth.validToken() else { return }
            await viewModel.load(accessToken: token, chartDays: selectedFilter.chartDays)
        }
        .onChange(of: refreshCostsToken) { _, _ in
            Task {
                guard let token = await auth.validToken() else { return }
                await viewModel.load(accessToken: token, chartDays: selectedFilter.chartDays)
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.rows.isEmpty {
                ProgressView()
            }
        }
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                Task { await auth.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(auth.user?.email ?? "Are you sure you want to sign out?")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(firstName) \u{1F44B}")
                    .font(.title2.bold())
            }
            Spacer()
            Button {
                showSignOutConfirmation = true
            } label: {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(String(firstName.prefix(1)).uppercased())
                            .font(.headline.bold())
                            .foregroundStyle(.green)
                    }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Summary card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Period picker
            GlassMenuPicker(
                selection: $selectedFilter,
                options: TimeFilter.allCases
            ) { $0.label }

            // Total
            VStack(alignment: .leading, spacing: 4) {
                Text(displayedTotalAmount, format: .currency(code: currencyCode))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                if !displayedRows.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Receipt \(displayedExpenseCount)")
                            .font(.subheadline)
                            .foregroundStyle(.black)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.black)
                    }
                }
            }

            // Chart
            spendingChart

            if let err = viewModel.errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .background(
            // Use background shape instead of clipShape so child shadows
            // (e.g. GlassMenuPicker) are not masked by the card boundary.
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Chart

    private var spendingChart: some View {
        let data = viewModel.chartData
        let maxVal = data.map(\.total).max() ?? 1
        let cal = Calendar.current
        // Use the days that were actually loaded — not selectedFilter — so the
        // axis label format and stride only change when the new data arrives.
        let days = viewModel.loadedChartDays

        // Stride and label format adapt to the date range so labels never overlap:
        //   ≤ 7 days  → daily stride, "Mon" / "Today"
        //   ≤ 30 days → weekly stride, "Jan 5"
        //   > 30 days → monthly stride, "Jan" / "Jan '25"
        let strideComponent: Calendar.Component = days <= 7 ? .day : days <= 30 ? .weekOfYear : .month
        let labelFormat: (Date) -> String = { date in
            if days <= 7 {
                return cal.isDateInToday(date) ? "Today" : date.formatted(.dateTime.weekday(.abbreviated))
            } else if days <= 30 {
                return date.formatted(.dateTime.month(.abbreviated).day())
            } else {
                return date.formatted(.dateTime.month(.abbreviated))
            }
        }

        return Chart(data) { point in
            AreaMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Amount", point.total)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.green.opacity(0.45), Color.green.opacity(0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Amount", point.total)
            )
            .foregroundStyle(Color.green)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Amount", point.total)
            )
            .foregroundStyle(Color.green)
            .symbolSize(data.last?.id == point.id ? 55 : 0)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: strideComponent)) { val in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [4]))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                AxisValueLabel {
                    if let date = val.as(Date.self) {
                        Text(labelFormat(date))
                            .font(.caption2)
                            .foregroundStyle(cal.isDateInToday(date) ? Color.green : Color.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0, maxVal]) { val in
                AxisValueLabel {
                    if let v = val.as(Double.self) {
                        Text(v == 0 ? "Rp0" : shortAmount(v))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYScale(domain: 0 ... max(maxVal * 1.2, 1))
        .frame(height: 140)
    }

    // MARK: - Recent expenses

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Expenses")
                    .font(.headline)
                Spacer()
                Button {
                } label: {
                    HStack(spacing: 2) {
                        Text("See All")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(.horizontal, 20)

            if displayedRows.isEmpty && !viewModel.isLoading {
                Text("No expenses yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 10) {
                    ForEach(displayedRecentCosts) { cost in
                        Button {
                            selectedCost = cost
                        } label: {
                            CostRowView(cost: cost)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func reload() async {
        guard let token = await auth.validToken() else { return }
        await viewModel.load(accessToken: token, chartDays: selectedFilter.chartDays)
    }

    private func shortAmount(_ value: Double) -> String {
        if value >= 1_000_000 { return "Rp\(Int(value / 1_000_000))M" }
        if value >= 1_000 { return "Rp\(Int(value / 1_000))K" }
        return "Rp\(Int(value))"
    }
}

// MARK: - Cost row

struct CostRowView: View {
    let cost: Cost

    /// API `category.color` on the tag only; name fallback when unset / invalid hex.
    private var tagTint: Color {
        if let raw = cost.category?.color?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty,
           let parsed = Color(hex: raw) {
            return parsed
        }
        return fallbackTintFromCategoryName
    }

    private var iconBackground: Color {
        switch cost.category?.name.lowercased() {
        case "transportation", "transport": return Color.teal.opacity(0.15)
        case "food", "food & drink": return Color.orange.opacity(0.15)
        case "laundry": return Color.purple.opacity(0.15)
        case "health": return Color.red.opacity(0.15)
        case "entertainment": return Color.blue.opacity(0.15)
        default: return Color.green.opacity(0.15)
        }
    }

    private var fallbackTintFromCategoryName: Color {
        switch cost.category?.name.lowercased() {
        case "transportation", "transport": return .teal
        case "food", "food & drink": return .orange
        case "laundry": return .purple
        case "health": return .red
        case "entertainment": return .blue
        default: return .green
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconBackground)
                    .frame(width: 48, height: 48)
                Text(cost.category?.emoji.isEmpty == false ? cost.category!.emoji : defaultEmoji)
                    .font(.title3)
            }

            // Title + category tag (uses API category color)
            VStack(alignment: .leading, spacing: 4) {
                Text(cost.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("1 pack")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let cat = cost.category?.name {
                        Text(cat)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(tagTint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .overlay(Capsule().strokeBorder(tagTint.opacity(0.6), lineWidth: 1))
                    }
                }
            }

            Spacer()

            Text(cost.amount, format: .currency(code: cost.currency))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private var defaultEmoji: String {
        switch cost.category?.name.lowercased() {
        case "transportation", "transport": return "🚗"
        case "food", "food & drink": return "🍔"
        case "laundry": return "🧺"
        case "health": return "💊"
        case "entertainment": return "🎬"
        default: return "💳"
        }
    }
}

#Preview {
    HomeView(selectedCost: .constant(nil), refreshCostsToken: 0)
        .environment(AuthController())
}
