// Views/Study/StudyView.swift
import SwiftUI

enum JLPTLevel: String, CaseIterable {
    case N5 = "N5"
    case N4 = "N4"
    case N3 = "N3"
    case N2 = "N2"
    case N1 = "N1"
    
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .N5: return "Cơ bản nhất"
        case .N4: return "Sơ cấp"
        case .N3: return "Trung cấp thấp"
        case .N2: return "Trung cấp cao"
        case .N1: return "Cao cấp"
        }
    }
    
    var color: Color {
        switch self {
        case .N5: return Color(red: 0.3, green: 0.8, blue: 0.4)     // Bright Green
        case .N4: return Color(red: 0.2, green: 0.6, blue: 1.0)     // Bright Blue
        case .N3: return Color(red: 1.0, green: 0.6, blue: 0.2)     // Bright Orange
        case .N2: return Color(red: 1.0, green: 0.3, blue: 0.5)     // Bright Pink
        case .N1: return Color(red: 0.7, green: 0.3, blue: 1.0)     // Bright Purple
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .N5: return [Color(red: 0.3, green: 0.8, blue: 0.4), Color(red: 0.2, green: 0.6, blue: 0.3)]
        case .N4: return [Color(red: 0.2, green: 0.6, blue: 1.0), Color(red: 0.1, green: 0.4, blue: 0.8)]
        case .N3: return [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.8, green: 0.4, blue: 0.1)]
        case .N2: return [Color(red: 1.0, green: 0.3, blue: 0.5), Color(red: 0.8, green: 0.2, blue: 0.4)]
        case .N1: return [Color(red: 0.7, green: 0.3, blue: 1.0), Color(red: 0.5, green: 0.2, blue: 0.8)]
        }
    }
    
    var icon: String {
        switch self {
        case .N5: return "leaf.fill"
        case .N4: return "star.fill"
        case .N3: return "flame.fill"
        case .N2: return "crown.fill"
        case .N1: return "sparkles"
        }
    }
}

