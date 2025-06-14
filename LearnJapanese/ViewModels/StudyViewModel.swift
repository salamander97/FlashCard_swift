//
//  StudyViewModel.swift
//  LearnJapanese
//
//  Created by Trung Hiếu on 2025/06/14.
//

// ViewModels/StudyViewModel.swift - Improved Version
import Foundation
import SwiftUI

@MainActor
class StudyViewModel: ObservableObject {
    @Published var studyWords: [Word] = []
    @Published var currentWordIndex = 0
    @Published var isCardFlipped = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var selectedCategoryId = 1 // Default category
    @Published var showingSessionComplete = false
    @Published var selectedJLPTLevel: String? = nil
    @Published var categories: [Category] = []
    @Published var filteredCategories: [Category] = []
    @Published var isPickingCategory = false
    @Published var selectedCategory: Category? = nil
    // Statistics
    @Published var correctCount = 0
    @Published var normalCount = 0
    @Published var hardCount = 0
    @Published var totalAnswered = 0
    
    private let apiService = APIService.shared
    private let srsManager = SRSManager.shared
    
    var progressPercentage: Double {
        guard !studyWords.isEmpty else { return 0 }
        return Double(currentWordIndex) / Double(studyWords.count) * 100
    }
    
    var currentWord: Word? {
        guard currentWordIndex < studyWords.count else { return nil }
        return studyWords[currentWordIndex]
    }
    
    var isSessionComplete: Bool {
        return currentWordIndex >= studyWords.count
    }
    
    func loadCategories() async {
        do {
            categories = try await apiService.getCategories()
        } catch {
            print("❌ Lỗi load categories: \(error)")
            categories = []
        }
    }

    // Lọc category theo JLPT Level
    func filterCategories(for level: String) {
        // Map JLPT level (N5 → 1, N4 → 2, ...)
        let levelMap = ["N5": 1, "N4": 2, "N3": 3, "N2": 4, "N1": 5]
        guard let levelNum = levelMap[level] else { return }
        filteredCategories = categories.filter { $0.difficultyLevel == levelNum }
        isPickingCategory = true
    }
    
    // MARK: - Load Study Words with better error handling
    func loadStudyWords() async {
        isLoading = true
        errorMessage = ""
        
        do {
            print("🔄 Loading study words for category: \(selectedCategoryId)")
            
            // Check if user is logged in first
            guard UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn) else {
                print("❌ User not logged in, cannot load study words")
                errorMessage = "Vui lòng đăng nhập lại"
                isLoading = false
                
                // Notify to show login screen
                NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
                return
            }
            
            print("✅ User is logged in, proceeding to load words...")
            
            // First, try to get words for the selected category
            let words = try await apiService.getStudyWords(categoryId: selectedCategoryId)
            print("📚 API returned \(words.count) words for category \(selectedCategoryId)")
            
            if words.isEmpty {
                print("🔄 No words in category \(selectedCategoryId), trying to get all categories...")
                
                // Try to get all categories and find one with words
                let categories = try await apiService.getCategories()
                print("📂 Found \(categories.count) categories")
                
                var foundWordsInCategory = false
                
                for category in categories {
                    if category.id != selectedCategoryId {
                        print("🔄 Trying category: \(category.name) (ID: \(category.id))")
                        
                        let categoryWords = try await apiService.getStudyWords(categoryId: category.id)
                        
                        if !categoryWords.isEmpty {
                            print("✅ Found \(categoryWords.count) words in category: \(category.name)")
                            studyWords = categoryWords
                            selectedCategoryId = category.id
                            currentWordIndex = 0
                            isCardFlipped = false
                            resetStatistics()
                            foundWordsInCategory = true
                            break
                        }
                    }
                }
                
                if !foundWordsInCategory {
                    print("❌ No words found in any category, loading sample data")
                    loadSampleData()
                }
                
            } else {
                // Successfully loaded words from selected category
                studyWords = words
                currentWordIndex = 0
                isCardFlipped = false
                resetStatistics()
                print("✅ Loaded \(studyWords.count) words successfully")
            }
            
        } catch APIError.unauthorized {
            print("❌ Unauthorized - clearing login and showing login screen")
            errorMessage = "Phiên đăng nhập đã hết hạn"
            
            // Clear login data and show login screen
            apiService.logout()
            NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
            
        } catch APIError.networkError {
            print("❌ Network error - loading sample data for offline use")
            errorMessage = "Lỗi kết nối mạng. Sử dụng dữ liệu mẫu."
            loadSampleData()
            
        } catch APIError.serverError {
            print("❌ Server error - loading sample data")
            errorMessage = "Lỗi server. Sử dụng dữ liệu mẫu."
            loadSampleData()
            
        } catch {
            print("❌ Unexpected error: \(error)")
            errorMessage = "Lỗi không xác định: \(error.localizedDescription)"
            loadSampleData()
        }
        
