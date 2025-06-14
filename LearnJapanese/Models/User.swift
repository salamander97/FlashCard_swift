// Models/User.swift
import Foundation

struct User: Codable {
    let id: Int
    let username: String
    let email: String?
    let displayName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username, email
        case displayName = "display_name"
    }
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let success: Bool
    let message: String?
    let user: User?
    let token: String?
    let data: User?
    
    // Handle both possible response formats from your API
    var actualUser: User? {
        return user ?? data
    }
}
