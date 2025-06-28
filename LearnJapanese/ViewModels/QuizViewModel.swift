//
//  QuizViewModel.swift
//  LearnJapanese
//
//  Created by Trung Hiếu on 2025/06/15.
//

import Foundation
import SwiftUI

// MARK: - 🎯 Enum Độ Khó Quiz
enum QuizDifficulty: String, CaseIterable {
    case easy = "Dễ"
    case medium = "Trung bình"
    case hard = "Khó"

    /// Thời gian giới hạn cho mỗi câu hỏi (giây)
    var timeLimit: Int {
        switch self {
        case .easy: return 20
        case .medium: return 15
        case .hard: return 10
        }
    }
    
    /// Mô tả chi tiết độ khó
    var description: String {
        return "\(timeLimit) giây/câu"
    }
}

// MARK: - 🎮 QuizViewModel - Quản lý logic quiz
@MainActor
class QuizViewModel: ObservableObject {
    
    // MARK: - 📊 Published Properties - UI State
    @Published var quizQuestions: [QuizQuestion] = []          // Danh sách câu hỏi
    @Published var currentQuestionIndex = 0                    // Câu hỏi hiện tại
    @Published var selectedAnswer: String? = nil               // Đáp án được chọn
    @Published var showAnswer = false                          // Hiển thị kết quả
    @Published var isLoading = false                           // Trạng thái loading
    @Published var errorMessage = ""                           // Thông báo lỗi
    
    // MARK: - 🎪 Quiz Session State
    @Published var quizSession: QuizSession? = nil
    @Published var showingQuizComplete = false                 // Hiển thị màn hình hoàn thành
    @Published var showingCategorySelection = true             // Hiển thị chọn chủ đề
    
    // MARK: - ⚙️ Quiz Settings
    @Published var selectedCategory: Category? = nil          // Chủ đề được chọn
    @Published var selectedLevel: JLPTLevel? = nil            // Level JLPT được chọn
    @Published var categories: [Category] = []                // Danh sách chủ đề
    @Published var quizMode: QuizMode = .multiple_choice      // Chế độ quiz
    @Published var numberOfQuestions = 10                     // Số câu hỏi
    @Published var quizDifficulty: QuizDifficulty = .easy     // Độ khó
    
    // MARK: - ⏰ Timer Settings
    @Published var timeRemaining: Int = 20                    // Thời gian còn lại
    @Published var showTimer: Bool = true                     // Hiển thị timer
    @Published var autoNextQuestion: Bool = false             // Tự động chuyển câu
    @Published var autoNextDelay: Double = 1.5                // Delay trước khi chuyển câu
    
    // MARK: - 📈 Statistics
    @Published var correctAnswers = 0                         // Số câu đúng
    @Published var incorrectAnswers = 0                       // Số câu sai
    @Published var totalAnswered = 0                          // Tổng số câu đã trả lời
    @Published var totalTime: TimeInterval = 0               // Tổng thời gian
    @Published var questionStartTime = Date()                 // Thời gian bắt đầu câu hỏi
    @Published var userAnswers: [QuizUserAnswer] = []         // Lịch sử trả lời
    
    // MARK: - 🔧 Private Properties
    private var questionTimer: Timer?                         // Timer cho câu hỏi
    private var autoNextTimer: Timer?                         // Timer tự động chuyển câu
    private let apiService = APIService.shared               // Service gọi API
    private var sessionStartTime = Date()                    // Thời gian bắt đầu session
    
    // MARK: - 🧮 Computed Properties
    
