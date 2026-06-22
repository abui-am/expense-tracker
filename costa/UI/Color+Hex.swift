//
//  Color+Hex.swift
//  costa
//

import SwiftUI

extension Color {
    /// Parses `#RGB`, `#RRGGBB`, or `#RRGGBBAA` (case-insensitive). Returns `nil` if invalid or empty.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.hasPrefix("#") else { return nil }
        s.removeFirst()
        if s.count == 3 {
            s = s.map { String(repeating: $0, count: 2) }.joined()
        }
        guard let n = UInt64(s, radix: 16) else { return nil }
        let r, g, b, a: Double
        if s.count == 8 {
            r = Double((n >> 24) & 0xFF) / 255
            g = Double((n >> 16) & 0xFF) / 255
            b = Double((n >> 8) & 0xFF) / 255
            a = Double(n & 0xFF) / 255
        } else if s.count == 6 {
            r = Double((n >> 16) & 0xFF) / 255
            g = Double((n >> 8) & 0xFF) / 255
            b = Double(n & 0xFF) / 255
            a = 1
        } else {
            return nil
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
