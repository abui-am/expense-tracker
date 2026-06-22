//
//  costaApp.swift
//  costa
//
//  Created by Abuidillah Adjie Muliadi on 30/04/26.
//

import SwiftUI

@main
struct costaApp: App {
    @State private var authController = AuthController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authController)
                .onOpenURL { url in
                    // Handles costa://oauth?code=<nonce> when the app is opened cold/warm
                    // from a deep link (e.g. Android-style or Safari fallback).
                    // ASWebAuthenticationSession delivers the URL inline to GoogleOAuthSession,
                    // so this path is only reached in edge cases.
                    guard url.scheme?.lowercased() == GoogleOAuthSession.callbackScheme,
                          url.host?.lowercased() == "oauth"
                    else { return }
                    Task { await authController.handleOAuthCallback(url: url) }
                }
        }
    }
}
