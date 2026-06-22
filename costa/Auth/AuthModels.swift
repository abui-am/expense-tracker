//
//  AuthModels.swift
//  costa
//

import Foundation

struct LoginResponse: Codable, Sendable {
    var user: AuthUser
    var session: AuthSession
}

struct AuthUser: Codable, Sendable, Equatable {
    var id: String
    var email: String?
}

struct AuthSession: Codable, Sendable, Equatable {
    var access_token: String
    var refresh_token: String?
    var expires_in: Int?
    var expires_at: Int64?
    var token_type: String?
}

struct APIErrorEnvelope: Codable, Sendable {
    var error: String
}
