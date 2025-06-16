////
////  QuizViewModel+Audio.swift
////  LearnJapanese
////
////  Created by Trung Hiếu on 2025/06/15.
////
//
//// ViewModels/QuizViewModel+Audio.swift
//import Foundation
//import SwiftUI
//
//extension QuizViewModel {
//    
//    // ✅ THÊM: Timer-related properties cho âm thanh
//    @Published var showTimer = true
//    @Published var timeRemaining = 30
//    @Published var autoNextQuestion = false
//    @Published var autoNextDelay: TimeInterval = 2.0
//    @Published var quizDifficulty = QuizDifficulty.medium
//    
//    private var timer: Timer?
//    private var autoNextTimer: Timer?
//    
//    // MARK: - Audio-Enhanced Answer Selection
//    func selectAnswerWithSound(_ answer: String) {
//        // Stop timer tick sound
//        stopTimerTickSound()
//        
//        // Play button tap sound first
//        playButtonTapSound()
//        
//        // Original select answer logic
//        selectedAnswer = answer
//        showAnswer = true
//        
//        let questionTime = Date().timeIntervalSince(questionStartTime)
//        let isCorrect = answer == currentQuestion?.correctAnswer
//        
//        // Play correct/incorrect sound với delay nhỏ
//        playAnswerSound(isCorrect: isCorrect)
//        
//        // Update statistics
//        if isCorrect {
//            correctAnswers += 1
//        } else {
//            incorrectAnswers += 1
//        }
//        
//        // Record user answer
//        if let question = currentQuestion {
//            let userAnswer = QuizUserAnswer(
//                questionId: question.id,
//                userAnswer: answer,
//                correctAnswer: question.correctAnswer,
//                isCorrect: isCorrect,
//                timeSpent: questionTime
//            )
//            userAnswers.append(userAnswer)
//        }
//        
//        totalTime += questionTime
//        
//        // Stop question timer
//        stopQuestionTimer()
//        
//        // Auto next logic với âm thanh
//        if autoNextQuestion {
//            startAutoNextTimer()
//        }
//        
//        print("📝 Answer selected: \(answer), Correct: \(isCorrect), Time: \(String(format: "%.1f", questionTime))s")
//    }
//    
//    // MARK: - Enhanced Next Question với âm thanh
//    func nextQuestionWithSound() {
//        playButtonTapSound()
//        
//        // Stop any running timers
//        stopAutoNextTimer()
//        stopTimerTickSound()
//        
//        if currentQuestionIndex + 1 >= quizQuestions.count {
//            completeQuizWithSound()
//        } else {
//            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
//                currentQuestionIndex += 1
//                selectedAnswer = nil
//                showAnswer = false
//                questionStartTime = Date()
//                
//                // Start new question timer
//                startQuestionTimer()
//            }
//        }
//    }
//    
//    // MARK: - Quiz Completion với âm thanh
//    private func completeQuizWithSound() {
//        let completionTime = Date()
//        totalTime = completionTime.timeIntervalSince(sessionStartTime)
//        
//        // Update quiz session
//        quizSession?.correctAnswers = correctAnswers
//        quizSession?.timeSpent = Int(totalTime)
//        quizSession?.completedAt = completionTime
//        quizSession?.isCompleted = true
//        
//        // Play completion sound
//        playQuizCompleteSound()
//        
//        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
//            showingQuizComplete = true
//        }
//        
//        // Save quiz results to API
//        Task {
//            await saveQuizResults()
//        }
//        
//        print("🎉 Quiz completed! Score: \(correctAnswers)/\(quizQuestions.count) (\(String(format: "%.1f", accuracy))%)")
//    }
//    
//    // MARK: - Timer Management với âm thanh
//    func startQuestionTimer() {
//        guard showTimer else { return }
//        
//        timeRemaining = quizDifficulty.timeLimit
//        
//        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
//            guard let self = self else { return }
//            
//            DispatchQueue.main.async {
//                if self.timeRemaining > 0 {
//                    self.timeRemaining -= 1
//                    
//                    // Start timer tick sound khi còn <= 10 giây
//                    if self.timeRemaining == 10 {
//                        self.startTimerTickSound()
//                    }
//                    
//                    // Speed up timer tick khi còn <= 5 giây
//                    if self.timeRemaining <= 5 {
//                        // Timer tick đã được handle trong AudioManager
//                    }
//                } else {
//                    // Time up!
//                    self.handleTimeUp()
//                }
//            }
//        }
//    }
//    
//    private func handleTimeUp() {
//        stopQuestionTimer()
//        stopTimerTickSound()
//        
//        // Play time up sound
//        playTimeUpSound()
//        
//        // Auto select wrong answer hoặc skip
//        if selectedAnswer == nil {
//            // Tự động chọn đáp án sai đầu tiên (để tính điểm)
//            if let firstOption = currentQuestion?.options.first {
//                selectAnswerWithSound(firstOption)
//            }
//        }
//    }
//    
//    func stopQuestionTimer() {
//        timer?.invalidate()
//        timer = nil
//    }
//    
//    // MARK: - Auto Next Timer với âm thanh
//    private func startAutoNextTimer() {
//        autoNextTimer = Timer.scheduledTimer(withTimeInterval: autoNextDelay, repeats: false) { [weak self] _ in
//            DispatchQueue.main.async {
//                self?.nextQuestionWithSound()
//            }
//        }
//    }
//    
//    private func stopAutoNextTimer() {
//        autoNextTimer?.invalidate()
//        autoNextTimer = nil
//    }
//    
//    // MARK: - Settings với âm thanh
//    func setAutoNext(_ enabled: Bool) {
//        autoNextQuestion = enabled
//        playButtonTapSound()
//        print("🔄 Auto next question: \(enabled)")
//    }
//    
//    func setAutoNextDelay(_ delay: TimeInterval) {
//        autoNextDelay = delay
//        playButtonTapSound()
//        print("⏱️ Auto next delay: \(delay)s")
//    }
//    
//    // MARK: - Quiz Control với âm thanh
//    func resetQuizWithSound() {
//        playButtonTapSound()
//        
//        // Stop all timers and sounds
//        stopQuestionTimer()
//        stopAutoNextTimer()
//        stopTimerTickSound()
//        
//        withAnimation(.easeInOut(duration: 0.5)) {
//            currentQuestionIndex = 0
//            selectedAnswer = nil
//            showAnswer = false
//            showingQuizComplete = false
//            correctAnswers = 0
//            incorrectAnswers = 0
//            totalTime = 0
//            userAnswers = []
//            questionStartTime = Date()
//            sessionStartTime = Date()
//            timeRemaining = quizDifficulty.timeLimit
//        }
//    }
//    
//    func startNewQuizWithSound() {
//        playButtonTapSound()
//        showingCategorySelection = true
//        resetQuizWithSound()
//    }
//    
//    func restartCurrentQuizWithSound() {
//        playButtonTapSound()
//        resetQuizWithSound()
//        quizQuestions.shuffle() // Shuffle questions for variety
//        
//        // Restart timer for first question
//        if !quizQuestions.isEmpty {
//            startQuestionTimer()
//        }
//    }
//    
//    // MARK: - Audio Integration Methods
//    private func playAnswerSound(isCorrect: Bool) {
//        if isCorrect {
//            AudioManager.shared.playCorrectWithDelay(0.1)
//        } else {
//            AudioManager.shared.playIncorrectWithDelay(0.1)
//        }
//    }
//    
//    private func playQuizCompleteSound() {
//        AudioManager.shared.playSound(.quizComplete)
//    }
//    
//    private func playTimeUpSound() {
//        AudioManager.shared.playSound(.timeUp)
//    }
//    
//    private func playButtonTapSound() {
//        AudioManager.shared.playSound(.buttonTap, volume: 0.4)
//    }
//    
//    private func startTimerTickSound() {
//        // Chỉ bật timer tick khi còn <= 10 giây
//        if timeRemaining <= 10 {
//            AudioManager.shared.playTimerTickLoop()
//        }
//    }
//    
//    private func stopTimerTickSound() {
//        AudioManager.shared.stopTimerTick()
//    }
//}
//
//// MARK: - Quiz Difficulty enum
//enum QuizDifficulty: String, CaseIterable {
//    case easy = "Dễ"
//    case medium = "Trung bình"
//    case hard = "Khó"
//    
//    var timeLimit: Int {
//        switch self {
//        case .easy: return 30
//        case .medium: return 20
//        case .hard: return 15
//        }
//    }
//    
//    var description: String {
//        switch self {
//        case .easy: return "30 giây mỗi câu"
//        case .medium: return "20 giây mỗi câu"
//        case .hard: return "15 giây mỗi câu"
//        }
//    }
//}