    /// Câu hỏi hiện tại
    var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < quizQuestions.count else { return nil }
        return quizQuestions[currentQuestionIndex]
    }
    
    /// Phần trăm tiến độ
    var progressPercentage: Double {
        guard !quizQuestions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(quizQuestions.count) * 100
    }
    
    /// Kiểm tra quiz đã hoàn thành chưa
    var isQuizComplete: Bool {
        return currentQuestionIndex >= quizQuestions.count
    }
    
    /// Độ chính xác (%)
    var accuracy: Double {
        let total = correctAnswers + incorrectAnswers
        guard total > 0 else { return 0 }
        return Double(correctAnswers) / Double(total) * 100
    }
    
    // MARK: - 🏗️ Initialization
    init() {
        loadCategories()
        loadAutoNextSettings()
    }
    
    // MARK: - ⚙️ Auto Next Settings Management
    
    /// Bật/tắt tự động chuyển câu
    func setAutoNext(_ enabled: Bool) {
        autoNextQuestion = enabled
        UserDefaults.standard.set(enabled, forKey: "quiz_auto_next_enabled")
        print("🔄 Auto next câu hỏi: \(enabled ? "BẬT" : "TẮT")")
    }

    /// Thiết lập thời gian delay cho auto next
    func setAutoNextDelay(_ delay: Double) {
        autoNextDelay = delay
        UserDefaults.standard.set(delay, forKey: "quiz_auto_next_delay")
        print("⏱️ Auto next delay: \(delay)s")
    }

    /// Load settings auto next từ UserDefaults
    private func loadAutoNextSettings() {
        autoNextQuestion = UserDefaults.standard.bool(forKey: "quiz_auto_next_enabled")
        autoNextDelay = UserDefaults.standard.double(forKey: "quiz_auto_next_delay") > 0
            ? UserDefaults.standard.double(forKey: "quiz_auto_next_delay")
            : 1.5
    }
    
    // MARK: - ⏰ Timer Management
    
    /// Bắt đầu timer cho câu hỏi
    func startQuestionTimer() {
        guard showTimer else { return }
        
        // Reset timer với thời gian theo độ khó
        timeRemaining = quizDifficulty.timeLimit
        
        // Hủy timer cũ nếu có
        stopQuestionTimer()
        
        // Tạo timer mới
        questionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    // Hết thời gian - tự động chuyển câu
                    self.handleTimeOut()
                }
            }
        }
    }

    /// Dừng timer câu hỏi
    func stopQuestionTimer() {
        questionTimer?.invalidate()
        questionTimer = nil
    }

    /// Xử lý khi hết thời gian
    private func handleTimeOut() {
        stopQuestionTimer()
        
        // Tự động chọn câu trả lời sai (chọn đáp án đầu tiên nếu chưa chọn)
        if selectedAnswer == nil, let firstOption = currentQuestion?.options.first {
            selectedAnswer = firstOption
        }
        
        showAnswer = true
        incorrectAnswers += 1
        totalAnswered += 1
        
        // Lưu user answer
        if let question = currentQuestion {
            let userAnswer = QuizUserAnswer(
                questionId: question.id,
                userAnswer: selectedAnswer ?? "",
                correctAnswer: question.correctAnswer,
                isCorrect: false, // Timeout = sai
                timeSpent: Double(quizDifficulty.timeLimit) // Hết thời gian
            )
            userAnswers.append(userAnswer)
        }
        
        // Auto next nếu được bật
        if autoNextQuestion {
            startAutoNextTimer()
        }
    }

    // MARK: - 🎯 Answer Handling
    
    /// Xử lý khi user chọn đáp án
    func selectAnswer(_ answer: String) {
        // Dừng timer khi user chọn đáp án
        stopQuestionTimer()
        
        selectedAnswer = answer
        showAnswer = true
        
        let questionTime = Date().timeIntervalSince(questionStartTime)
        let isCorrect = answer == currentQuestion?.correctAnswer
        
        // Cập nhật thống kê
        if isCorrect {
            correctAnswers += 1
        } else {
            incorrectAnswers += 1
        }
        
        totalAnswered += 1
        
        // Ghi lại câu trả lời
        if let question = currentQuestion {
            let userAnswer = QuizUserAnswer(
                questionId: question.id,
                userAnswer: answer,
                correctAnswer: question.correctAnswer,
                isCorrect: isCorrect,
                timeSpent: questionTime
            )
            userAnswers.append(userAnswer)
        }
        
        totalTime += questionTime
        
        print("📝 Answer selected: \(answer), Correct: \(isCorrect), Time: \(String(format: "%.1f", questionTime))s")
        
        // Auto next logic
        if autoNextQuestion {
            startAutoNextTimer()
        }
    }

    // MARK: - 🔄 Auto Next Timer Management
    
    /// Bắt đầu timer tự động chuyển câu
    private func startAutoNextTimer() {
        // Hủy timer cũ nếu có
        stopAutoNextTimer()
        
        // Tạo timer mới với delay
        autoNextTimer = Timer.scheduledTimer(withTimeInterval: autoNextDelay, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.moveToNextQuestionAutomatically()
            }
        }
        
        print("⏰ Auto next timer started: \(autoNextDelay)s")
    }

    /// Dừng timer tự động chuyển câu
    private func stopAutoNextTimer() {
        autoNextTimer?.invalidate()
        autoNextTimer = nil
    }

    /// Di chuyển đến câu tiếp theo tự động
    private func moveToNextQuestionAutomatically() {
        stopAutoNextTimer()
        
        if currentQuestionIndex + 1 >= quizQuestions.count {
            completeQuiz()
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentQuestionIndex += 1
                selectedAnswer = nil
                showAnswer = false
                questionStartTime = Date()
                
                startQuestionTimer()
            }
        }
        
        print("🔄 Auto moved to next question")
    }

    /// Chuyển câu tiếp theo thủ công
    func nextQuestion() {
        stopQuestionTimer()
        stopAutoNextTimer() // Dừng auto timer khi bấm manual
        
        if currentQuestionIndex + 1 >= quizQuestions.count {
            completeQuiz()
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentQuestionIndex += 1
                selectedAnswer = nil
                showAnswer = false
                questionStartTime = Date()
                
                startQuestionTimer()
            }
        }
    }
    
    // MARK: - 📂 Category Management
    
    /// Load danh sách categories từ API
    func loadCategories() {
        Task {
            do {
                categories = try await apiService.getCategories()
                print("✅ Loaded \(categories.count) categories for quiz")
            } catch {
                print("❌ Error loading categories: \(error)")
                // Load sample categories nếu API fail
                loadSampleCategories()
            }
        }
    }
    
    /// Load sample categories cho testing
    private func loadSampleCategories() {
        categories = [
            Category(
                id: 1, name: "Cơ bản", nameEn: "Basic", icon: "🌱", color: "#56ab2f",
                description: "Từ vựng cơ bản", difficultyLevel: 1, estimatedHours: 2.0,
                totalWords: 25, learnedWords: 15, masteredWords: 8, completionPercentage: 60.0,
                quizBestScore: 85, quizAttempts: 3, totalStudyTime: 1800, isCompleted: false,
                isUnlocked: true, lastStudiedAt: nil, unlockCondition: nil
            ),
            Category(
                id: 2, name: "Gia đình", nameEn: "Family", icon: "👨‍👩‍👧‍👦", color: "#ff6b6b",
                description: "Thành viên gia đình", difficultyLevel: 1, estimatedHours: 3.0,
                totalWords: 20, learnedWords: 12, masteredWords: 5, completionPercentage: 40.0,
                quizBestScore: 92, quizAttempts: 2, totalStudyTime: 1200, isCompleted: false,
                isUnlocked: true, lastStudiedAt: nil, unlockCondition: nil
            )
        ]
    }
    
    /// Chọn category và level để bắt đầu quiz
    func selectCategoryAndLevel(category: Category, level: JLPTLevel) {
        selectedCategory = category
        selectedLevel = level
        showingCategorySelection = false
        
        Task {
            await loadQuizQuestions()
        }
    }
    
    // MARK: - 📚 Quiz Data Loading
    
    /// Load câu hỏi quiz từ API hoặc generate từ vocabulary
    func loadQuizQuestions() async {
        guard let category = selectedCategory else {
            print("❌ Không có category được chọn")
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            print("🔄 Loading quiz questions for category: \(category.name)")
            
            // Thử lấy câu hỏi từ API trước
            let questions = try await apiService.getQuizQuestions(
                categoryId: category.id,
                questionCount: numberOfQuestions,
                quizMode: quizMode
            )
            
            if questions.isEmpty {
                print("⚠️ Không có câu hỏi từ API, generating từ vocabulary")
                await generateQuestionsFromVocabulary(categoryId: category.id)
            } else {
                quizQuestions = questions
                print("✅ Loaded \(questions.count) quiz questions từ API")
            }
            
            // Khởi tạo quiz session
            initializeQuizSession()
            
        } catch {
            print("❌ Error loading quiz questions: \(error)")
            // Fallback sang generate từ vocabulary
            await generateQuestionsFromVocabulary(categoryId: category.id)
        }
        
        isLoading = false
    }
    
    /// Generate câu hỏi từ vocabulary words
    private func generateQuestionsFromVocabulary(categoryId: Int) async {
        do {
            let words = try await apiService.getStudyWords(categoryId: categoryId)
            print("📚 Generating quiz từ \(words.count) vocabulary words")
            
            if words.isEmpty {
                print("⚠️ Không có words, dùng sample questions")
                generateSampleQuestions()
            } else {
                quizQuestions = generateMultipleChoiceQuestions(from: words)
                print("✅ Generated \(quizQuestions.count) quiz questions")
            }
            
        } catch {
            print("❌ Failed to get vocabulary words, dùng sample questions")
            generateSampleQuestions()
        }
    }
    
    /// Generate multiple choice questions từ danh sách words
    private func generateMultipleChoiceQuestions(from words: [Word]) -> [QuizQuestion] {
        guard !words.isEmpty else {
            print("❌ Không thể generate questions: words array rỗng")
            return []
        }
        
        let shuffledWords = words.shuffled()
        let questionCount = min(numberOfQuestions, words.count)
        var questions: [QuizQuestion] = []
        
        print("📊 Sẽ tạo \(questionCount) câu hỏi từ \(words.count) từ có sẵn")
        
        for i in 0..<questionCount {
            let correctWord = shuffledWords[i]
            
            // Tạo các đáp án sai từ những từ khác
            let otherWords = shuffledWords.filter { $0.id != correctWord.id }
            let wrongAnswers = Array(otherWords.shuffled().prefix(3))
            
            // Tạo danh sách options
            var options = wrongAnswers.map { $0.vietnameseMeaning }
            options.append(correctWord.vietnameseMeaning)
            options.shuffle()
            
            let question = QuizQuestion(
                id: i + 1,
                questionText: correctWord.japaneseWord,
                questionType: .multiple_choice,
                options: options,
                correctAnswer: correctWord.vietnameseMeaning,
                explanation: correctWord.exampleSentenceVn,
                wordId: correctWord.id,
                romaji: correctWord.romaji,
                kanji: correctWord.kanji
            )
            
            questions.append(question)
        }
        
        return questions
    }
    
    /// Generate sample questions cho testing
    private func generateSampleQuestions() {
        print("🧪 Generating sample quiz questions")
        quizQuestions = [
            QuizQuestion(
                id: 1,
                questionText: "おはよう",
                questionType: .multiple_choice,
                options: ["Chào buổi sáng", "Cảm ơn", "Xin lỗi", "Tạm biệt"],
                correctAnswer: "Chào buổi sáng",
                explanation: "おはよう được dùng để chào buổi sáng",
                wordId: 1,
                romaji: "ohayou",
                kanji: nil
            ),
            QuizQuestion(
                id: 2,
                questionText: "ありがとう",
                questionType: .multiple_choice,
                options: ["Xin lỗi", "Cảm ơn", "Chào buổi sáng", "Tạm biệt"],
                correctAnswer: "Cảm ơn",
                explanation: "ありがとう có nghĩa là cảm ơn",
                wordId: 2,
                romaji: "arigatou",
                kanji: nil
            ),
            QuizQuestion(
                id: 3,
                questionText: "すみません",
                questionType: .multiple_choice,
                options: ["Cảm ơn", "Tạm biệt", "Xin lỗi", "Chào buổi sáng"],
                correctAnswer: "Xin lỗi",
                explanation: "すみません được dùng để xin lỗi",
                wordId: 3,
                romaji: "sumimasen",
                kanji: nil
            )
        ]
    }
    
    // MARK: - 🎮 Quiz Session Management
    
    /// Khởi tạo quiz session mới
    private func initializeQuizSession() {
        sessionStartTime = Date()
        questionStartTime = Date()
        
        // Reset tất cả statistics
        correctAnswers = 0
        incorrectAnswers = 0
        totalTime = 0
        totalAnswered = 0
        userAnswers = []
        currentQuestionIndex = 0
        selectedAnswer = nil
        showAnswer = false
        
        // Bắt đầu timer cho câu đầu tiên
        startQuestionTimer()
        
        // Tạo quiz session record
        quizSession = QuizSession(
            id: Int.random(in: 1000...9999),
            userId: UserDefaults.standard.integer(forKey: Constants.Storage.userId),
            quizType: selectedCategory?.name ?? "Unknown",
            totalQuestions: quizQuestions.count,
            correctAnswers: 0,
            timeSpent: 0,
            startedAt: sessionStartTime,
            completedAt: nil,
            isCompleted: false
        )
        
        print("🎯 Quiz session initialized với \(quizQuestions.count) questions")
    }
    
    // MARK: - 🏁 Quiz Completion
    
    /// Hoàn thành quiz
    private func completeQuiz() {
        // Dừng tất cả timers
        stopQuestionTimer()
        stopAutoNextTimer()
        
        let completionTime = Date()
        totalTime = completionTime.timeIntervalSince(sessionStartTime)
        
        // Cập nhật quiz session
        quizSession?.correctAnswers = correctAnswers
        quizSession?.timeSpent = Int(totalTime)
        quizSession?.completedAt = completionTime
        quizSession?.isCompleted = true
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingQuizComplete = true
        }
        
        // Lưu kết quả lên server
        Task {
            await saveQuizResults()
        }
        
        print("🎉 Quiz completed! Score: \(correctAnswers)/\(quizQuestions.count) (\(String(format: "%.1f", accuracy))%)")
    }
    
    /// Lưu kết quả quiz lên server
    private func saveQuizResults() async {
        guard let _ = quizSession,
               let category = selectedCategory else { return }
        
        do {
            try await apiService.saveQuizResult(
                categoryId: category.id,
                totalQuestions: quizQuestions.count,
                correctAnswers: correctAnswers,
                timeSpent: Int(totalTime),
                accuracy: accuracy
            )
            print("✅ Quiz results saved to server")
        } catch {
            print("⚠️ Failed to save quiz results: \(error)")
            // Backup: lưu local
            saveQuizResultsLocally()
        }
    }
    
    /// Backup: lưu kết quả quiz locally
    private func saveQuizResultsLocally() {
        let quizResult = [
            "category_id": selectedCategory?.id ?? 0,
            "total_questions": quizQuestions.count,
            "correct_answers": correctAnswers,
            "time_spent": Int(totalTime),
            "accuracy": accuracy,
            "completed_at": ISO8601DateFormatter().string(from: Date())
        ] as [String : Any]
        
        var savedResults = UserDefaults.standard.array(forKey: "saved_quiz_results") as? [[String: Any]] ?? []
        savedResults.append(quizResult)
        UserDefaults.standard.set(savedResults, forKey: "saved_quiz_results")
        
        print("💾 Quiz results saved locally")
    }
    
    // MARK: - 🔄 Quiz Control
    
    /// Reset quiz về trạng thái ban đầu
    func resetQuiz() {
        // Dừng tất cả timers
        stopQuestionTimer()
        stopAutoNextTimer()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentQuestionIndex = 0
            selectedAnswer = nil
            showAnswer = false
            showingQuizComplete = false
            correctAnswers = 0
            incorrectAnswers = 0
            totalAnswered = 0
            totalTime = 0
            userAnswers = []
            questionStartTime = Date()
            sessionStartTime = Date()
            
            quizQuestions = []
            timeRemaining = quizDifficulty.timeLimit
        }
        
        // Load lại auto next settings
        loadAutoNextSettings()
        
        print("🔄 Quiz đã được reset với settings:")
        print("   - Số câu: \(numberOfQuestions)")
        print("   - Độ khó: \(quizDifficulty.rawValue) (\(quizDifficulty.timeLimit)s)")
        print("   - Auto next: \(autoNextQuestion ? "BẬT" : "TẮT")")
    }
    
    /// Bắt đầu quiz mới
    func startNewQuiz() {
        showingCategorySelection = true
        resetQuiz()
    }
    
    /// Làm lại quiz hiện tại
    func restartCurrentQuiz() {
        resetQuiz()
        quizQuestions.shuffle() // Trộn câu hỏi cho đa dạng
        initializeQuizSession() // Khởi tạo lại session
    }
    
    // MARK: - 📊 Quiz Summary
    
    /// Lấy tóm tắt kết quả quiz
    func getQuizSummary() -> QuizSummary {
        let averageTimePerQuestion = userAnswers.isEmpty ? 0 : userAnswers.map { $0.timeSpent }.reduce(0, +) / Double(userAnswers.count)
        
        return QuizSummary(
            totalQuestions: quizQuestions.count,
            correctAnswers: correctAnswers,
            incorrectAnswers: incorrectAnswers,
            accuracy: accuracy,
            totalTime: totalTime,
            averageTimePerQuestion: averageTimePerQuestion,
            category: selectedCategory?.name ?? "Unknown",
            level: selectedLevel?.displayName ?? "Unknown",
            userAnswers: userAnswers
        )
    }
    
    // MARK: - 🧹 Cleanup
    deinit {
        questionTimer?.invalidate()
        autoNextTimer?.invalidate()
        print("🧹 QuizViewModel cleaned up")
    }
}

