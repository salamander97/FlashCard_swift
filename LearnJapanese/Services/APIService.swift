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
    
    // MARK: - Get Categories cũng cần fix nếu cần
    func getCategories() async throws -> [Category] {
        guard UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn) else {
            print("❌ User not logged in, cannot get categories")
            throw APIError.unauthorized
        }
        
        // ✅ FIX: Có thể categories endpoint cũng khác
        var urlComponents = URLComponents(string: Constants.API.baseURL + Constants.API.Endpoints.vocabulary)!
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "get_categories")
        ]
        
        // ✅ FIX: Sử dụng 'user' thay vì 'user_id'
        if let userId = UserDefaults.standard.object(forKey: Constants.Storage.userId) as? Int {
            urlComponents.queryItems?.append(URLQueryItem(name: "user", value: "\(userId)"))
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Constants.API.timeout
        
        // Add auth headers
        if let token = UserDefaults.standard.string(forKey: Constants.Storage.userToken), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("🌐 Categories API URL: \(url.absoluteString)")
        print("📤 Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("📥 Categories HTTP Status: \(statusCode)")
            
            // Log response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Categories Raw Response: \(responseString.prefix(500))...")
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
    
    // MARK: - Get Study Words với correct endpoint
    func getStudyWords(categoryId: Int) async throws -> [Word] {
        guard UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn) else {
            print("❌ User not logged in, cannot get study words")
            throw APIError.unauthorized
        }
        
        // ✅ FIX: Sử dụng correct endpoint và parameters
        var urlComponents = URLComponents(string: Constants.API.baseURL + Constants.API.Endpoints.vocabulary)!
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "get_category_words"),  // ✅ FIX: get_category_words
            URLQueryItem(name: "category_id", value: "\(categoryId)"),
            URLQueryItem(name: "mode", value: "all"),                   // ✅ FIX: thêm mode=all
            URLQueryItem(name: "limit", value: "50")                    // ✅ FIX: thêm limit=50
        ]
        
        // ✅ FIX: Sử dụng 'user' thay vì 'user_id'
        if let userId = UserDefaults.standard.object(forKey: Constants.Storage.userId) as? Int {
            urlComponents.queryItems?.append(URLQueryItem(name: "user", value: "\(userId)"))
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Constants.API.timeout
        
        // Add auth header nếu cần
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
extension APIService {
    
    // MARK: - Update Category Progress
    func updateCategoryProgress(
        categoryId: Int,
        wordsLearned: Int,
        wordsMastered: Int,
        studyTime: Int,
        isCompleted: Bool
    ) async throws {
        guard UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: Constants.API.baseURL + Constants.API.Endpoints.progress)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.API.timeout
        
        // Add auth header
        if let token = UserDefaults.standard.string(forKey: Constants.Storage.userToken), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var parameters = [
            "action=save_category_progress",
            "category_id=\(categoryId)",
            "words_learned=\(wordsLearned)",
            "words_mastered=\(wordsMastered)",
            "study_time=\(studyTime)",
            "is_completed=\(isCompleted ? 1 : 0)"
        ]
        
        // Add user_id if available
        if let userId = UserDefaults.standard.object(forKey: Constants.Storage.userId) as? Int {
            parameters.append("user_id=\(userId)")
        }
        
        let parametersString = parameters.joined(separator: "&")
        request.httpBody = parametersString.data(using: .utf8)
        
        print("🌐 Update Category Progress URL: \(url)")
        print("📤 Parameters: \(parametersString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("📥 Update Category Progress Status: \(statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Update Response: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError
            }
            
            switch httpResponse.statusCode {
            case 200:
                let updateResponse = try JSONDecoder().decode(UpdateProgressResponse.self, from: data)
                if !updateResponse.success {
                    let message = updateResponse.message ?? "Unknown error"
                    print("❌ Update progress failed: \(message)")
                    throw APIError.serverError
                }
                print("✅ Category progress updated successfully")
                
            case 401:
                await logout()
                throw APIError.unauthorized
            default:
                throw APIError.serverError
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            print("🚨 Network error updating category progress: \(error)")
            throw APIError.networkError
        }
    }
    
    // MARK: - Unlock Next Category
    func unlockNextCategory(completedCategoryId: Int) async throws {
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
        
        var parameters = [
            "action=unlock_next_category",
            "completed_category_id=\(completedCategoryId)"
        ]
        
        // Add user_id if available
        if let userId = UserDefaults.standard.object(forKey: Constants.Storage.userId) as? Int {
            parameters.append("user_id=\(userId)")
        }
        
        let parametersString = parameters.joined(separator: "&")
        request.httpBody = parametersString.data(using: .utf8)
        
        print("🌐 Unlock Next Category URL: \(url)")
        print("📤 Parameters: \(parametersString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("📥 Unlock Next Category Status: \(statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Unlock Response: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError
            }
            
            switch httpResponse.statusCode {
            case 200:
                let unlockResponse = try JSONDecoder().decode(UnlockCategoryResponse.self, from: data)
                if unlockResponse.success {
                    print("✅ Next category unlocked successfully")
                    if let unlockedCategory = unlockResponse.unlockedCategory {
                        print("🔓 Unlocked category: \(unlockedCategory)")
                    }
                } else {
                    let message = unlockResponse.message ?? "No more categories to unlock"
                    print("ℹ️ Unlock response: \(message)")
                    // Không throw error vì có thể không có category nào để unlock
                }
                
            case 401:
                await logout()
                throw APIError.unauthorized
            default:
                throw APIError.serverError
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            print("🚨 Network error unlocking next category: \(error)")
            // Không throw error cho unlock vì đây không phải critical operation
            print("⚠️ Failed to unlock next category, but progress was saved")
        }
    }
    
    // MARK: - Save Word Knowledge (SRS)
    func saveWordKnowledge(
        wordId: Int,
        knowledgeLevel: Int,
        easeFactor: Double,
        intervalDays: Int,
        nextReviewDate: Date,
        difficulty: String
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
            "action=save_word_knowledge",
            "word_id=\(wordId)",
            "knowledge_level=\(knowledgeLevel)",
            "ease_factor=\(easeFactor)",
            "interval_days=\(intervalDays)",
            "next_review_date=\(nextReviewDateString)",
            "difficulty=\(difficulty)"
        ]
        
        // Add user_id if available
        if let userId = UserDefaults.standard.object(forKey: Constants.Storage.userId) as? Int {
            parameters.append("user_id=\(userId)")
        }
        
        let parametersString = parameters.joined(separator: "&")
        request.httpBody = parametersString.data(using: .utf8)
        
        print("🌐 Save Word Knowledge URL: \(url)")
        print("📤 Parameters: \(parametersString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("📥 Save Word Knowledge Status: \(statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Save Word Response: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw APIError.serverError
            }
            
            let saveResponse = try JSONDecoder().decode(SaveWordResponse.self, from: data)
            if !saveResponse.success {
                let message = saveResponse.message ?? "Unknown error"
                print("❌ Save word knowledge failed: \(message)")
                throw APIError.serverError
            }
            
            print("✅ Word knowledge saved successfully")
            
        } catch let error as APIError {
            throw error
        } catch {
            print("🚨 Network error saving word knowledge: \(error)")
            throw APIError.networkError
        }
    }
    
    // MARK: - Get User Statistics
    func getUserStatistics() async throws -> UserStatistics {
        guard UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn) else {
            throw APIError.unauthorized
        }
        
        var urlComponents = URLComponents(string: Constants.API.baseURL + Constants.API.Endpoints.progress)!
        urlComponents.queryItems = [URLQueryItem(name: "action", value: "get_user_stats")]
        
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
        
        print("🌐 User Statistics URL: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("📥 User Statistics Status: \(statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Statistics Response: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError
            }
            
            switch httpResponse.statusCode {
            case 200:
                let statsResponse = try JSONDecoder().decode(UserStatisticsResponse.self, from: data)
                if statsResponse.success, let stats = statsResponse.data {
                    return stats
                } else {
                    let message = statsResponse.message ?? "Unknown error"
                    print("❌ Get statistics failed: \(message)")
                    throw APIError.serverError
                }
                
            case 401:
                await logout()
                throw APIError.unauthorized
            default:
                throw APIError.serverError
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            print("🚨 Network error getting user statistics: \(error)")
            throw APIError.networkError
        }
    }
}

// MARK: - Response Models cho Progress APIs
struct UpdateProgressResponse: Codable {
    let success: Bool
    let message: String?
    let data: ProgressData?
}

struct ProgressData: Codable {
    let categoryId: Int
    let completionPercentage: Double
    let isCompleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case completionPercentage = "completion_percentage"
        case isCompleted = "is_completed"
    }
}