        isLoading = false
    }
    
    // MARK: - Enhanced Sample Data
    private func loadSampleData() {
        print("🧪 Loading enhanced sample data for testing...")
        studyWords = [
            Word(
                id: 1,
                japaneseWord: "おはよう",
                kanji: nil,
                romaji: "ohayou",
                vietnameseMeaning: "Chào buổi sáng",
                exampleSentenceJp: "おはようございます。",
                exampleSentenceVn: "Xin chào buổi sáng."
            ),
            Word(
                id: 2,
                japaneseWord: "ありがとう",
                kanji: nil,
                romaji: "arigatou",
                vietnameseMeaning: "Cảm ơn",
                exampleSentenceJp: "ありがとうございます。",
                exampleSentenceVn: "Cảm ơn anh/chị."
            ),
            Word(
                id: 3,
                japaneseWord: "すみません",
                kanji: nil,
                romaji: "sumimasen",
                vietnameseMeaning: "Xin lỗi",
                exampleSentenceJp: "すみません、遅れました。",
                exampleSentenceVn: "Xin lỗi, tôi đến muộn."
            ),
            Word(
                id: 4,
                japaneseWord: "こんにちは",
                kanji: nil,
                romaji: "konnichiwa",
                vietnameseMeaning: "Xin chào (buổi trưa)",
                exampleSentenceJp: "こんにちは、元気ですか？",
                exampleSentenceVn: "Xin chào, bạn có khỏe không?"
            ),
            Word(
                id: 5,
                japaneseWord: "さようなら",
                kanji: nil,
                romaji: "sayounara",
                vietnameseMeaning: "Tạm biệt",
                exampleSentenceJp: "さようなら、また明日。",
                exampleSentenceVn: "Tạm biệt, hẹn gặp lại ngày mai."
            ),
            Word(
                id: 6,
                japaneseWord: "はじめまして",
                kanji: nil,
                romaji: "hajimemashite",
                vietnameseMeaning: "Rất hân hạnh được gặp",
                exampleSentenceJp: "はじめまして、よろしくお願いします。",
                exampleSentenceVn: "Rất hân hạnh được gặp, mong được bạn chăm sóc."
            ),
            Word(
                id: 7,
                japaneseWord: "おやすみ",
                kanji: nil,
                romaji: "oyasumi",
                vietnameseMeaning: "Chúc ngủ ngon",
                exampleSentenceJp: "おやすみなさい。",
                exampleSentenceVn: "Chúc ngủ ngon."
            ),
            Word(
                id: 8,
                japaneseWord: "いただきます",
                kanji: nil,
                romaji: "itadakimasu",
                vietnameseMeaning: "Cảm ơn bữa ăn (trước khi ăn)",
                exampleSentenceJp: "いただきます。",
                exampleSentenceVn: "Cảm ơn bữa ăn."
            )
        ]
        currentWordIndex = 0
        isCardFlipped = false
        resetStatistics()
        print("✅ Sample data loaded: \(studyWords.count) words")
    }
    
    // MARK: - Card Interaction
    func flipCard() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isCardFlipped.toggle()
        }
    }
    
    func submitAnswer(difficulty: DifficultyLevel) async {
        guard let currentWord = currentWord else { return }
        
        print("📝 Submitting answer: \(difficulty.rawValue) for word: \(currentWord.japaneseWord)")
        
        // Update statistics
        updateStatistics(difficulty: difficulty)
        
        // Update SRS data
        await updateWordKnowledge(wordId: currentWord.id, difficulty: difficulty)
        
        // Move to next word or complete session
        if currentWordIndex + 1 >= studyWords.count {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingSessionComplete = true
            }
        } else {
            moveToNextWord()
        }
    }
    
    // MARK: - Navigation
    private func moveToNextWord() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentWordIndex += 1
            isCardFlipped = false
        }
    }
    
    func resetSession() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentWordIndex = 0
            isCardFlipped = false
            showingSessionComplete = false
            resetStatistics()
        }
    }
    
    func startNewSession() async {
        resetSession()
        await loadStudyWords()
    }
    
    // MARK: - Statistics
    private func updateStatistics(difficulty: DifficultyLevel) {
        totalAnswered += 1
        
        switch difficulty {
        case .easy:
            correctCount += 1
        case .normal:
            normalCount += 1
        case .hard:
            hardCount += 1
        }
        
        print("📊 Stats updated - Easy: \(correctCount), Normal: \(normalCount), Hard: \(hardCount)")
    }
    
    private func resetStatistics() {
        correctCount = 0
        normalCount = 0
        hardCount = 0
        totalAnswered = 0
    }
    
    // MARK: - SRS Integration
    private func updateWordKnowledge(wordId: Int, difficulty: DifficultyLevel) async {
        // Calculate next review date based on SRS algorithm
        let srsResult = srsManager.calculateNextReview(
            wordId: wordId,
            difficulty: difficulty
        )
        
        // Save to local storage first (for offline support)
        let lastReviewKey = "last_review_\(wordId)"
        let intervalKey = "review_interval_\(wordId)"
        let knowledgeLevelKey = "knowledge_level_\(wordId)"
        let easeFactorKey = "ease_factor_\(wordId)"
        
        UserDefaults.standard.set(Date(), forKey: lastReviewKey)
        UserDefaults.standard.set(srsResult.nextInterval, forKey: intervalKey)
        UserDefaults.standard.set(srsResult.newKnowledgeLevel, forKey: knowledgeLevelKey)
        UserDefaults.standard.set(srsResult.newEaseFactor, forKey: easeFactorKey)
        
        // Update database via API (if online)
        do {
            try await apiService.updateWordKnowledge(
                wordId: wordId,
                knowledgeLevel: srsResult.newKnowledgeLevel,
                easeFactor: srsResult.newEaseFactor,
                intervalDays: Int(srsResult.nextInterval / 86400), // Convert seconds to days
                nextReviewDate: Date().addingTimeInterval(srsResult.nextInterval)
            )
            print("✅ Updated word knowledge for word ID: \(wordId)")
        } catch {
            print("⚠️ Failed to update word knowledge on server (saved locally): \(error)")
            // Data is still saved locally, so the app can continue working
        }
    }
    
    // MARK: - Category Management
    func selectCategory(_ category: Category) {
        selectedCategory = category
        selectedCategoryId = category.id
        isPickingCategory = false
        Task { await loadStudyWords() }
    }
    
    // MARK: - Session Management
    func getSessionSummary() -> StudySessionSummary {
        return StudySessionSummary(
            totalWords: studyWords.count,
            correctAnswers: correctCount,
            normalAnswers: normalCount,
            hardAnswers: hardCount,
            accuracy: totalAnswered > 0 ? Double(correctCount) / Double(totalAnswered) * 100 : 0
        )
    }
    
    // MARK: - Word Management
    func skipCurrentWord() {
        guard currentWordIndex < studyWords.count else { return }
        
        print("⏭️ Skipping word: \(currentWord?.japaneseWord ?? "unknown")")
        
        if currentWordIndex + 1 >= studyWords.count {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingSessionComplete = true
            }
        } else {
            moveToNextWord()
        }
    }
    
    func markWordAsFavorite(_ wordId: Int) {
        let favoritesKey = "favorite_words"
        var favorites = UserDefaults.standard.array(forKey: favoritesKey) as? [Int] ?? []
        
        if !favorites.contains(wordId) {
            favorites.append(wordId)
            UserDefaults.standard.set(favorites, forKey: favoritesKey)
            print("⭐ Added word \(wordId) to favorites")
        }
    }
    
    func removeWordFromFavorites(_ wordId: Int) {
        let favoritesKey = "favorite_words"
        var favorites = UserDefaults.standard.array(forKey: favoritesKey) as? [Int] ?? []
        
        if let index = favorites.firstIndex(of: wordId) {
            favorites.remove(at: index)
            UserDefaults.standard.set(favorites, forKey: favoritesKey)
            print("❌ Removed word \(wordId) from favorites")
        }
    }
    
    func isWordFavorite(_ wordId: Int) -> Bool {
        let favoritesKey = "favorite_words"
        let favorites = UserDefaults.standard.array(forKey: favoritesKey) as? [Int] ?? []
        return favorites.contains(wordId)
    }
}