// MARK: - 📋 Supporting Models

/// Model cho câu hỏi quiz (dùng trong app)
struct QuizQuestion: Codable, Identifiable {
    let id: Int
    let questionText: String                    // Văn bản câu hỏi (tiếng Nhật)
    let questionType: QuizQuestionType          // Loại câu hỏi
    let options: [String]                       // Các lựa chọn
    let correctAnswer: String                   // Đáp án đúng
    let explanation: String?                    // Giải thích (optional)
    let wordId: Int?                           // ID của từ vựng (optional)
    let romaji: String?                        // Phiên âm romaji (optional)
    let kanji: String?                         // Chữ kanji (optional)
}

/// Enum loại câu hỏi
enum QuizQuestionType: String, Codable, CaseIterable {
    case multiple_choice = "multiple_choice"
    case true_false = "true_false"
    case fill_blank = "fill_blank"
    case listening = "listening"
    
    var displayName: String {
        switch self {
        case .multiple_choice: return "Trắc nghiệm"
        case .true_false: return "Đúng/Sai"
        case .fill_blank: return "Điền vào chỗ trống"
        case .listening: return "Nghe và chọn"
        }
    }
}

/// Enum chế độ quiz
enum QuizMode: String, CaseIterable {
    case multiple_choice = "multiple_choice"
    case mixed = "mixed"
    case review_mistakes = "review_mistakes"
    
