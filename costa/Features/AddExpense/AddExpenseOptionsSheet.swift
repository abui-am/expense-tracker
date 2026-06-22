//
//  AddExpenseOptionsSheet.swift
//  costa
//

import SwiftUI

/// Bottom sheet: ways to add an expense (matches product design).
struct AddExpenseOptionsSheet: View {
    @Binding var isPresented: Bool
    var onSnapReceipt: () -> Void = {}
    var onEnterManually: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                optionRow(
                    icon: "camera.fill",
                    iconBackground: Color(red: 0.88, green: 0.94, blue: 1),
                    title: "Snap Receipt",
                    subtitle: "Use your camera to quickly capture expenses details."
                ) {
                    isPresented = false
                    onSnapReceipt()
                }

                sheetDivider

                optionRow(
                    icon: "photo.on.rectangle.angled",
                    iconBackground: Color(red: 1, green: 0.9, blue: 0.94),
                    title: "Upload from Gallery",
                    subtitle: "Add up to 1 receipts at once from your gallery."
                ) {
                    isPresented = false
                    // TODO: photo picker / from-bill
                }

                sheetDivider

                optionRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    iconBackground: Color(red: 1, green: 0.97, blue: 0.82),
                    title: "Free Text Input",
                    subtitle: "Input your free text and the expense details will be automatically written."
                ) {
                    isPresented = false
                    // TODO: from-text flow
                }

                sheetDivider

                optionRow(
                    icon: "doc.badge.plus",
                    iconBackground: Color(red: 0.89, green: 0.97, blue: 0.9),
                    title: "Enter Manually",
                    subtitle: "Manually input your transaction details."
                ) {
                    isPresented = false
                    onEnterManually()
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 8)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var sheetDivider: some View {
        Divider()
            .padding(.leading, 84)
    }

    private func optionRow(
        icon: String,
        iconBackground: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(iconBackground))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddExpenseOptionsSheet(isPresented: .constant(true))
}
