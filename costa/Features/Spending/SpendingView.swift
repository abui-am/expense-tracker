//
//  SpendingView.swift
//  costa
//

import SwiftUI

struct SpendingView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Spending", systemImage: "doc.text", description: Text("Coming soon"))
                .navigationTitle("Spending")
        }
    }
}
