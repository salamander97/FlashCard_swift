// Views/Quiz/QuizView.swift
import SwiftUI

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
        .sheet(isPresented: $showingSettings) {
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
            
            // Categories Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
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
            
            // Next Button
            if quizViewModel.showAnswer {
                nextButtonView
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
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
            // Question Type Badge
            HStack {
                Text("Trắc nghiệm")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .clipShape(Capsule())
                
                Spacer()
                
                // Timer (optional)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("00:30")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white.opacity(0.7))
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
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(animateCards ? 1.0 : 0.9)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateCards)
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
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(category.primaryColor.opacity(0.8))
                        .frame(width: 50, height: 50)
                    
                    Text(category.icon)
                        .font(.title2)
                }
                
                // Info
                VStack(spacing: 4) {
                    Text(category.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("\(category.totalWords) từ")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Best score badge
                    if let bestScore = category.quizBestScore, bestScore > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
                            
                            Text("\(bestScore)%")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.yellow)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(16)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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

// MARK: - Quiz Settings View
struct QuizSettingsView: View {
    @ObservedObject var quizViewModel: QuizViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Number of Questions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Số câu hỏi")
                        .font(.headline)
                    
                    HStack {
                        ForEach([5, 10, 15, 20], id: \.self) { count in
                            Button(action: {
                                quizViewModel.numberOfQuestions = count
                            }) {
                                Text("\(count)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(quizViewModel.numberOfQuestions == count ? .white : .blue)
                                    .frame(width: 50, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(quizViewModel.numberOfQuestions == count ? Color.blue : Color.blue.opacity(0.1))
                                    )
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Cài đặt Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Xong") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Preview
struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        QuizView()
    }
}
