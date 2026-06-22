//
//  WalletView.swift
//  costa
//

import SwiftUI

struct WalletView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Wallet", systemImage: "wallet.bifold", description: Text("Coming soon"))
                .navigationTitle("Wallet")
        }
    }
}