// MARK: - Supporting Models
enum DifficultyLevel: String, CaseIterable {
    case easy = "easy"
    case normal = "normal"
    case hard = "hard"
    
    var displayName: String {
        switch self {
        case .easy: return "Dễ"
        case .normal: return "Bình thường"
        case .hard: return "Khó"
        }
    }
    
    var emoji: String {
        switch self {
        case .easy: return "😊"
        case .normal: return "🤔"
        case .hard: return "😰"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .normal: return .orange
        case .hard: return .red
        }
    }
    
    var nextReviewMultiplier: Double {
        switch self {
        case .easy: return 2.5  // Easy: longer interval
        case .normal: return 1.3 // Normal: moderate interval
        case .hard: return 0.8   // Hard: shorter interval
        }
    }
}

struct StudySessionSummary {
    let totalWords: Int
    let correctAnswers: Int
    let normalAnswers: Int
    let hardAnswers: Int
    let accuracy: Double
    
    var totalAnswered: Int {
        return correctAnswers + normalAnswers + hardAnswers
    }
    
    var scorePercentage: Double {
        guard totalAnswered > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalAnswered) * 100
    }
    
    var grade: String {
        switch scorePercentage {
        case 90...100: return "Xuất sắc! 🌟"
        case 80..<90: return "Tốt! 👏"
        case 70..<80: return "Khá! 👍"
        case 60..<70: return "Trung bình 😐"
        default: return "Cần cố gắng thêm 💪"
        }
    }
}

