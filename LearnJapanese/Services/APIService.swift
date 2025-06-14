// Services/APIService.swift - Improved Version
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
        request.timeoutInterval = Constants.API.timeout
        
        let parameters = "action=login&username=\(username)&password=\(password)"
        request.httpBody = parameters.data(using: .utf8)
        
        print("🌐 API URL: \(url)")
        print("📤 Parameters: \(parameters)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        print("📥 HTTP Status: \(statusCode)")
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Raw Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError
        }
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError
        default:
            print("⚠️ Unexpected status code: \(httpResponse.statusCode)")
            throw APIError.serverError
        }
        
        do {
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            
            // Save user data if login successful
            if loginResponse.success {
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: Constants.Storage.isLoggedIn)
                    
                    // Handle user data (from either 'user' or 'data' field)
                    if let user = loginResponse.actualUser {
                        UserDefaults.standard.set(user.id, forKey: Constants.Storage.userId)
                        UserDefaults.standard.set(user.username, forKey: Constants.Storage.username)
                        print("💾 Saved user: \(user.username) (ID: \(user.id))")
                    }
                    
                    // Save token if available
                    if let token = loginResponse.token {
                        UserDefaults.standard.set(token, forKey: Constants.Storage.userToken)
                        print("🔑 Saved token: \(token.prefix(10))...")
                    } else {
                        print("⚠️ No token received from server")
                    }
                }
            }
            
            return loginResponse
        } catch {
            print("🚨 JSON Decode Error: \(error)")
            throw APIError.decodingError
        }
    }
    
    // MARK: - Get Categories with improved error handling
    func getCategories() async throws -> [Category] {
        // Check if user is logged in
        guard UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn) else {
            print("❌ User not logged in, cannot get categories")
            throw APIError.unauthorized
        }
        
        let url = URL(string: Constants.API.baseURL + Constants.API.Endpoints.vocabulary + "?action=get_categories")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Constants.API.timeout
        
        // Add auth headers - try both methods your API might expect
        if let token = UserDefaults.standard.string(forKey: Constants.Storage.userToken), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Using token: \(token.prefix(10))...")
        }
        
        // Also add user_id as query parameter (common in PHP APIs)
        if let userId = UserDefaults.standard.object(forKey: Constants.Storage.userId) as? Int {
            let urlWithUserId = URL(string: url.absoluteString + "&user_id=\(userId)")!
            request.url = urlWithUserId
            print("👤 Using user_id: \(userId)")
        }
        
        print("🌐 Categories API URL: \(request.url?.absoluteString ?? "nil")")
        print("📤 Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("📥 Categories HTTP Status: \(statusCode)")
            
            // Log response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Categories Raw Response: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError
            }
            
            switch httpResponse.statusCode {
            case 200:
                break
            case 401:
                // Clear login data and throw unauthorized
                await logout()
                throw APIError.unauthorized
            case 404:
                throw APIError.notFound
            default:
                throw APIError.serverError
            }
            
            let categoriesResponse = try JSONDecoder().decode(CategoriesResponse.self, from: data)
            
            if categoriesResponse.success {
                let categories = categoriesResponse.data ?? []
                print("✅ Loaded \(categories.count) categories")
                return categories
            } else {
                let message = categoriesResponse.message ?? "Unknown error"
                print("❌ Categories API failed: \(message)")
                throw APIError.serverError
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            print("🚨 Network error getting categories: \(error)")
            throw APIError.networkError
        }
    }
    
    // MARK: - Get Study Words with improved error handling
    func getStudyWords(categoryId: Int) async throws -> [Word] {
        // Check if user is logged in
        guard UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn) else {
            print("❌ User not logged in, cannot get study words")
            throw APIError.unauthorized
        }
        
        var urlComponents = URLComponents(string: Constants.API.baseURL + Constants.API.Endpoints.vocabulary)!
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "get_study_words"),
            URLQueryItem(name: "category_id", value: "\(categoryId)")
        ]
        
        // Add user_id if available
        if let userId = UserDefaults.standard.object(forKey: Constants.Storage.userId) as? Int {
            urlComponents.queryItems?.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Constants.API.timeout
        
        // Add auth header
        if let token = UserDefaults.standard.string(forKey: Constants.Storage.userToken), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("🌐 Study Words API URL: \(url.absoluteString)")
        print("📤 Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("📥 Study Words HTTP Status: \(statusCode)")
            
            // Log response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Study Words Raw Response: \(responseString.prefix(500))...")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError
            }
            
            switch httpResponse.statusCode {
            case 200:
                break
            case 401:
                await logout()
                throw APIError.unauthorized
            case 404:
                throw APIError.notFound
            default:
                throw APIError.serverError
            }
            
            let wordsResponse = try JSONDecoder().decode(WordsResponse.self, from: data)
            
            if wordsResponse.success {
                let words = wordsResponse.data ?? []
                print("✅ Loaded \(words.count) study words for category \(categoryId)")
                return words
            } else {
                let message = wordsResponse.message ?? "Unknown error"
                print("❌ Study Words API failed: \(message)")
                throw APIError.serverError
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            print("🚨 Network error getting study words: \(error)")
            throw APIError.networkError
        }
    }
    
    // MARK: - Update Word Knowledge
    func updateWordKnowledge(
        wordId: Int,
        knowledgeLevel: Int,
        easeFactor: Double,
        intervalDays: Int,
        nextReviewDate: Date
    ) async throws {
        guard UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: Constants.API.baseURL + Constants.API.Endpoints.vocabulary)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.API.timeout
        
        // Add auth header
        if let token = UserDefaults.standard.string(forKey: Constants.Storage.userToken), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Format date for PHP
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let nextReviewDateString = dateFormatter.string(from: nextReviewDate)
        
        var parameters = [
            "action=update_word_knowledge",
            "word_id=\(wordId)",
            "knowledge_level=\(knowledgeLevel)",
            "ease_factor=\(easeFactor)",
            "interval_days=\(intervalDays)",
            "next_review_date=\(nextReviewDateString)"
        ]
        
        // Add user_id if available
        if let userId = UserDefaults.standard.object(forKey: Constants.Storage.userId) as? Int {
            parameters.append("user_id=\(userId)")
        }
        
        let parametersString = parameters.joined(separator: "&")
        request.httpBody = parametersString.data(using: .utf8)
        
        print("🌐 Update Word Knowledge URL: \(url)")
        print("📤 Parameters: \(parametersString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        print("📥 Update Word Knowledge Status: \(statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Update Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
    }
    
    // MARK: - Get Progress
    func getProgress() async throws -> StudyProgress {
        guard UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn) else {
            throw APIError.unauthorized
        }
        
        var urlComponents = URLComponents(string: Constants.API.baseURL + Constants.API.Endpoints.progress)!
        urlComponents.queryItems = [URLQueryItem(name: "action", value: "get")]
        
        // Add user_id if available
        if let userId = UserDefaults.standard.object(forKey: Constants.Storage.userId) as? Int {
            urlComponents.queryItems?.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Constants.API.timeout
        
        // Add auth header
        if let token = UserDefaults.standard.string(forKey: Constants.Storage.userToken), !token.isEmpty {
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
    @MainActor
    func logout() {
        print("🚪 APIService logout - clearing all user data")
        UserDefaults.standard.removeObject(forKey: Constants.Storage.isLoggedIn)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.userId)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.username)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.userToken)
    }
}

// MARK: - API Response Models (unchanged)
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

// MARK: - Enhanced API Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case serverError
    case unauthorized
    case decodingError
    case networkError
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL không hợp lệ"
        case .noData:
            return "Không có dữ liệu"
        case .serverError:
            return "Lỗi server (500)"
        case .unauthorized:
            return "Phiên đăng nhập đã hết hạn"
        case .decodingError:
            return "Lỗi phân tích dữ liệu JSON"
        case .networkError:
            return "Lỗi kết nối mạng"
        case .notFound:
            return "Không tìm thấy dữ liệu (404)"
        }
    }
}
