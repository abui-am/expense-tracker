//
//  AuthAPIClient.swift
//  costa
//

import Foundation

enum AuthAPIError: LocalizedError {
    case invalidURL
    case httpStatus(Int, String?)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid API URL"
        case let .httpStatus(code, message): message ?? "Request failed (\(code))"
        case let .decoding(err): err.localizedDescription
        case let .transport(err): err.localizedDescription
        }
    }
}

struct AuthAPIClient: Sendable {
    var baseURL: URL

    init(baseURL: URL = APIBaseURL.url) {
        self.baseURL = baseURL
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let url = baseURL.appending(path: "api/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["email": email, "password": password])
        return try await executeLoginRequest(request)
    }

    /// Exchanges the single-use nonce from `costa://oauth?code=<nonce>` for a full session.
    /// See BE-Integration.md — Step 4 (POST /api/auth/mobile/exchange).
    func mobileExchange(code: String) async throws -> LoginResponse {
        let url = baseURL.appending(path: "api/auth/mobile/exchange")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["code": code])
        return try await executeLoginRequest(request)
    }

    func logout(accessToken: String) async throws {
        let url = baseURL.appending(path: "api/auth/logout")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthAPIError.transport(error)
        }
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200 ..< 300).contains(code) else {
            throw parseError(data: data, status: code)
        }
    }

    func refreshSession(refreshToken: String) async throws -> LoginResponse {
        let url = baseURL.appending(path: "api/auth/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["refresh_token": refreshToken])
        return try await executeLoginRequest(request)
    }

    private func executeLoginRequest(_ request: URLRequest) async throws -> LoginResponse {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthAPIError.transport(error)
        }
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200 ..< 300).contains(code) else {
            throw parseError(data: data, status: code)
        }
        do {
            return try JSONDecoder().decode(LoginResponse.self, from: data)
        } catch {
            throw AuthAPIError.decoding(error)
        }
    }

    private func parseError(data: Data, status: Int) -> AuthAPIError {
        if let env = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data) {
            return .httpStatus(status, env.error)
        }
        let raw = String(data: data, encoding: .utf8)
        return .httpStatus(status, raw)
    }
}