// MARK: - Enhanced SRS Manager
class SRSManager {
    static let shared = SRSManager()
    private init() {}
    
    func calculateNextReview(wordId: Int, difficulty: DifficultyLevel) -> SRSResult {
        // Get current word knowledge data
        let knowledgeLevelKey = "knowledge_level_\(wordId)"
        let easeFactorKey = "ease_factor_\(wordId)"
        let consecutiveCorrectKey = "consecutive_correct_\(wordId)"
        let totalReviewsKey = "total_reviews_\(wordId)"
        let correctReviewsKey = "correct_reviews_\(wordId)"
        
        let currentLevel = UserDefaults.standard.integer(forKey: knowledgeLevelKey)
        let currentEaseFactor = UserDefaults.standard.double(forKey: easeFactorKey)
        let consecutiveCorrect = UserDefaults.standard.integer(forKey: consecutiveCorrectKey)
        let totalReviews = UserDefaults.standard.integer(forKey: totalReviewsKey)
        let correctReviews = UserDefaults.standard.integer(forKey: correctReviewsKey)
        
        // Initialize default values for new words
        let easeFactor = currentEaseFactor > 0 ? currentEaseFactor : 2.5
        
        var newKnowledgeLevel = currentLevel
        var newEaseFactor = easeFactor
        var newConsecutiveCorrect = consecutiveCorrect
        let newTotalReviews = totalReviews + 1
        var newCorrectReviews = correctReviews
        
        // Update based on difficulty
        switch difficulty {
        case .easy:
            newKnowledgeLevel = min(currentLevel + 2, 10)
            newEaseFactor = min(easeFactor + 0.15, 4.0)
            newConsecutiveCorrect = consecutiveCorrect + 1
            newCorrectReviews = correctReviews + 1
            
        case .normal:
            newKnowledgeLevel = min(currentLevel + 1, 10)
            newEaseFactor = easeFactor // No change
            newConsecutiveCorrect = consecutiveCorrect + 1
            newCorrectReviews = correctReviews + 1
            
        case .hard:
            newKnowledgeLevel = max(currentLevel - 1, 0)
            newEaseFactor = max(easeFactor - 0.2, 1.3)
            newConsecutiveCorrect = 0 // Reset streak
            // Don't increment correct reviews for hard answers
        }
        
        // Calculate next interval based on enhanced SM-2 algorithm
        let nextInterval = calculateInterval(
            knowledgeLevel: newKnowledgeLevel,
            easeFactor: newEaseFactor,
            consecutiveCorrect: newConsecutiveCorrect
        )
        
        // Save all data
        UserDefaults.standard.set(newConsecutiveCorrect, forKey: consecutiveCorrectKey)
        UserDefaults.standard.set(newTotalReviews, forKey: totalReviewsKey)
        UserDefaults.standard.set(newCorrectReviews, forKey: correctReviewsKey)
        
        print("📊 SRS Updated for word \(wordId):")
        print("   Level: \(currentLevel) → \(newKnowledgeLevel)")
        print("   Ease: \(String(format: "%.2f", easeFactor)) → \(String(format: "%.2f", newEaseFactor))")
        print("   Next: \(formatInterval(nextInterval))")
        
        return SRSResult(
            newKnowledgeLevel: newKnowledgeLevel,
            newEaseFactor: newEaseFactor,
            nextInterval: nextInterval,
            consecutiveCorrect: newConsecutiveCorrect
        )
    }
    
