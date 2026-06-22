//
//  StyledSelectField.swift
//  costa
//

import SwiftUI
import UIKit

/// A reusable dropdown/select block matching the `StyledTextField` look.
/// The menu opens anchored to the trailing edge of the field.
/// When `onAddNew` is set, a trailing "Add new…" action appears; the parent presents any add UI (sheet, navigation, etc.).
struct StyledSelectField<Option: Hashable>: View {
    let title: String
    @Binding var selection: Option
    let options: [Option]
    let optionLabel: (Option) -> String
    var onAddNew: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.primary)

            ZStack {
                selectLabel(text: optionLabel(selection))
                    .allowsHitTesting(false)

                SelectMenuControl(
                    selection: $selection,
                    options: options,
                    optionLabel: optionLabel,
                    onAddNew: onAddNew
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
    }

    @ViewBuilder
    private func selectLabel(text: String) -> some View {
        HStack(spacing: 12) {
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.down")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(
            Color(uiColor: .secondarySystemFill),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}

// MARK: - UIViewRepresentable trigger

private struct SelectMenuControl<Option: Hashable>: UIViewRepresentable {
    @Binding var selection: Option
    let options: [Option]
    let optionLabel: (Option) -> String
    var onAddNew: (() -> Void)?

    func makeUIView(context: Context) -> TrailingMenuButton {
        let button = TrailingMenuButton(type: .system)
        button.backgroundColor = .clear
        button.showsMenuAsPrimaryAction = true
        return button
    }

    func updateUIView(_ button: TrailingMenuButton, context: Context) {
        var actions: [UIMenuElement] = options.map { option in
            UIAction(
                title: optionLabel(option),
                image: selection == option
                    ? UIImage(systemName: "checkmark")
                    : nil
            ) { _ in
                selection = option
            }
        }

        if let onAddNew {
            actions.append(
                UIAction(
                    title: "Add new…",
                    image: UIImage(systemName: "plus.circle.fill"),
                    attributes: []
                ) { _ in
                    onAddNew()
                }
            )
        }

        button.menu = UIMenu(children: actions)
    }
}

// MARK: - UIButton subclass anchoring menu to the trailing edge

final class TrailingMenuButton: UIButton {
    override func menuAttachmentPoint(for configuration: UIContextMenuConfiguration) -> CGPoint {
        CGPoint(x: bounds.maxX, y: bounds.minY)
    }
}

// MARK: - Preview

#Preview {
    enum Category: String, CaseIterable {
        case food = "Food"
        case transport = "Transport"
        case utilities = "Utilities"
        case entertainment = "Entertainment"
    }

    struct Demo: View {
        @State private var category: Category = .food
        @State private var categories: [Category] = Category.allCases
        @State private var addLog: String?

        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text("Select only")
                    .font(.caption.weight(.semibold))
                StyledSelectField(
                    title: "Category",
                    selection: $category,
                    options: categories,
                    optionLabel: { $0.rawValue }
                )

                Divider()

                Text("With add callback (parent handles UI)")
                    .font(.caption.weight(.semibold))
                StyledSelectField(
                    title: "Category",
                    selection: $category,
                    options: categories,
                    optionLabel: { $0.rawValue },
                    onAddNew: { addLog = "Add requested at \(Date().formatted(date: .omitted, time: .standard))" }
                )
                if let addLog {
                    Text(addLog)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(18)
            .background(Color(.systemGroupedBackground))
        }
    }

    return Demo()
}