struct StudyView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedLevel: JLPTLevel? = nil
    @State private var selectedCategory: Category? = nil
    @State private var categories: [Category] = []
    @State private var isLoadingCategories = false
    @State private var showingFlashcards = false
    @State private var errorMessage = ""
    
    private let apiService = APIService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Darker background with contrast
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.2, green: 0.1, blue: 0.3),
                        Color(red: 0.3, green: 0.2, blue: 0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        
                        if selectedLevel == nil {
                            levelSelectionView
                        } else if selectedCategory == nil {
                            categorySelectionView
                        }
                        
                        // Error message
                        if !errorMessage.isEmpty {
                            errorMessageView
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingFlashcards) {
            if let category = selectedCategory, let level = selectedLevel {
                FlashcardStudyView(category: category, level: level)
                    .onAppear {
                        print("🎴 Opening FlashcardStudyView for \(category.name) - \(level.rawValue)")
                    }
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: goBack) {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack {
                Text(headerTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Placeholder for balance
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Level Selection
    private var levelSelectionView: some View {
        VStack(spacing: 25) {
            // Header with subtitle
            VStack(spacing: 12) {
                Text("Chọn trình độ JLPT")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Hãy chọn level phù hợp với trình độ hiện tại của bạn")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 10)
            
            // Cards grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 15),
                GridItem(.flexible(), spacing: 15)
            ], spacing: 20) {
                ForEach(JLPTLevel.allCases, id: \.self) { level in
                    SimpleLevelCard(level: level) {
                        withAnimation(.spring()) {
                            selectedLevel = level
                            loadCategories()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Category Selection
    private var categorySelectionView: some View {
        VStack(spacing: 20) {
            if let level = selectedLevel {
                HStack {
                    Image(systemName: level.icon)
                        .foregroundColor(level.color)
                    Text("JLPT \(level.displayName)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.bottom, 10)
            }
            
            if isLoadingCategories {
                VStack(spacing: 15) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    Text("Đang tải chủ đề...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .padding(40)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    ForEach(categories) { category in
                        SimpleCategoryCard(category: category) {
                            selectedCategory = category
                            showingFlashcards = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Error Message View
    private var errorMessageView: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Thử lại") {
                errorMessage = ""
                if selectedLevel != nil {
                    loadCategories()
                }
            }
            .foregroundColor(.orange)
            .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                )
        )
        .transition(.slide)
    }
    
    // MARK: - Computed Properties
    private var headerTitle: String {
        if selectedCategory != nil {
            return "Sẵn sàng học"
        } else if selectedLevel != nil {
            return "Chọn chủ đề"
        } else {
            return "Bắt đầu học"
        }
    }
    
    private var headerSubtitle: String {
        if selectedLevel != nil {
            return "JLPT \(selectedLevel?.displayName ?? "")"
        } else {
            return "Chọn trình độ phù hợp"
        }
    }
    
    // MARK: - Actions
    private func goBack() {
        if selectedCategory != nil {
            withAnimation(.spring()) {
                selectedCategory = nil
            }
        } else if selectedLevel != nil {
            withAnimation(.spring()) {
                selectedLevel = nil
                categories = []
            }
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func loadCategories() {
        isLoadingCategories = true
        errorMessage = ""
        
        Task {
            do {
                print("🔄 Loading categories...")
                let allCategories = try await apiService.getCategories()
                print("📥 Received \(allCategories.count) categories")
                
                await MainActor.run {
                    // Sử dụng tất cả categories, không filter theo isUnlocked vì model cũ chưa có field này
                    self.categories = allCategories
                    self.isLoadingCategories = false
                    print("✅ Categories loaded successfully")
                }
            } catch {
                print("❌ Error loading categories: \(error)")
                await MainActor.run {
                    self.categories = []
                    self.isLoadingCategories = false
                    self.errorMessage = "Không thể tải danh sách chủ đề. Vui lòng thử lại."
                }
            }
        }
    }
}

// MARK: - Simple Level Card
struct SimpleLevelCard: View {
    let level: JLPTLevel
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(ScaleButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var cardContent: some View {
        VStack(spacing: 16) {
            // Icon with glow effect
            ZStack {
                // Glow background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [level.color.opacity(0.6), Color.clear],
                            center: .center,
                            startRadius: 5,
                            endRadius: 30
                        )
                    )
                    .frame(width: 80, height: 80)
                
                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: level.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 65, height: 65)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: level.color.opacity(0.4), radius: 8, x: 0, y: 4)
                
                // Icon
                Image(systemName: level.icon)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Level info
            VStack(spacing: 8) {
                Text(level.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(level.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                // Progress bar (mock)
                progressBar
            }
        }
        .padding(20)
        .frame(height: 200)
        .background(cardBackground)
    }
    
    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Tiến độ")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("45%")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(level.color)
                    .frame(width: 50, height: 6)
            }
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.black.opacity(0.3))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                level.color.opacity(0.6),
                                Color.clear,
                                level.color.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Simple Category Card
struct SimpleCategoryCard: View {
    let category: Category
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var cardContent: some View {
        VStack(spacing: 12) {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Color.cyan.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Text(category.icon)
                    .font(.system(size: 28))
            }
            
            // Info section
            VStack(spacing: 6) {
                Text(category.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                wordsCountText
                
                // Completion indicator (mock data vì API chưa có)
                completionBadge(65.0) // Mock 65% completion
            }
            
            Spacer(minLength: 8)
            
            // Action button
            actionButton
        }
        .padding(16)
        .frame(height: 200)
        .background(categoryCardBackground)
    }
    
    private var wordsCountText: some View {
        Text("\(category.totalWords) từ")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.8))
    }
    
    private func completionBadge(_ completion: Double) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            
            Text("\(Int(completion))% hoàn thành")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.2))
        .clipShape(Capsule())
    }
    
    private var actionButton: some View {
        HStack(spacing: 4) {
            Image(systemName: "play.fill")
                .font(.system(size: 10))
            Text("Bắt đầu học")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [Color.cyan, Color.blue],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
        .shadow(color: Color.cyan.opacity(0.4), radius: 4, x: 0, y: 2)
    }
    
    private var categoryCardBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.black.opacity(0.3))
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Flashcard Study View
struct FlashcardStudyView: View {
    let category: Category
    let level: JLPTLevel
    @Environment(\.presentationMode) var presentationMode
    @State private var words: [Word] = []
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var isLoading = true
    @State private var dragOffset = CGSize.zero
    @State private var showControls = true
    @State private var studiedCount = 0
    
    private let apiService = APIService.shared
    
    // Sample words for fallback
    private let sampleWords = [
        Word(id: 1, japaneseWord: "おはよう", kanji: nil, romaji: "ohayou", vietnameseMeaning: "Chào buổi sáng", exampleSentenceJp: "おはようございます。", exampleSentenceVn: "Chào buổi sáng ạ."),
        Word(id: 2, japaneseWord: "ありがとう", kanji: nil, romaji: "arigatou", vietnameseMeaning: "Cảm ơn", exampleSentenceJp: "ありがとうございます。", exampleSentenceVn: "Cảm ơn bạn."),
        Word(id: 3, japaneseWord: "すみません", kanji: nil, romaji: "sumimasen", vietnameseMeaning: "Xin lỗi", exampleSentenceJp: "すみません、遅れました。", exampleSentenceVn: "Xin lỗi, tôi đến muộn."),
        Word(id: 4, japaneseWord: "はじめまして", kanji: nil, romaji: "hajimemashite", vietnameseMeaning: "Rất vui được gặp bạn", exampleSentenceJp: "はじめまして、よろしくお願いします。", exampleSentenceVn: "Rất vui được gặp bạn, xin hãy giúp đỡ."),
        Word(id: 5, japaneseWord: "さようなら", kanji: nil, romaji: "sayounara", vietnameseMeaning: "Tạm biệt", exampleSentenceJp: "さようなら、また明日。", exampleSentenceVn: "Tạm biệt, hẹn gặp lại ngày mai.")
    ]
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Progress
                progressView
                
                Spacer()
                
                // Flashcard
                if !words.isEmpty {
                    flashcardView
                } else if isLoading {
                    loadingView
                } else {
                    emptyView
                }
                
                Spacer()
                
                // Controls
                if showControls && !words.isEmpty {
                    controlsView
                }
                
                Spacer(minLength: 50)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadWords()
        }
    }
    
    // MARK: - Background
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.2, green: 0.1, blue: 0.3),
                level.color.opacity(0.3)
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
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("JLPT \(level.displayName)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    showControls.toggle()
                }
            }) {
                Image(systemName: showControls ? "eye.slash" : "eye")
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
    
    // MARK: - Progress
    private var progressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Tiến độ: \(currentIndex + 1)/\(words.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("Đã học: \(studiedCount)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(level.color)
                    .frame(width: progressWidth, height: 6)
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var progressWidth: CGFloat {
        guard !words.isEmpty else { return 0 }
        let screenWidth = UIScreen.main.bounds.width - 40
        return screenWidth * CGFloat(currentIndex + 1) / CGFloat(words.count)
    }
    
    // MARK: - Flashcard
    private var flashcardView: some View {
        let currentWord = words[currentIndex]
        
        return ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            // Front side (Japanese)
            if !isFlipped {
                frontSide(word: currentWord)
            } else {
                // Back side (Vietnamese)
                backSide(word: currentWord)
                    .rotation3DEffect(
                        .degrees(180),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
        }
        .frame(width: UIScreen.main.bounds.width - 40, height: 300)
        .offset(dragOffset)
        .rotationEffect(.degrees(Double(dragOffset.width / 10)))
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    handleSwipe(translation: value.translation)
                }
        )
        .onTapGesture {
            flipCard()
        }
    }
    
    private func frontSide(word: Word) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("🎴")
                    .font(.system(size: 40))
                
                Text("Nhấn để xem nghĩa")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 12) {
                Text(word.japaneseWord)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                if let kanji = word.kanji, !kanji.isEmpty {
                    Text(kanji)
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
                
                Text(word.romaji)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                    .italic()
            }
        }
        .padding(30)
    }
    
    private func backSide(word: Word) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("🇻🇳")
                    .font(.system(size: 40))
                
                Text("Nghĩa tiếng Việt")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 16) {
                // Main meaning
                Text(word.vietnameseMeaning)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                // Example sentences
                if let exampleJp = word.exampleSentenceJp, !exampleJp.isEmpty {
                    VStack(spacing: 8) {
                        Text("Ví dụ:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(exampleJp)
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                        
                        if let exampleVn = word.exampleSentenceVn, !exampleVn.isEmpty {
                            Text(exampleVn)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }.padding(.horizontal, 10)
                }
                
                // JLPT Level badge
                Text("JLPT \(level.displayName)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(level.color)
                    .clipShape(Capsule())
            }
        }
        .padding(20)
    }
    
    // MARK: - Controls
    private var controlsView: some View {
        HStack(spacing: 20) {
            // Previous button
            Button(action: previousCard) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Trước")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
            }
            .disabled(currentIndex == 0)
            .opacity(currentIndex == 0 ? 0.5 : 1.0)
            
            // Flip button
            Button(action: flipCard) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text(isFlipped ? "Mặt trước" : "Mặt sau")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(level.color)
                .clipShape(Capsule())
            }
            
            // Next button
            Button(action: nextCard) {
                HStack {
                    Text("Sau")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
            }
            .disabled(currentIndex >= words.count - 1)
            .opacity(currentIndex >= words.count - 1 ? 0.5 : 1.0)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Loading & Empty States
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Đang tải từ vựng...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Text("📚")
                .font(.system(size: 60))
            
            Text("Không có từ vựng")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Chủ đề này chưa có từ vựng nào cho level \(level.displayName)")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Actions
    private func loadWords() {
        isLoading = true
        print("🔄 Loading words for category: \(category.id), level: \(level.rawValue)")
        
        Task {
            do {
                // Get all words for this category
                let allWords = try await apiService.getStudyWords(categoryId: category.id)
                print("📥 Received \(allWords.count) words from API")
                
                await MainActor.run {
                    // Sử dụng tất cả từ vựng trong category, không filter theo JLPT level
                    // vì API của bạn có thể chưa có thông tin JLPT level
                    self.words = allWords
                    print("📚 Using all \(self.words.count) words")
                    
                    // If no words found, use sample data as fallback
                    if self.words.isEmpty {
                        print("⚠️ No words found, using sample data")
                        self.words = self.sampleWords
                    }
                    
                    self.isLoading = false
                }
            } catch {
                print("❌ API Error: \(error)")
                await MainActor.run {
                    // Fallback to sample words if API fails
                    print("🔄 Using sample words as fallback")
                    self.words = self.sampleWords
                    self.isLoading = false
                }
            }
        }
    }
    
    private func flipCard() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isFlipped.toggle()
        }
    }
    
    private func nextCard() {
        guard currentIndex < words.count - 1 else { return }
        
        withAnimation(.spring()) {
            currentIndex += 1
            isFlipped = false
            studiedCount += 1
        }
    }
    
    private func previousCard() {
        guard currentIndex > 0 else { return }
        
        withAnimation(.spring()) {
            currentIndex -= 1
            isFlipped = false
        }
    }
    
    private func handleSwipe(translation: CGSize) {
        let threshold: CGFloat = 50
        
        withAnimation(.spring()) {
            if translation.width > threshold {
                // Swipe right - previous card
                if currentIndex > 0 {
                    previousCard()
                }
            } else if translation.width < -threshold {
                // Swipe left - next card
                if currentIndex < words.count - 1 {
                    nextCard()
                }
            }
            
            dragOffset = .zero
        }
    }
}

// MARK: - Preview
struct StudyView_Previews: PreviewProvider {
    static var previews: some View {
        StudyView()
    }
}
