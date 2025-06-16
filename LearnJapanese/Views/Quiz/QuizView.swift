// Views/Quiz/QuizView.swift
import SwiftUI
import Foundation

struct QuizView: View {
    @StateObject private var quizViewModel = QuizViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var animateProgress = false
    @State private var animateCards = false
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Content based on state
                    if quizViewModel.showingCategorySelection {
                        categorySelectionView
                    } else if quizViewModel.isLoading {
                        loadingView
                    } else if quizViewModel.showingQuizComplete {
                        quizCompleteView
                    } else if !quizViewModel.quizQuestions.isEmpty {
                        quizContentView
                    } else {
                        emptyStateView
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startAnimations()
        }
        .fullScreenCover(isPresented: $showingSettings) {
            QuizSettingsView(quizViewModel: quizViewModel)
        }
    }
    
    // MARK: - Background
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(hex: "667eea"),
                Color(hex: "764ba2"),
                Color(hex: "f093fb")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                if quizViewModel.showingCategorySelection {
                    presentationMode.wrappedValue.dismiss()
                } else {
                    quizViewModel.startNewQuiz()
                }
            }) {
                Image(systemName: quizViewModel.showingCategorySelection ? "xmark" : "arrow.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                if quizViewModel.showingCategorySelection {
                    Text("Chọn chủ đề Quiz")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text(quizViewModel.selectedCategory?.name ?? "Quiz")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if !quizViewModel.showingQuizComplete {
                        Text("Câu \(quizViewModel.currentQuestionIndex + 1)/\(quizViewModel.quizQuestions.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Category Selection
    private var categorySelectionView: some View {
        VStack(spacing: 25) {
            // Mode Selection
            modeSelectionView
            
            // Level Selection
            levelSelectionView
            
            // Categories Grid với spacing đồng đều
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 20),
                    GridItem(.flexible(), spacing: 20)
                ], spacing: 20) {
                    ForEach(quizViewModel.categories) { category in
                        QuizCategoryCard(category: category) {
                            // Auto-select N5 level for now
                            quizViewModel.selectCategoryAndLevel(
                                category: category,
                                level: .N5
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30) // Thêm padding bottom
            }
        }
        .padding(.top, 20)
    }
    
    private var modeSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chế độ quiz")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(QuizMode.allCases, id: \.self) { mode in
                        QuizModeButton(
                            mode: mode,
                            isSelected: quizViewModel.quizMode == mode
                        ) {
                            withAnimation(.spring()) {
                                quizViewModel.quizMode = mode
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var levelSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trình độ JLPT")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(JLPTLevel.allCases, id: \.self) { level in
                        QuizLevelButton(
                            level: level,
                            isSelected: quizViewModel.selectedLevel == level
                        ) {
                            withAnimation(.spring()) {
                                quizViewModel.selectedLevel = level
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Quiz Content
    private var quizContentView: some View {
        VStack(spacing: 20) {
            // Progress Bar
            progressView
            
            // Question Card
            questionCardView
            
            // Answer Options
            answerOptionsView
            
            // ✅ CẬP NHẬT: Next Button - chỉ hiện khi auto next TẮT
            if quizViewModel.showAnswer && !quizViewModel.autoNextQuestion {
                nextButtonView
            }
            
            // ✅ THÊM: Auto Next Indicator - chỉ hiện khi auto next BẬT
            if quizViewModel.showAnswer && quizViewModel.autoNextQuestion {
                autoNextIndicatorView
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var autoNextIndicatorView: some View {
        HStack(spacing: 12) {
            // Loading spinner
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
            
            VStack(spacing: 4) {
                Text(quizViewModel.currentQuestionIndex + 1 >= quizViewModel.quizQuestions.count
                     ? "Đang hoàn thành quiz..."
                     : "Chuyển câu tiếp theo...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Chạm để chuyển ngay")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Manual skip button
            Button(action: {
                quizViewModel.nextQuestion()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .onTapGesture {
            // Cho phép tap vào indicator để chuyển ngay
            quizViewModel.nextQuestion()
        }
        .padding(.top, 10)
    }
    
    private var progressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Tiến độ")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("\(String(format: "%.1f", quizViewModel.progressPercentage))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: progressWidth, height: 6)
                    .animation(.easeInOut(duration: 0.5), value: quizViewModel.currentQuestionIndex)
            }
        }
    }
    
    private var progressWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 40
        return screenWidth * CGFloat(quizViewModel.progressPercentage) / 100
    }
    
    private var questionCardView: some View {
        VStack(spacing: 20) {
            // Question Type Badge với Timer
            HStack {
                Text("Trắc nghiệm")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.6, blue: 1.0),    // Bright Blue
                                Color(red: 0.1, green: 0.4, blue: 0.8)     // Darker Blue
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Spacer()
                
                // Timer Display (nếu có)
                if quizViewModel.showTimer && !quizViewModel.showAnswer {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(timerTextColor)
                        
                        Text("\(quizViewModel.timeRemaining)s")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(timerTextColor)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(timerBackground)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(timerBorderColor, lineWidth: 2)
                    )
                    .scaleEffect(quizViewModel.timeRemaining <= 5 ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3).repeatCount(quizViewModel.timeRemaining <= 5 ? .max : 1),
                              value: quizViewModel.timeRemaining)
                }
            }
            
            // Circular Timer Progress (nếu muốn thêm)
            if quizViewModel.showTimer && !quizViewModel.showAnswer {
                timerProgressView
            }
            
            // Main Question
            VStack(spacing: 16) {
                Text("Từ tiếng Nhật này có nghĩa là gì?")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 8) {
                    // Japanese word
                    Text(quizViewModel.currentQuestion?.questionText ?? "")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Romaji
                    if let romaji = quizViewModel.currentQuestion?.romaji {
                        Text(romaji)
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                            .italic()
                    }
                    
                    // Kanji (if available)
                    if let kanji = quizViewModel.currentQuestion?.kanji, !kanji.isEmpty {
                        Text(kanji)
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            quizViewModel.timeRemaining <= 5 ? Color.red.opacity(0.6) : Color.white.opacity(0.3),
                            lineWidth: quizViewModel.timeRemaining <= 5 ? 2 : 1
                        )
                )
        )
        .scaleEffect(animateCards ? 1.0 : 0.9)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateCards)
    }
    // MARK: - Timer Colors (thêm vào QuizView)
    private var timerTextColor: Color {
        switch quizViewModel.timeRemaining {
        case 11...: return .white
        case 6...10: return .white
        default: return .white
        }
    }

    private var timerBackground: some View {
        LinearGradient(
            colors: timerGradientColors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var timerGradientColors: [Color] {
        switch quizViewModel.timeRemaining {
        case 11...:
            return [
                Color(red: 0.2, green: 0.8, blue: 0.4),    // Bright Green
                Color(red: 0.1, green: 0.6, blue: 0.3)     // Darker Green
            ]
        case 6...10:
            return [
                Color(red: 1.0, green: 0.6, blue: 0.2),    // Bright Orange
                Color(red: 0.8, green: 0.4, blue: 0.1)     // Darker Orange
            ]
        default:
            return [
                Color(red: 1.0, green: 0.3, blue: 0.3),    // Bright Red
                Color(red: 0.8, green: 0.1, blue: 0.1)     // Darker Red
            ]
        }
    }

    private var timerBorderColor: Color {
        switch quizViewModel.timeRemaining {
        case 11...: return Color.green.opacity(0.6)
        case 6...10: return Color.orange.opacity(0.6)
        default: return Color.red.opacity(0.8)
        }
    }
    
    private var answerOptionsView: some View {
        VStack(spacing: 12) {
            ForEach(Array((quizViewModel.currentQuestion?.options ?? []).enumerated()), id: \.offset) { index, option in
                QuizAnswerButton(
                    option: option,
                    index: index,
                    isSelected: quizViewModel.selectedAnswer == option,
                    showAnswer: quizViewModel.showAnswer,
                    isCorrect: option == quizViewModel.currentQuestion?.correctAnswer
                ) {
                    guard !quizViewModel.showAnswer else { return }
                    quizViewModel.selectAnswer(option)
                }
            }
        }
    }
    
    // Timer color helper
    private var timerColor: Color {
        switch quizViewModel.timeRemaining {
        case 11...: return .green
        case 6...10: return .orange
        default: return .red
        }
    }

    // Circular Timer Progress View
    private var timerProgressView: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                .frame(width: 60, height: 60)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: timerProgress)
                .stroke(timerColor, lineWidth: 4)
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: quizViewModel.timeRemaining)
            
            // Timer text
            Text("\(quizViewModel.timeRemaining)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(timerColor)
        }
    }

    // Timer progress calculation
    private var timerProgress: Double {
        let maxTime = Double(quizViewModel.quizDifficulty.timeLimit)
        let remaining = Double(quizViewModel.timeRemaining)
        return remaining / maxTime
    }
    
    private var nextButtonView: some View {
        Button(action: {
            quizViewModel.nextQuestion()
        }) {
            HStack(spacing: 8) {
                Text(quizViewModel.currentQuestionIndex + 1 >= quizViewModel.quizQuestions.count ? "Hoàn thành" : "Câu tiếp theo")
                    .font(.system(size: 16, weight: .semibold))
                
                Image(systemName: quizViewModel.currentQuestionIndex + 1 >= quizViewModel.quizQuestions.count ? "checkmark" : "arrow.right")
                    .font(.system(size: 14))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.green, Color.green.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 10)
    }
    
    // MARK: - Quiz Complete View
    private var quizCompleteView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Celebration Animation
            VStack(spacing: 20) {
                Text(quizViewModel.accuracy >= 80 ? "🎉" : quizViewModel.accuracy >= 60 ? "👏" : "💪")
                    .font(.system(size: 80))
                    .scaleEffect(animateCards ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateCards)
                
                Text("Quiz hoàn thành!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text(quizViewModel.getQuizSummary().grade)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Results Summary
            quizResultsView
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 15) {
                // Review Answers Button
                Button(action: {
                    // TODO: Show detailed review
                }) {
                    HStack {
                        Image(systemName: "eye.fill")
                        Text("Xem lại đáp án")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Retry Button
                Button(action: {
                    quizViewModel.restartCurrentQuiz()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Làm lại Quiz")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // New Quiz Button
                Button(action: {
                    quizViewModel.startNewQuiz()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Quiz mới")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.green.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Back to Home Button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Về trang chủ")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
    
    private var quizResultsView: some View {
        VStack(spacing: 20) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: quizViewModel.accuracy / 100)
                    .stroke(quizViewModel.getQuizSummary().scoreColor, lineWidth: 8)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: animateProgress)
                
                VStack(spacing: 4) {
                    Text("\(Int(quizViewModel.accuracy))%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Độ chính xác")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Statistics
            HStack(spacing: 30) {
                StatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(quizViewModel.correctAnswers)",
                    label: "Đúng",
                    color: .green
                )
                
                StatItem(
                    icon: "xmark.circle.fill",
                    value: "\(quizViewModel.incorrectAnswers)",
                    label: "Sai",
                    color: .red
                )
                
                StatItem(
                    icon: "clock.fill",
                    value: formatTime(quizViewModel.totalTime),
                    label: "Thời gian",
                    color: .blue
                )
            }
            
            // Category Info
            HStack(spacing: 12) {
                Text(quizViewModel.selectedCategory?.icon ?? "📚")
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(quizViewModel.selectedCategory?.name ?? "Unknown")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("JLPT \(quizViewModel.selectedLevel?.displayName ?? "N5")")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Đang tải câu hỏi...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Text("❓")
                .font(.system(size: 60))
            
            Text("Không có câu hỏi")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Không tìm thấy câu hỏi cho chủ đề này")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button(action: {
                quizViewModel.startNewQuiz()
            }) {
                Text("Thử chủ đề khác")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(40)
    }
    
    // MARK: - Helper Functions
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.8)) {
            animateCards = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateProgress = true
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Components

struct QuizCategoryCard: View {
    let category: Category
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // SF Symbol Icon với gradient background
                ZStack {
                    // Glow background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    category.primaryColor.opacity(0.6),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 35
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    // Main gradient circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: category.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 55, height: 55)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(
                            color: category.primaryColor.opacity(0.4),
                            radius: 8, x: 0, y: 4
                        )
                    
                    // SF Symbol Icon
                    Image(systemName: category.sfSymbol)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Category Info
                VStack(spacing: 8) {
                    Text(category.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(minHeight: 40) // Đảm bảo chiều cao đồng đều
                    
                    // Words count
                    HStack(spacing: 4) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("\(category.totalWords) từ")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Best score badge (nếu có)
                    if let bestScore = category.quizBestScore, bestScore > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
                            
                            Text("\(bestScore)%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )
                    } else {
                        // Placeholder để giữ layout đồng đều
                        Text("")
                            .font(.system(size: 10))
                            .frame(height: 16)
                    }
                }
            }
            .padding(20)
            .frame(width: 160, height: 180) // Kích thước cố định để đồng đều
            .background(cardBackground)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                category.primaryColor.opacity(0.6),
                                Color.clear,
                                category.primaryColor.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}
struct QuizModeButton: View {
    let mode: QuizMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.system(size: 14))
                
                Text(mode.displayName)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(isSelected ? 0.5 : 0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct QuizLevelButton: View {
    let level: JLPTLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: level.icon)
                    .font(.system(size: 12))
                
                Text(level.displayName)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : level.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? level.color : Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(level.color, lineWidth: isSelected ? 0 : 1.5)
                    )
            )
        }
    }
}

struct QuizAnswerButton: View {
    let option: String
    let index: Int
    let isSelected: Bool
    let showAnswer: Bool
    let isCorrect: Bool
    let onTap: () -> Void
    
    private var backgroundColor: Color {
        if !showAnswer {
            return isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.1)
        } else {
            if isCorrect {
                return Color.green.opacity(0.3)
            } else if isSelected && !isCorrect {
                return Color.red.opacity(0.3)
            } else {
                return Color.white.opacity(0.1)
            }
        }
    }
    
    private var borderColor: Color {
        if !showAnswer {
            return isSelected ? Color.blue : Color.white.opacity(0.3)
        } else {
            if isCorrect {
                return Color.green
            } else if isSelected && !isCorrect {
                return Color.red
            } else {
                return Color.white.opacity(0.3)
            }
        }
    }
    
    private var iconName: String? {
        if showAnswer {
            if isCorrect {
                return "checkmark.circle.fill"
            } else if isSelected && !isCorrect {
                return "xmark.circle.fill"
            }
        }
        return nil
    }
    
    private var iconColor: Color {
        if isCorrect {
            return .green
        } else {
            return .red
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Option letter
                Text(String(Character(UnicodeScalar(65 + index)!)))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(borderColor))
                
                // Option text
                Text(option)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Result icon
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 2)
                    )
            )
        }
        .disabled(showAnswer)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Quiz Settings View (SỬA LỖI KHÔNG RELOAD)
struct QuizSettingsView: View {
    @ObservedObject var quizViewModel: QuizViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedQuestionIndex: Int?
    @State private var selectedDifficultyIndex: Int?
    
    let questionOptions = [5, 10, 15, 20]
    let difficultyOptions = QuizDifficulty.allCases

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "667eea"), Color(hex: "764ba2"), Color(hex: "f093fb")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 35) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Cài đặt Quiz")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                            Text("Tùy chỉnh trải nghiệm quiz của bạn")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.top, 15)
                        
                        // Số câu hỏi
                        VStack(spacing: 20) {
                            VStack(spacing: 8) {
                                Text("Số câu hỏi")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Chọn số câu hỏi cho mỗi quiz")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            HStack(spacing: 18) {
                                ForEach(questionOptions.indices, id: \.self) { idx in
                                    let count = questionOptions[idx]
                                    questionCard(idx: idx, count: count)
                                }
                            }
                        }
                        
                        // Độ khó
                        VStack(spacing: 20) {
                            VStack(spacing: 8) {
                                Text("Độ khó")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Thời gian trả lời mỗi câu")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(difficultyOptions.indices, id: \.self) { idx in
                                    let difficulty = difficultyOptions[idx]
                                    difficultyCard(idx: idx, difficulty: difficulty)
                                }
                            }
                        }
                        
                        // Chuyển câu tự động & nút áp dụng
                        VStack(spacing: 20) {
                            VStack(spacing: 8) {
                                Text("Chuyển câu tự động")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Tự động chuyển sang câu tiếp theo sau khi trả lời")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            VStack(spacing: 15) {
                                // Auto Next Toggle
                                autoNextToggleCard
                                
                                // Delay Settings (nếu có)
                                if quizViewModel.autoNextQuestion {
                                    autoNextDelayCard
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .top).combined(with: .opacity),
                                            removal: .move(edge: .top).combined(with: .opacity)
                                        ))
                                }
                                
                                // Nút áp dụng & reload nằm ngay đây!
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                    Task {
                                        await reloadQuizWithNewSettings()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20, weight: .bold))
                                        Text("Áp dụng & Reload Quiz")
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(hex: "667eea"), Color(hex: "f093fb")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: Color(hex: "667eea").opacity(0.18), radius: 12, x: 0, y: 8)
                                }
                                .padding(.horizontal, 0) // Hoặc .padding(.horizontal, 20) nếu muốn căn đều
                            }
                        }
                        
                        // Spacer để tránh bị kéo lên quá sát trên
                        Spacer(minLength: 0.1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
        }
    }
    
    private var autoNextToggleCard: some View {
           Button(action: {
               withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                   quizViewModel.setAutoNext(!quizViewModel.autoNextQuestion)
               }
           }) {
               HStack(spacing: 15) {
                   // Auto Next Icon - IMPROVED
                   ZStack {
                       Circle()
                           .fill(quizViewModel.autoNextQuestion ? Color.green.opacity(0.25) : Color.gray.opacity(0.25))
                           .frame(width: 42, height: 42)
                       
                       Image(systemName: quizViewModel.autoNextQuestion ? "forward.fill" : "pause.fill")
                           .font(.system(size: 18, weight: .bold))
                           .foregroundColor(quizViewModel.autoNextQuestion ? .green : .gray)
                   }
                   
                   VStack(alignment: .leading, spacing: 5) {
                       // ✅ FIX: Màu chữ tốt hơn
                       Text(quizViewModel.autoNextQuestion ? "Tự động: BẬT" : "Tự động: TẮT")
                           .font(.system(size: 16, weight: .bold))
                           .foregroundColor(quizViewModel.autoNextQuestion ? .green : .white)
                       
                       Text(quizViewModel.autoNextQuestion
                            ? "Tự động chuyển câu sau khi trả lời"
                            : "Hiện nút 'Câu tiếp theo'")
                           .font(.system(size: 13, weight: .medium))
                           .foregroundColor(.white.opacity(0.8))
                   }
                   
                   Spacer()
                   
                   // ✅ FIX: Toggle Switch Visual cải thiện
                   ZStack {
                       RoundedRectangle(cornerRadius: 16)
                           .fill(quizViewModel.autoNextQuestion ? Color.green : Color.gray.opacity(0.5))
                           .frame(width: 52, height: 30)
                       
                       Circle()
                           .fill(Color.white)
                           .frame(width: 26, height: 26)
                           .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                           .offset(x: quizViewModel.autoNextQuestion ? 11 : -11)
                           .animation(.spring(response: 0.3, dampingFraction: 0.8), value: quizViewModel.autoNextQuestion)
                   }
               }
               .padding(.horizontal, 20)
               .padding(.vertical, 16)
               .background(autoNextToggleBackground)
           }
           .buttonStyle(PlainButtonStyle())
       }

    // ✅ THÊM: Auto Next Delay Card
    private var autoNextDelayCard: some View {
            VStack(spacing: 15) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Thời gian chờ")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // ✅ FIX: Màu sắc time display
                    Text("\(String(format: "%.1f", quizViewModel.autoNextDelay))s")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.yellow.opacity(0.2))
                        )
                }
                
                // Delay Options - IMPROVED
                HStack(spacing: 10) {
                    ForEach([1.0, 1.5, 2.0, 3.0], id: \.self) { delay in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                quizViewModel.setAutoNextDelay(delay)
                            }
                        }) {
                            Text("\(String(format: "%.1f", delay))s")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(quizViewModel.autoNextDelay == delay ? .white : .yellow)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(quizViewModel.autoNextDelay == delay
                                              ? Color.yellow
                                              : Color.yellow.opacity(0.25))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    quizViewModel.autoNextDelay == delay
                                                        ? Color.clear
                                                        : Color.yellow.opacity(0.5),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(quizViewModel.autoNextDelay == delay ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: quizViewModel.autoNextDelay)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.4), lineWidth: 1.5)
                    )
                    .shadow(color: Color.green.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }

    // ✅ THÊM: Auto Next Toggle Background
    private var autoNextToggleBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: quizViewModel.autoNextQuestion
                        ? [Color.green.opacity(0.2), Color.green.opacity(0.1)]
                        : [Color.gray.opacity(0.15), Color.gray.opacity(0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        quizViewModel.autoNextQuestion ? Color.green.opacity(0.5) : Color.gray.opacity(0.3),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: quizViewModel.autoNextQuestion ? Color.green.opacity(0.2) : Color.gray.opacity(0.1),
                radius: 8, x: 0, y: 4
            )
    }
    
    // ✅ THÊM: Function để reload quiz với settings mới
    private func reloadQuizWithNewSettings() async {
        print("🔄 Reloading quiz với settings mới:")
        print("   - Số câu: \(quizViewModel.numberOfQuestions)")
        print("   - Độ khó: \(quizViewModel.quizDifficulty.rawValue)")
        print("   - Auto Next: \(quizViewModel.autoNextQuestion)")
        print("   - Auto Delay: \(quizViewModel.autoNextDelay)s")
        
        // Reset quiz hiện tại
        quizViewModel.resetQuiz()
        
        // Load questions mới với settings đã cập nhật
        await quizViewModel.loadQuizQuestions()
    }

    // Card cho số câu hỏi
    private func questionCard(idx: Int, count: Int) -> some View {
           let isSelected = quizViewModel.numberOfQuestions == count
           return Button(action: {
               withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                   quizViewModel.numberOfQuestions = count
                   selectedQuestionIndex = idx
                   print("📝 Đã chọn số câu: \(count)")
               }
           }) {
               VStack(spacing: 6) {
                   Text("\(count)")
                       .font(.system(size: 24, weight: .bold))
                       .foregroundColor(isSelected ? .white : Color.blue)
                   Text("Câu")
                       .font(.system(size: 13, weight: .medium))
                       .foregroundColor(isSelected ? .white.opacity(0.9) : .blue.opacity(0.8))
               }
               .frame(width: 68, height: 82)
               .background(questionCardBackground(isSelected: isSelected))
               .scaleEffect(isSelected ? 1.1 : 1.0)
               .animation(.easeInOut(duration: 0.2), value: quizViewModel.numberOfQuestions)
           }
           .buttonStyle(PlainButtonStyle())
       }
    
    // Card cho độ khó
    private func difficultyCard(idx: Int, difficulty: QuizDifficulty) -> some View {
           let isSelected = quizViewModel.quizDifficulty == difficulty
           return Button(action: {
               withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                   quizViewModel.quizDifficulty = difficulty
                   selectedDifficultyIndex = idx
                   print("📝 Đã chọn độ khó: \(difficulty.rawValue) - \(difficulty.timeLimit)s")
               }
           }) {
               HStack(spacing: 15) {
                   // Icon cho độ khó
                   ZStack {
                       Circle()
                           .fill(isSelected ? Color.white.opacity(0.2) : difficultyColor(difficulty).opacity(0.2))
                           .frame(width: 40, height: 40)
                       
                       Image(systemName: difficultyIcon(difficulty))
                           .font(.system(size: 18, weight: .semibold))
                           .foregroundColor(isSelected ? .white : difficultyColor(difficulty))
                   }
                   
                   VStack(alignment: .leading, spacing: 4) {
                       Text(difficulty.rawValue)
                           .font(.system(size: 16, weight: .semibold))
                           .foregroundColor(isSelected ? .white : difficultyColor(difficulty))
                       
                       Text("\(difficulty.timeLimit) giây/câu")
                           .font(.system(size: 13, weight: .medium))
                           .foregroundColor(isSelected ? .white.opacity(0.8) : difficultyColor(difficulty).opacity(0.8))
                   }
                   
                   Spacer()
                   
                   // Checkmark
                   if isSelected {
                       Image(systemName: "checkmark.circle.fill")
                           .font(.system(size: 20))
                           .foregroundColor(.white)
                   }
               }
               .padding(.horizontal, 20)
               .padding(.vertical, 12)
               .background(difficultyCardBackground(isSelected: isSelected, difficulty: difficulty))
           }
           .buttonStyle(PlainButtonStyle())
       }

       // Background cho question card - UNCHANGED
       private func questionCardBackground(isSelected: Bool) -> some View {
           ZStack {
               RoundedRectangle(cornerRadius: 20)
                   .fill(
                       isSelected
                           ? AnyShapeStyle(
                               LinearGradient(
                                   colors: [Color(hex: "764ba2"), Color(hex: "667eea")],
                                   startPoint: .top,
                                   endPoint: .bottom
                               )
                           )
                           : AnyShapeStyle(Color.white.opacity(0.95))
                   )
                   .shadow(
                       color: isSelected
                           ? Color(hex: "764ba2").opacity(0.28)
                           : Color.black.opacity(0.12),
                       radius: 12, x: 0, y: 8
                   )
               
               RoundedRectangle(cornerRadius: 20)
                   .stroke(
                       isSelected
                           ? Color.white.opacity(0.7)
                           : Color(hex: "764ba2").opacity(0.28),
                       lineWidth: 2
                   )
           }
       }
       
       // Background cho difficulty card - UNCHANGED
       private func difficultyCardBackground(isSelected: Bool, difficulty: QuizDifficulty) -> some View {
           RoundedRectangle(cornerRadius: 16)
               .fill(
                   LinearGradient(
                       colors: isSelected
                           ? [difficultyColor(difficulty), difficultyColor(difficulty).opacity(0.8)]
                           : [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                       startPoint: .leading,
                       endPoint: .trailing
                   )
               )
               .overlay(
                   RoundedRectangle(cornerRadius: 16)
                       .stroke(
                           isSelected ? Color.white.opacity(0.5) : difficultyColor(difficulty).opacity(0.3),
                           lineWidth: isSelected ? 2 : 1
                       )
               )
               .shadow(
                   color: isSelected ? difficultyColor(difficulty).opacity(0.3) : Color.black.opacity(0.1),
                   radius: 8, x: 0, y: 4
               )
       }
       
       // Helper functions - UNCHANGED
       private func difficultyColor(_ difficulty: QuizDifficulty) -> Color {
           switch difficulty {
           case .easy:
               return Color(red: 0.2, green: 0.8, blue: 0.4)
           case .medium:
               return Color(red: 1.0, green: 0.7, blue: 0.2)
           case .hard:
               return Color(red: 1.0, green: 0.4, blue: 0.6)
           }
       }
       
       private func difficultyIcon(_ difficulty: QuizDifficulty) -> String {
           switch difficulty {
           case .easy: return "leaf.fill"
           case .medium: return "flame.fill"
           case .hard: return "bolt.fill"
           }
       }
   }


// MARK: - Preview
struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        QuizView()
    }
}
