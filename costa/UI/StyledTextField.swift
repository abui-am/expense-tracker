//
//  StyledTextField.swift
//  costa
//

import SwiftUI

/// A reusable text-field block styled like the receipt detail form.
struct StyledTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    /// Optional short leading text rendered in its own rounded capsule (e.g. "IDR").
    var leadingText: String?
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.callout.weight(.medium))
                .foregroundStyle(.primary)

            HStack(spacing: 10) {
                if let leadingText {
                    Text(leadingText)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(fieldBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .fixedSize(horizontal: true, vertical: false)
                }

                TextField(placeholder, text: $text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .keyboardType(keyboardType)
                    .padding(.horizontal, 20)
                    .frame(height: 48)
                    .background(fieldBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var fieldBackground: Color {
        Color(uiColor: .secondarySystemFill)
    }
}

#Preview {
    struct Demo: View {
        @State private var name = "Venti Mocha Latte"
        @State private var quantity = "1"
        @State private var unitPrice = "50.000"

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    StyledTextField(
                        title: "Name",
                        placeholder: "Enter item name",
                        text: $name
                    )

                    StyledTextField(
                        title: "Quantity",
                        placeholder: "0",
                        text: $quantity,
                        keyboardType: .numberPad
                    )

                    StyledTextField(
                        title: "Unit Price",
                        placeholder: "0",
                        text: $unitPrice,
                        leadingText: "IDR",
                        keyboardType: .numberPad
                    )
                }
                .padding(18)
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    return Demo()
}