struct UnlockCategoryResponse: Codable {
    let success: Bool
    let message: String?
    let unlockedCategory: String?
    
    enum CodingKeys: String, CodingKey {
        case success, message
        case unlockedCategory = "unlocked_category"
    }
}

struct SaveWordResponse: Codable {
    let success: Bool
    let message: String?
    let data: WordKnowledgeData?
}

struct WordKnowledgeData: Codable {
    let wordId: Int
    let knowledgeLevel: Int
    let nextReviewDate: String
    
    enum CodingKeys: String, CodingKey {
        case wordId = "word_id"
        case knowledgeLevel = "knowledge_level"
        case nextReviewDate = "next_review_date"
    }
}

struct UserStatistics: Codable {
    let totalWordsLearned: Int
    let totalWordsMastered: Int
    let totalStudyTime: Int
    let learningStreak: Int
    let categoriesCompleted: Int
    let totalCategories: Int
    let averageAccuracy: Double
    let weeklyStudyTime: Int
    let monthlyStudyTime: Int
    
    enum CodingKeys: String, CodingKey {
        case totalWordsLearned = "total_words_learned"
        case totalWordsMastered = "total_words_mastered"
        case totalStudyTime = "total_study_time"
        case learningStreak = "learning_streak"
        case categoriesCompleted = "categories_completed"
        case totalCategories = "total_categories"
        case averageAccuracy = "average_accuracy"
        case weeklyStudyTime = "weekly_study_time"
        case monthlyStudyTime = "monthly_study_time"
    }
    
    var completionPercentage: Double {
        guard totalCategories > 0 else { return 0 }
        return Double(categoriesCompleted) / Double(totalCategories) * 100
    }
    
    var formattedStudyTime: String {
        let hours = totalStudyTime / 3600
        let minutes = (totalStudyTime % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct UserStatisticsResponse: Codable {
    let success: Bool
    let message: String?
    let data: UserStatistics?
}