    var displayName: String {
        switch self {
        case .multiple_choice: return "Trắc nghiệm"
        case .mixed: return "Hỗn hợp"
        case .review_mistakes: return "Ôn lỗi sai"
        }
    }
    
    var icon: String {
        switch self {
        case .multiple_choice: return "list.bullet.circle"
        case .mixed: return "shuffle.circle"
        case .review_mistakes: return "arrow.clockwise.circle"
        }
    }
}

/// Model cho quiz session
struct QuizSession: Codable {
    let id: Int
    let userId: Int
    let quizType: String
    let totalQuestions: Int
    var correctAnswers: Int
    var timeSpent: Int
    let startedAt: Date
    var completedAt: Date?
    var isCompleted: Bool
}

/// Model cho câu trả lời của user
struct QuizUserAnswer: Codable {
    let questionId: Int
    let userAnswer: String
    let correctAnswer: String
    let isCorrect: Bool
    let timeSpent: TimeInterval
}

/// Model tóm tắt kết quả quiz
struct QuizSummary {
    let totalQuestions: Int
    let correctAnswers: Int
    let incorrectAnswers: Int
    let accuracy: Double
    let totalTime: TimeInterval
    let averageTimePerQuestion: Double
    let category: String
    let level: String
    let userAnswers: [QuizUserAnswer]
    
