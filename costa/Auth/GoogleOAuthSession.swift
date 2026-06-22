//
//  GoogleOAuthSession.swift
//  costa
//
//  Two-step nonce flow (BE-Integration.md -- Native client integration):
//  1. ASWebAuthenticationSession opens GET /api/auth/oauth/google?redirect_to=costa://oauth
//  2. BFF redirects to costa://oauth?code=<nonce> after server-side code exchange
//  3. App POSTs nonce to POST /api/auth/mobile/exchange and receives LoginResponse over HTTPS
//  Tokens never appear in any URL.
//

import AuthenticationServices
import UIKit

enum GoogleOAuthSession {
    static let callbackScheme = "costa"

    @MainActor
    static func perform(
        startURL: URL,
        api: AuthAPIClient,
        completion: @escaping @Sendable (Result<LoginResponse, Error>) -> Void
    ) {
        let session = ASWebAuthenticationSession(
            url: startURL,
            callbackURLScheme: callbackScheme
        ) { callbackURL, error in
            if let error {
                Task { @MainActor in completion(.failure(error)) }
                return
            }
            guard let callbackURL else {
                Task { @MainActor in
                    completion(.failure(AuthAPIError.httpStatus(-1, "OAuth completed with no callback URL.")))
                }
                return
            }

            let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems

            if let errorMsg = items?.first(where: { $0.name == "error" })?.value {
                Task { @MainActor in
                    completion(.failure(AuthAPIError.httpStatus(401, errorMsg)))
                }
                return
            }

            guard let code = items?.first(where: { $0.name == "code" })?.value, !code.isEmpty else {
                Task { @MainActor in
                    completion(.failure(AuthAPIError.httpStatus(-1, "OAuth callback missing 'code' parameter.")))
                }
                return
            }

            Task {
                do {
                    let login = try await api.mobileExchange(code: code)
                    Task { @MainActor in completion(.success(login)) }
                } catch {
                    Task { @MainActor in completion(.failure(error)) }
                }
            }
        }
        session.presentationContextProvider = PresentationBridge.shared
        session.prefersEphemeralWebBrowserSession = false
        if !session.start() {
            Task { @MainActor in
                completion(.failure(AuthAPIError.httpStatus(-1, "Could not start sign-in session.")))
            }
        }
    }
}

// MARK: - Presentation anchor

private final class PresentationBridge: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = PresentationBridge()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            if let window = scene.windows.first(where: { $0.isKeyWindow }) { return window }
        }
        if let scene = scenes.first {
            if let window = scene.windows.first { return window }
            return UIWindow(windowScene: scene)
        }
        // Guaranteed to have a scene; force-unwrap is acceptable here.
        return UIWindow(windowScene: UIApplication.shared.connectedScenes.first as! UIWindowScene)
    }
}
