// Services/APIService.swift
import Foundation

class APIService: ObservableObject {
    static let shared = APIService()
    
    private init() {}
    
    // MARK: - Login
    func login(username: String, password: String) async throws -> LoginResponse {
        let url = URL(string: Constants.API.baseURL + Constants.API.Endpoints.auth)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = "action=login&username=\(username)&password=\(password)"
        request.httpBody = parameters.data(using: .utf8)
        
        print("🌐 API URL: \(url)")
        print("📤 Parameters: \(parameters)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("📥 HTTP Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        
        // Log raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Raw Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        do {
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            
            // Save user data if login successful
            if loginResponse.success {
                UserDefaults.standard.set(true, forKey: Constants.Storage.isLoggedIn)
                
                // Handle user data (from either 'user' or 'data' field)
                if let user = loginResponse.actualUser {
                    UserDefaults.standard.set(user.id, forKey: Constants.Storage.userId)
                    UserDefaults.standard.set(user.username, forKey: Constants.Storage.username)
                }
                
                // Save token if available
                if let token = loginResponse.token {
                    UserDefaults.standard.set(token, forKey: Constants.Storage.userToken)
                }
            }
            
            return loginResponse
        } catch {
            print("🚨 JSON Decode Error: \(error)")
            throw APIError.decodingError
        }
    }
    
    // MARK: - Get Categories
    func getCategories() async throws -> [Category] {
        let url = URL(string: Constants.API.baseURL + Constants.API.Endpoints.vocabulary + "?action=get_categories")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add auth header
        if let token = UserDefaults.standard.string(forKey: Constants.Storage.userToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        let categoriesResponse = try JSONDecoder().decode(CategoriesResponse.self, from: data)
        
        if categoriesResponse.success {
            return categoriesResponse.data ?? []
        } else {
            throw APIError.serverError
        }
    }
    
    // MARK: - Get Study Words
    func getStudyWords(categoryId: Int) async throws -> [Word] {
        let url = URL(string: Constants.API.baseURL + Constants.API.Endpoints.vocabulary + "?action=get_study_words&category_id=\(categoryId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add auth header
        if let token = UserDefaults.standard.string(forKey: Constants.Storage.userToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        let wordsResponse = try JSONDecoder().decode(WordsResponse.self, from: data)
        
        if wordsResponse.success {
            return wordsResponse.data ?? []
        } else {
            throw APIError.serverError
        }
    }
    
    // MARK: - Get Progress
    func getProgress() async throws -> StudyProgress {
        let url = URL(string: Constants.API.baseURL + Constants.API.Endpoints.progress + "?action=get")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add auth header
        if let token = UserDefaults.standard.string(forKey: Constants.Storage.userToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        let progressResponse = try JSONDecoder().decode(ProgressResponse.self, from: data)
        
        if progressResponse.success, let progress = progressResponse.data {
            return progress
        } else {
            throw APIError.serverError
        }
    }
    
    // MARK: - Logout
    func logout() {
        UserDefaults.standard.removeObject(forKey: Constants.Storage.isLoggedIn)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.userId)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.username)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.userToken)
    }
}

// MARK: - API Response Models
struct CategoriesResponse: Codable {
    let success: Bool
    let data: [Category]?
    let message: String?
}

struct WordsResponse: Codable {
    let success: Bool
    let data: [Word]?
    let message: String?
}

struct ProgressResponse: Codable {
    let success: Bool
    let data: StudyProgress?
    let message: String?
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case serverError
    case unauthorized
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL không hợp lệ"
        case .noData:
            return "Không có dữ liệu"
        case .serverError:
            return "Lỗi server"
        case .unauthorized:
            return "Chưa đăng nhập"
        case .decodingError:
            return "Lỗi phân tích dữ liệu"
        }
    }
}