    /// Đánh giá kết quả
    var grade: String {
        switch accuracy {
        case 90...100: return "Xuất sắc! 🌟"
        case 80..<90: return "Tốt! 👏"
        case 70..<80: return "Khá! 👍"
        case 60..<70: return "Trung bình 😐"
        default: return "Cần cố gắng thêm 💪"
        }
    }
    
    /// Màu sắc theo kết quả
    var scoreColor: Color {
        switch accuracy {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .orange
        case 60..<70: return .yellow
        default: return .red
        }
    }
}

// MARK: - 🌐 APIService Extensions cho Quiz

extension APIService {
    
    /// Lấy câu hỏi quiz từ API
    func getQuizQuestions(
        categoryId: Int,
        questionCount: Int = 10,
        quizMode: QuizMode = .multiple_choice
    ) async throws -> [QuizQuestion] {
        guard UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn) else {
            throw APIError.unauthorized
        }
        
        // Tạo URL với parameters
        var urlComponents = URLComponents(string: Constants.API.baseURL + Constants.API.Endpoints.vocabulary)!
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "get_quiz_questions"),
            URLQueryItem(name: "category_id", value: "\(categoryId)"),
            URLQueryItem(name: "question_count", value: "\(questionCount)"),
            URLQueryItem(name: "quiz_mode", value: quizMode.rawValue)
        ]
        
        // Thêm user_id
        if let userId = UserDefaults.standard.object(forKey: Constants.Storage.userId) as? Int {
            urlComponents.queryItems?.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Constants.API.timeout
        
        // Thêm auth header nếu có
        if let token = UserDefaults.standard.string(forKey: Constants.Storage.userToken), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("🌐 Quiz Questions API URL: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("📥 Quiz Questions HTTP Status: \(statusCode)")
            
            // Log response để debug
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Quiz Questions Response: \(responseString.prefix(500))...")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError
            }
            
            switch httpResponse.statusCode {
            case 200:
                let questionsResponse = try JSONDecoder().decode(QuizQuestionsResponse.self, from: data)
                
                if questionsResponse.success {
                    // Convert QuizQuestionFromAPI sang QuizQuestion
                    let apiQuestions = questionsResponse.data?.questions ?? []
                    let questions = apiQuestions.map { $0.toQuizQuestion() }
                    print("✅ Loaded \(questions.count) quiz questions từ API")
                    return questions
                } else {
                    let message = questionsResponse.message ?? "Unknown error"
                    print("❌ Quiz Questions API failed: \(message)")
                    return [] // Trả về array rỗng thay vì throw
                }
                
            case 401:
                await logout()
                throw APIError.unauthorized
                
            case 404:
                print("ℹ️ Không tìm thấy quiz questions cho category \(categoryId)")
                return [] // Trả về array rỗng cho 404
                
            default:
                throw APIError.serverError
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            print("🚨 Network error getting quiz questions: \(error)")
            return [] // Trả về array rỗng thay vì throw cho network errors
        }
    }
    
    /// Lưu kết quả quiz lên server
    func saveQuizResult(
        categoryId: Int,
        totalQuestions: Int,
        correctAnswers: Int,
        timeSpent: Int,
        accuracy: Double
    ) async throws {
        guard UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: Constants.API.baseURL + Constants.API.Endpoints.vocabulary)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.API.timeout
        
        // Thêm auth header
        if let token = UserDefaults.standard.string(forKey: Constants.Storage.userToken), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var parameters = [
            "action=save_quiz_result",
            "category_id=\(categoryId)",
            "total_questions=\(totalQuestions)",
            "correct_answers=\(correctAnswers)",
            "time_spent=\(timeSpent)",
            "accuracy=\(accuracy)"
        ]
        
        // Thêm user_id nếu có
        if let userId = UserDefaults.standard.object(forKey: Constants.Storage.userId) as? Int {
            parameters.append("user_id=\(userId)")
        }
        
        let parametersString = parameters.joined(separator: "&")
        request.httpBody = parametersString.data(using: .utf8)
        
        print("🌐 Save Quiz Result URL: \(url)")
        print("📤 Parameters: \(parametersString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("📥 Save Quiz Result Status: \(statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Save Quiz Response: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError
            }
            
            switch httpResponse.statusCode {
            case 200:
                let saveResponse = try JSONDecoder().decode(SaveQuizResultResponse.self, from: data)
                if saveResponse.success {
                    print("✅ Quiz result saved successfully")
                    
                    // Cập nhật best score local nếu tốt hơn
                    updateLocalBestScore(categoryId: categoryId, newScore: Int(accuracy))
                    
                } else {
                    let message = saveResponse.message ?? "Unknown error"
                    print("❌ Save quiz result failed: \(message)")
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
            print("🚨 Network error saving quiz result: \(error)")
            throw APIError.networkError
        }
    }
    
    /// Lấy lịch sử quiz
    func getQuizHistory(categoryId: Int? = nil, limit: Int = 20) async throws -> [QuizHistoryItem] {
        guard UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn) else {
            throw APIError.unauthorized
        }
        
        var urlComponents = URLComponents(string: Constants.API.baseURL + Constants.API.Endpoints.vocabulary)!
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "get_quiz_history"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        // Thêm filter category nếu có
        if let categoryId = categoryId {
            urlComponents.queryItems?.append(URLQueryItem(name: "category_id", value: "\(categoryId)"))
        }
        
        // Thêm user_id
        if let userId = UserDefaults.standard.object(forKey: Constants.Storage.userId) as? Int {
            urlComponents.queryItems?.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Constants.API.timeout
        
        // Thêm auth header
        if let token = UserDefaults.standard.string(forKey: Constants.Storage.userToken), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("🌐 Quiz History API URL: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("📥 Quiz History HTTP Status: \(statusCode)")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError
            }
            
            switch httpResponse.statusCode {
            case 200:
                let historyResponse = try JSONDecoder().decode(QuizHistoryResponse.self, from: data)
                
                if historyResponse.success {
                    let history = historyResponse.data ?? []
                    print("✅ Loaded \(history.count) quiz history items")
                    return history
                } else {
                    let message = historyResponse.message ?? "Unknown error"
                    print("❌ Quiz History API failed: \(message)")
                    return []
                }
                
            case 401:
                await logout()
                throw APIError.unauthorized
                
            case 404:
                print("ℹ️ Không tìm thấy quiz history")
                return []
                
            default:
                throw APIError.serverError
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            print("🚨 Network error getting quiz history: \(error)")
            return []
        }
    }
    
    /// Lấy thống kê quiz
    func getQuizStatistics() async throws -> QuizStatistics {
        guard UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn) else {
            throw APIError.unauthorized
        }
        
        var urlComponents = URLComponents(string: Constants.API.baseURL + Constants.API.Endpoints.vocabulary)!
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "get_quiz_statistics")
        ]
        
        // Thêm user_id
        if let userId = UserDefaults.standard.object(forKey: Constants.Storage.userId) as? Int {
            urlComponents.queryItems?.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Constants.API.timeout
        
        // Thêm auth header
        if let token = UserDefaults.standard.string(forKey: Constants.Storage.userToken), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("🌐 Quiz Statistics API URL: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("📥 Quiz Statistics HTTP Status: \(statusCode)")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError
            }
            
            switch httpResponse.statusCode {
            case 200:
                let statsResponse = try JSONDecoder().decode(QuizStatisticsResponse.self, from: data)
                
                if statsResponse.success, let stats = statsResponse.data {
                    print("✅ Loaded quiz statistics")
                    return stats
                } else {
                    let message = statsResponse.message ?? "Unknown error"
                    print("❌ Quiz Statistics API failed: \(message)")
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
            print("🚨 Network error getting quiz statistics: \(error)")
            throw APIError.networkError
        }
    }
    
    /// Cập nhật best score local
    private func updateLocalBestScore(categoryId: Int, newScore: Int) {
        let key = "quiz_best_score_\(categoryId)"
        let currentBest = UserDefaults.standard.integer(forKey: key)
        
        if newScore > currentBest {
            UserDefaults.standard.set(newScore, forKey: key)
            print("🏆 New best score cho category \(categoryId): \(newScore)%")
            
            // Post notification cho achievement
            NotificationCenter.default.post(
                name: NSNotification.Name("QuizNewBestScore"),
                object: nil,
                userInfo: ["categoryId": categoryId, "score": newScore]
            )
        }
    }
}

