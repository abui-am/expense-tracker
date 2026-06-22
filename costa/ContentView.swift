//
//  ContentView.swift
//  costa
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthController.self) private var auth

    var body: some View {
        if auth.isAuthenticated {
            MainTabView()
        } else {
            LoginView()
        }
    }
}

// MARK: - Main tab shell

struct MainTabView: View {
    enum Tab: Int, CaseIterable {
        case home, spending, wallet

        var icon: String {
            switch self {
            case .home:     "house.fill"
            case .spending: "doc.text.fill"
            case .wallet:   "wallet.bifold.fill"
            }
        }

        var label: String {
            switch self {
            case .home:     "Home"
            case .spending: "Spending"
            case .wallet:   "Wallet"
            }
        }
    }

    @State private var selected: Tab = .home
    @State private var showAddExpenseOptions = false
    @State private var showReceiptCapture = false
    @State private var showManualEntry = false
    @State private var selectedCost: Cost?
    /// Bump after editing a cost from the home sheet so lists and chart reload.
    @State private var homeCostsRefreshToken = 0
    @Namespace private var pillNS

    var body: some View {
        // Stable ZStack keeps all views in the tree so the safeAreaInset
        // never re-layouts and the tab bar never flickers on switch.
        ZStack {
            HomeView(selectedCost: $selectedCost, refreshCostsToken: homeCostsRefreshToken)
                .opacity(selected == .home ? 1 : 0)
                .allowsHitTesting(selected == .home)
            SpendingView()
                .opacity(selected == .spending ? 1 : 0)
                .allowsHitTesting(selected == .spending)
            WalletView()
                .opacity(selected == .wallet ? 1 : 0)
                .allowsHitTesting(selected == .wallet)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TabBar(
                selected: $selected,
                showAddSheet: $showAddExpenseOptions,
                namespace: pillNS
            )
        }
        .sheet(isPresented: $showAddExpenseOptions) {
            AddExpenseOptionsSheet(
                isPresented: $showAddExpenseOptions,
                onSnapReceipt: { showReceiptCapture = true },
                onEnterManually: { showManualEntry = true }
            )
            .presentationDetents([.height(440), .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showReceiptCapture) {
            ReceiptCaptureFlowView()
        }
        .fullScreenCover(isPresented: $showManualEntry) {
            ManualExpenseFlowView()
        }
        .sheet(item: $selectedCost) { cost in
            EditCostDetailSheet(cost: cost, onSaved: { _ in
                homeCostsRefreshToken += 1
            })
        }
    }
}

// MARK: - Tab bar

private struct TabBar: View {
    @Binding var selected: MainTabView.Tab
    @Binding var showAddSheet: Bool
    var namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 8) {
            // Sliding pill group
            HStack(spacing: 0) {
                ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                    TabPill(tab: tab, selected: selected, namespace: namespace) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                            selected = tab
                        }
                    }
                }
            }
            .padding(6)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.35),
                                        Color.white.opacity(0.10)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
            .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 6)

            // FAB — same glass stack as tab pill
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .frame(width: 60, height: 60)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.35),
                                                Color.white.opacity(0.10)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .overlay {
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.15)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
    }
}

// MARK: - Individual pill button

private struct TabPill: View {
    let tab: MainTabView.Tab
    let selected: MainTabView.Tab
    let namespace: Namespace.ID
    let onTap: () -> Void

    private var isSelected: Bool { tab == selected }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                Text(tab.label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background {
                // The capsule is ALWAYS in the view tree for all tabs;
                // opacity drives which one is visible so matchedGeometryEffect
                // can smoothly interpolate position between any two tabs.
                Capsule()
                    .fill(Color(.systemBackground))
                    .matchedGeometryEffect(id: "pill", in: namespace, isSource: isSelected)
                    .opacity(isSelected ? 1 : 0)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: isSelected)
    }
}

#Preview {
    ContentView()
        .environment(AuthController())
}
