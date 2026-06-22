//
//  GlassMenuPicker.swift
//  costa
//
//  A reusable glassmorphism-style Menu picker button.
//
//  Usage:
//      GlassMenuPicker(selection: $filter, options: TimeFilter.allCases) { $0.label }
//

import SwiftUI

struct GlassMenuPicker<Option: Hashable>: View {
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String

    var body: some View {
        // Render the visible pill + shadow OUTSIDE the Menu so UIKit's
        // button container can't clip the shadow blur.
        ZStack {
            GlassMenuLabel(text: label(selection))
                .allowsHitTesting(false) // touches go through to the Menu below

            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selection = option
                        }
                    } label: {
                        Label(
                            label(option),
                            systemImage: selection == option ? "checkmark" : ""
                        )
                    }
                }
            } label: {
                // Invisible label — the real visuals live in GlassMenuLabel above
                GlassMenuLabel(text: label(selection))
                    .opacity(0)
            }
            .menuStyle(.borderlessButton)
            .tint(.primary)
        }
        .fixedSize()
    }
}

// MARK: - Label shape (exported so it can be reused as a standalone button label)

struct GlassMenuLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.45),
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
                                    Color.white.opacity(0.7),
                                    Color(uiColor: .separator).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        // Shadow lives here — on the visible SwiftUI layer, not inside UIKit's Menu container
        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    enum Filter: String, CaseIterable, Hashable {
        case week = "Last 7 days"
        case month = "Last 30 days"
        case all = "All time"
    }

    struct Demo: View {
        @State private var selection: Filter = .week
        var body: some View {
            ZStack {
                LinearGradient(
                    colors: [.teal.opacity(0.3), .blue.opacity(0.2)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                GlassMenuPicker(selection: $selection, options: Filter.allCases) { $0.rawValue }
            }
        }
    }

    return Demo()
}