// MARK: - 📡 API Response Models

/// Response cho quiz questions API
struct QuizQuestionsResponse: Codable {
    let success: Bool
    let data: QuizQuestionsData?
    let message: String?
}

/// Data wrapper chứa session_id và questions
struct QuizQuestionsData: Codable {
    let sessionId: Int
    let questions: [QuizQuestionFromAPI]  // Questions từ API format
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case questions
    }
}

/// Model cho quiz question từ API (format khác với QuizQuestion)
struct QuizQuestionFromAPI: Codable, Identifiable {
    let id: Int
    let type: String?                    // "meaning", "reading", etc.
    let question: String                 // Japanese word
    let questionKanji: String?           // Kanji version
    let correctAnswer: String            // Vietnamese meaning
    let questionType: String?            // "jp_to_vn", "vn_to_jp", etc.
    let options: [String]
    let wordData: QuizWordData?          // Additional word info
    
    enum CodingKeys: String, CodingKey {
        case id, type, question, options
        case questionKanji = "question_kanji"
        case correctAnswer = "correct_answer"
        case questionType = "question_type"
        case wordData = "word_data"
    }
    
    /// Convert sang QuizQuestion format để dùng trong app
    func toQuizQuestion() -> QuizQuestion {
        return QuizQuestion(
            id: self.id,
            questionText: self.question,
            questionType: .multiple_choice,  // Default
            options: self.options,
            correctAnswer: self.correctAnswer,
            explanation: self.wordData?.exampleVn,
            wordId: nil,
            romaji: self.wordData?.romaji,
            kanji: self.questionKanji
        )
    }
}

