//
//  AuthController.swift
//  costa
//

import Foundation
import Observation

@MainActor
@Observable
final class AuthController {
    private static let persistedUserKey = "com.abui.costa.persistedUser"

    private(set) var user: AuthUser?
    private(set) var accessToken: String?

    private var refreshToken: String?
    private var tokenExpiresAt: Date?

    private let api = AuthAPIClient()

    var isAuthenticated: Bool { accessToken != nil }

    init() {
        if let tokens = KeychainSessionStore.loadTokens() {
            accessToken = tokens.access
            refreshToken = tokens.refresh
            if let expiresAt = tokens.expiresAt {
                tokenExpiresAt = Date(timeIntervalSince1970: TimeInterval(expiresAt))
            }
            user = Self.loadPersistedUser()
        }
    }

    /// Handles `costa://oauth?code=<nonce>` deep links (cold/warm start outside ASWebAuthenticationSession).
    func handleOAuthCallback(url: URL) async {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

        if let errorMsg = items?.first(where: { $0.name == "error" })?.value {
            // Surface errors if a UI hook is needed; currently just ignores on cold-start deep link.
            _ = errorMsg
            return
        }

        guard let code = items?.first(where: { $0.name == "code" })?.value, !code.isEmpty else { return }

        do {
            let response = try await api.mobileExchange(code: code)
            try applyLoginResponse(response)
        } catch {
            // Cold-start exchange failures are silent; user can re-authenticate from LoginView.
        }
    }

    func applyLoginResponse(_ response: LoginResponse) throws {
        try KeychainSessionStore.save(session: response.session)
        user = response.user
        accessToken = response.session.access_token
        refreshToken = response.session.refresh_token
        
        if let expiresAt = response.session.expires_at {
            tokenExpiresAt = Date(timeIntervalSince1970: TimeInterval(expiresAt))
        } else if let expiresIn = response.session.expires_in {
            tokenExpiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        }
        
        if let data = try? JSONEncoder().encode(response.user) {
            UserDefaults.standard.set(data, forKey: Self.persistedUserKey)
        }
    }

    func login(email: String, password: String) async throws {
        let response = try await api.login(email: email, password: password)
        try applyLoginResponse(response)
    }

    func signOut() async {
        if let token = accessToken {
            try? await api.logout(accessToken: token)
        }
        try? KeychainSessionStore.clear()
        user = nil
        accessToken = nil
        refreshToken = nil
        tokenExpiresAt = nil
        UserDefaults.standard.removeObject(forKey: Self.persistedUserKey)
    }

    func validToken() async -> String? {
        guard let token = accessToken else { return nil }
        
        let buffer: TimeInterval = 60
        let expirationThreshold = Date().addingTimeInterval(buffer)
        
        if let expiresAt = tokenExpiresAt, expiresAt > expirationThreshold {
            return token
        }
        
        guard let refresh = refreshToken else {
            await signOut()
            return nil
        }
        
        do {
            let response = try await api.refreshSession(refreshToken: refresh)
            try applyLoginResponse(response)
            return response.session.access_token
        } catch {
            await signOut()
            return nil
        }
    }

    func handleUnauthorized() async {
        await signOut()
    }

    private static func loadPersistedUser() -> AuthUser? {
        guard let data = UserDefaults.standard.data(forKey: persistedUserKey) else { return nil }
        return try? JSONDecoder().decode(AuthUser.self, from: data)
    }

    #if DEBUG
    /// Xcode Previews: `validToken()` returns without refresh or network.
    static func previewAuthenticated() -> AuthController {
        let c = AuthController()
        c.installPreviewSession()
        return c
    }

    private func installPreviewSession() {
        accessToken = "preview-access-token"
        refreshToken = "preview-refresh-token"
        tokenExpiresAt = .distantFuture
    }
    #endif
}
