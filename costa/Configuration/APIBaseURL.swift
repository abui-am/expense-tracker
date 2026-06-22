//
//  APIBaseURL.swift
//  costa
//

import Foundation

enum APIBaseURL {
    /// Base URL from `BackendAPIBaseURL` in Info.plist, or `http://localhost:3222` (see BE-Integration.md).
    static var string: String {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "BackendAPIBaseURL") as? String,
              !raw.isEmpty
        else {
            return "http://localhost:3222"
        }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines).trimmingSuffixSlash()
    }

    static var url: URL {
        guard let url = URL(string: string) else {
            preconditionFailure("Invalid BackendAPIBaseURL: \(string)")
        }
        return url
    }
}

private extension String {
    func trimmingSuffixSlash() -> String {
        var s = self
        while s.hasSuffix("/") { s.removeLast() }
        return s
    }
}