    private func calculateInterval(knowledgeLevel: Int, easeFactor: Double, consecutiveCorrect: Int) -> TimeInterval {
        let baseIntervals: [TimeInterval] = [
            0,          // Level 0: Review immediately
            60,         // Level 1: 1 minute
            300,        // Level 2: 5 minutes
            1800,       // Level 3: 30 minutes
            7200,       // Level 4: 2 hours
            86400,      // Level 5: 1 day
            259200,     // Level 6: 3 days
            604800,     // Level 7: 1 week
            1209600,    // Level 8: 2 weeks
            2592000,    // Level 9: 1 month
            7776000     // Level 10: 3 months
        ]
        
        guard knowledgeLevel < baseIntervals.count else {
            return baseIntervals.last! * easeFactor
        }
        
        let baseInterval = baseIntervals[knowledgeLevel]
        
        // Apply ease factor for higher levels
        if knowledgeLevel >= 5 {
            return baseInterval * easeFactor
        }
        
        return baseInterval
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        
        if days > 0 {
            return "\(days) ngày"
        } else if hours > 0 {
            return "\(hours) giờ"
        } else if minutes > 0 {
            return "\(minutes) phút"
        } else {
            return "ngay lập tức"
        }
    }
    
    // MARK: - Word Statistics
    func getWordStatistics(wordId: Int) -> WordStatistics {
        let knowledgeLevelKey = "knowledge_level_\(wordId)"
        let totalReviewsKey = "total_reviews_\(wordId)"
        let correctReviewsKey = "correct_reviews_\(wordId)"
        let consecutiveCorrectKey = "consecutive_correct_\(wordId)"
        let lastReviewKey = "last_review_\(wordId)"
        
        let knowledgeLevel = UserDefaults.standard.integer(forKey: knowledgeLevelKey)
        let totalReviews = UserDefaults.standard.integer(forKey: totalReviewsKey)
        let correctReviews = UserDefaults.standard.integer(forKey: correctReviewsKey)
        let consecutiveCorrect = UserDefaults.standard.integer(forKey: consecutiveCorrectKey)
        let lastReview = UserDefaults.standard.object(forKey: lastReviewKey) as? Date
        
        return WordStatistics(
            knowledgeLevel: knowledgeLevel,
            totalReviews: totalReviews,
            correctReviews: correctReviews,
            consecutiveCorrect: consecutiveCorrect,
            lastReview: lastReview
        )
    }
}

struct SRSResult {
    let newKnowledgeLevel: Int
    let newEaseFactor: Double
    let nextInterval: TimeInterval
    let consecutiveCorrect: Int
}

struct WordStatistics {
    let knowledgeLevel: Int
    let totalReviews: Int
    let correctReviews: Int
    let consecutiveCorrect: Int
    let lastReview: Date?
    
    var accuracy: Double {
        guard totalReviews > 0 else { return 0 }
        return Double(correctReviews) / Double(totalReviews) * 100
    }
    
    var masteryLevel: String {
        switch knowledgeLevel {
        case 0: return "Mới"
        case 1...3: return "Đang học"
        case 4...6: return "Quen thuộc"
        case 7...8: return "Thành thạo"
        case 9...10: return "Chuyên gia"
        default: return "Không xác định"
        }
    }
}