/// Model cho word data trong API response
struct QuizWordData: Codable {
    let romaji: String?
    let wordType: String?
    let exampleJp: String?
    let exampleVn: String?
    let usageNote: String?
    
    enum CodingKeys: String, CodingKey {
        case romaji
        case wordType = "word_type"
        case exampleJp = "example_jp"
        case exampleVn = "example_vn"
        case usageNote = "usage_note"
    }
}

/// Response cho save quiz result API
struct SaveQuizResultResponse: Codable {
    let success: Bool
    let message: String?
    let data: QuizResultData?
}

/// Data cho quiz result
struct QuizResultData: Codable {
    let quizId: Int
    let newBestScore: Bool
    let categoryProgress: Double?
    
    enum CodingKeys: String, CodingKey {
        case quizId = "quiz_id"
        case newBestScore = "new_best_score"
        case categoryProgress = "category_progress"
    }
}

/// Response cho quiz history API
struct QuizHistoryResponse: Codable {
    let success: Bool
    let data: [QuizHistoryItem]?
    let message: String?
}

/// Model cho quiz history item
struct QuizHistoryItem: Codable, Identifiable {
    let id: Int
    let categoryId: Int
    let categoryName: String
    let totalQuestions: Int
    let correctAnswers: Int
    let accuracy: Double
    let timeSpent: Int
    let completedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case categoryName = "category_name"
        case totalQuestions = "total_questions"
        case correctAnswers = "correct_answers"
        case accuracy
        case timeSpent = "time_spent"
        case completedAt = "completed_at"
    }
    
    /// Format thời gian theo mm:ss
    var formattedTime: String {
        let minutes = timeSpent / 60
        let seconds = timeSpent % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Format ngày tháng
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = formatter.date(from: completedAt) {
            formatter.dateFormat = "dd/MM/yyyy HH:mm"
            return formatter.string(from: date)
        }
        return completedAt
    }
    
    /// Emoji theo kết quả
    var gradeEmoji: String {
        switch accuracy {
        case 90...100: return "🌟"
        case 80..<90: return "👏"
        case 70..<80: return "👍"
        case 60..<70: return "😐"
        default: return "💪"
        }
    }
}

