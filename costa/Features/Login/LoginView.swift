//
//  LoginView.swift
//  costa
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthController.self) private var auth

    @State private var email = ""
    @State private var password = ""
    @State private var isBusy = false
    @State private var errorMessage: String?

    private var googleStartURL: URL {
        var c = URLComponents(url: APIBaseURL.url.appending(path: "api/auth/oauth/google"), resolvingAgainstBaseURL: true)!
        c.queryItems = [URLQueryItem(name: "redirect_to", value: "\(GoogleOAuthSession.callbackScheme)://oauth")]
        return c.url!
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }

                Section {
                    Button {
                        Task { await signInWithPassword() }
                    } label: {
                        if isBusy {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isBusy || email.isEmpty || password.isEmpty)

                    Button {
                        errorMessage = nil
                        startGoogleSignIn()
                    } label: {
                        Label("Continue with Google", systemImage: "globe")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(isBusy)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Sign In")
        }
    }

    private func startGoogleSignIn() {
        isBusy = true
        let api = AuthAPIClient()
        GoogleOAuthSession.perform(startURL: googleStartURL, api: api) { result in
            Task { @MainActor in
                isBusy = false
                switch result {
                case let .success(response):
                    do {
                        try auth.applyLoginResponse(response)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                case let .failure(err):
                    errorMessage = err.localizedDescription
                }
            }
        }
    }

    private func signInWithPassword() async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            try await auth.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthController())
}