/// Response cho quiz statistics API
struct QuizStatisticsResponse: Codable {
    let success: Bool
    let data: QuizStatistics?
    let message: String?
}

/// Model cho quiz statistics
struct QuizStatistics: Codable {
    let totalQuizzes: Int
    let totalQuestions: Int
    let correctAnswers: Int
    let averageAccuracy: Double
    let totalTimeSpent: Int
    let bestCategory: String?
    let worstCategory: String?
    let currentStreak: Int
    let longestStreak: Int
    let categoriesCompleted: Int
    let averageTimePerQuestion: Double
    
    enum CodingKeys: String, CodingKey {
        case totalQuizzes = "total_quizzes"
        case totalQuestions = "total_questions"
        case correctAnswers = "correct_answers"
        case averageAccuracy = "average_accuracy"
        case totalTimeSpent = "total_time_spent"
        case bestCategory = "best_category"
        case worstCategory = "worst_category"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case categoriesCompleted = "categories_completed"
        case averageTimePerQuestion = "average_time_per_question"
    }
    
    /// Format tổng thời gian thành h:mm
    var formattedTotalTime: String {
        let hours = totalTimeSpent / 3600
        let minutes = (totalTimeSpent % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Đánh giá performance level
    var performanceLevel: String {
        switch averageAccuracy {
        case 90...100: return "Xuất sắc"
        case 80..<90: return "Tốt"
        case 70..<80: return "Khá"
        case 60..<70: return "Trung bình"
        default: return "Cần cải thiện"
        }
    }
    
    /// Màu sắc theo performance
    var performanceColor: Color {
        switch averageAccuracy {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .orange
        case 60..<70: return .yellow
        default: return .red
        }
    }
}
