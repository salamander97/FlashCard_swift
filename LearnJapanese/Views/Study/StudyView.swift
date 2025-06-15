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
                // 🌿 NEW: Light green background
                LinearGradient(
                    colors: [
                        Color(red: 0.906, green: 1.0, blue: 0.808),    // #E7FFCE
                        Color(red: 0.85, green: 0.95, blue: 0.75),     // Slightly darker variant
                        Color(red: 0.8, green: 0.9, blue: 0.7)        // Even darker for depth
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
        .fullScreenCover(isPresented: $showingFlashcards) {
            if let category = selectedCategory, let level = selectedLevel {
                FlashcardStudyView(category: category, level: level)
            }
        }
        .onChange(of: showingFlashcards) { isPresented in
            if !isPresented {
                selectedCategory = nil
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: goBack) {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.3)) // Dark green for contrast
                    .padding(12)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            }
            
            Spacer()
            
            VStack {
                Text(headerTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.2)) // Dark green text
                
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.4)) // Medium green
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
                    .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.2))
                
                Text("Hãy chọn level phù hợp với trình độ hiện tại của bạn")
                    .font(.body)
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.3))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 10)
            
            // Cards grid với chiều cao cố định
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
                    .frame(height: 200)
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
                        .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.2))
                }
                .padding(.bottom, 10)
            }
            
            if isLoadingCategories {
                VStack(spacing: 15) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.2, green: 0.6, blue: 0.4)))
                        .scaleEffect(1.2)
                    Text("Đang tải chủ đề...")
                        .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.3))
                        .font(.headline)
                }
                .padding(40)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 15),
                    GridItem(.flexible(), spacing: 15)
                ], spacing: 15) {
                    ForEach(categories) { category in
                        SimpleCategoryCard(category: category) {
                            selectedCategory = category
                            showingFlashcards = true
                        }
                        .frame(height: 250)
                    }
                }
            }
        }
    }
    
    // MARK: - Error Message View
    private var errorMessageView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Có lỗi xảy ra")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.2))
                    
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.3))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Retry button
                Button("Thử lại") {
                    errorMessage = ""
                    if selectedLevel != nil {
                        loadCategories()
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                        )
                )
                
                Spacer()
                
                // Logout button - Chỉ hiện khi có lỗi authentication
                if isAuthenticationError {
                    Button("Đăng xuất") {
                        performLogout()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red.opacity(0.4), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
    }
    
    private var isAuthenticationError: Bool {
        return errorMessage.lowercased().contains("đăng nhập") ||
               errorMessage.lowercased().contains("authentication") ||
               errorMessage.lowercased().contains("unauthorized") ||
               errorMessage.lowercased().contains("token")
    }

    // MARK: - Thêm function logout
    private func performLogout() {
        print("🚪 User requested logout from error screen")
        
        // Clear user data
        UserDefaults.standard.removeObject(forKey: Constants.Storage.isLoggedIn)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.userId)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.username)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.userToken)
        UserDefaults.standard.synchronize()
        
        // Reset view state
        selectedLevel = nil
        selectedCategory = nil
        categories = []
        errorMessage = ""
        
        // Notify app to show login screen
        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
    }

    // MARK: - Computed Properties
    private var headerTitle: String {
        if selectedCategory != nil {
            return ""
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
                    self.errorMessage = "Không thể tải danh sách chủ đề. Đăng nhập lại vợ nha."
                }
            }
        }
    }
}

// MARK: - Simple Level Card (Updated colors)
struct SimpleLevelCard: View {
    let level: JLPTLevel
    let onTap: () -> Void
    @State private var isHovered = false
    @State private var levelProgress: Double = 0.0 // Tiến độ thật từ API
    
    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(ScaleButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            loadLevelProgress()
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
                    .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.2))
                
                Text(level.description)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.3))
                    .multilineTextAlignment(.center)
                
                // Progress bar (mock)
                progressBar
            }
        }
        .padding(20)
        .frame(maxHeight: 200)
        .background(cardBackground)
    }
    
    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Tiến độ")
                    .font(.caption2)
                    .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.4))
                Spacer()
                Text("\(Int(levelProgress))%") // Sử dụng tiến độ thật
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.2))
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.8, green: 0.9, blue: 0.7))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(level.color)
                    .frame(width: calculateProgressWidth(), height: 6)
                    .animation(.easeInOut(duration: 0.5), value: levelProgress)
            }
        }
    }
    
    // Tính toán width của progress bar dựa trên tiến độ thật
    private func calculateProgressWidth() -> CGFloat {
        let maxWidth: CGFloat = 140 // Approximate card width - padding
        return maxWidth * CGFloat(levelProgress / 100.0)
    }
    
    // Load tiến độ thật cho level này
    private func loadLevelProgress() {
        // Tạm thời set mặc định, sẽ implement API sau
        levelProgress = 0.0
        
        // TODO: Implement API call
        // Task {
        //     do {
        //         let progress = try await APIService.shared.getLevelProgress(for: level)
        //         await MainActor.run {
        //             self.levelProgress = progress
        //         }
        //     } catch {
        //         print("❌ Error loading level progress: \(error)")
        //         await MainActor.run {
        //             self.levelProgress = 0.0
        //         }
        //     }
        // }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.8))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.6))
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
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Simple Category Card (Updated colors)
struct SimpleCategoryCard: View {
    let category: Category
    let onTap: () -> Void
    
    // Kiểm tra xem category có được unlock không
    private var isUnlocked: Bool {
        return category.isUnlocked
    }
    
    var body: some View {
        Button(action: {
            if isUnlocked {
                onTap()
            }
        }) {
            cardContent
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isUnlocked)
    }
    
    private var cardContent: some View {
        VStack(spacing: 16) {
            // Icon gradient circle
            gradientIconView

            // Info section
            VStack(spacing: 8) {
                Text(category.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(
                        isUnlocked ?
                        Color(red: 0.1, green: 0.4, blue: 0.2) :
                        Color(red: 0.4, green: 0.4, blue: 0.4)
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 40)

                wordsCountText

                if isUnlocked {
                    completionBadge(category.completionPercentage ?? 0.0)
                } else {
                    lockStatusBadge
                }
            }
            .frame(maxWidth: .infinity)

            Spacer() // đẩy nút xuống dưới cùng card

            // Action button: BẮT ĐẦU HỌC
            actionButton
                .padding(.bottom, 4)
        }
        .padding(20)
        .frame(height: 250)
        .background(categoryCardBackground)
        .opacity(isUnlocked ? 1.0 : 0.6)
        .scaleEffect(isUnlocked ? 1.0 : 0.95)
    }
    
    // ✨ NEW: Gradient Circle Icon View
    private var gradientIconView: some View {
        ZStack {
            // Glow background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            isUnlocked ? category.primaryColor.opacity(0.6) : Color.gray.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 35
                    )
                )
                .frame(width: 85, height: 85)
            
            // Main gradient circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: isUnlocked ? category.gradientColors : [Color.gray.opacity(0.6), Color.gray.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 70, height: 70)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .shadow(
                    color: isUnlocked ? category.primaryColor.opacity(0.4) : Color.gray.opacity(0.2),
                    radius: 8, x: 0, y: 4
                )
            
            // ✨ NEW: SF Symbol Icon (thay thế emoji)
            Image(systemName: category.sfSymbol)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .opacity(isUnlocked ? 1.0 : 0.5)
            
            // Lock overlay nếu chưa unlock
            if !isUnlocked {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .offset(x: 25, y: -25)
            }
        }
    }
    
    private var wordsCountText: some View {
        Text("\(category.totalWords) từ")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(
                isUnlocked ?
                Color(red: 0.2, green: 0.5, blue: 0.3) :
                Color(red: 0.5, green: 0.5, blue: 0.5)
            )
    }
    
    // Badge cho trạng thái khoá
    private var lockStatusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 8))
                .foregroundColor(.orange)
            
            Text("Chưa mở khóa")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.2))
        .clipShape(Capsule())
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
            Image(systemName: isUnlocked ? "play.fill" : "lock.fill")
                .font(.system(size: 10))
            Text(isUnlocked ? "Bắt đầu học" : "Cần mở khóa")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: isUnlocked ?
                [category.primaryColor, category.primaryColor.opacity(0.8)] :
                [Color.gray.opacity(0.6), Color.gray.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
        .shadow(
            color: isUnlocked ? category.primaryColor.opacity(0.4) : Color.gray.opacity(0.3),
            radius: 4, x: 0, y: 2
        )
    }
    
    private var categoryCardBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.white.opacity(0.9))
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                isUnlocked ? category.primaryColor.opacity(0.4) : Color.gray.opacity(0.3),
                                Color.clear,
                                isUnlocked ? category.primaryColor.opacity(0.2) : Color.gray.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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

// MARK: - Flashcard Study View (Updated background)
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
    @State private var showCompletionScreen = false  // ✨ NEW
    @State private var isUpdatingProgress = false    // ✨ NEW
    @State private var sessionStartTime = Date()     // ✨ NEW
    
    private let apiService = APIService.shared
    
    // Sample words for fallback
    private let sampleWords = [
        Word(id: 1, japaneseWord: "Chưa thêm dữ liệu", kanji: nil, romaji: "Vợ đợi anh thêm sau nhé", vietnameseMeaning: "Chưa thêm dữ liệu", exampleSentenceJp: "", exampleSentenceVn: "Vợ đợi anh thêm sau nhé"),
//        Word(id: 2, japaneseWord: "ありがとう", kanji: nil, romaji: "arigatou", vietnameseMeaning: "Cảm ơn", exampleSentenceJp: "ありがとうございます。", exampleSentenceVn: "Cảm ơn bạn."),
//        Word(id: 3, japaneseWord: "すみません", kanji: nil, romaji: "sumimasen", vietnameseMeaning: "Xin lỗi", exampleSentenceJp: "すみません、遅れました。", exampleSentenceVn: "Xin lỗi, tôi đến muộn."),
//        Word(id: 4, japaneseWord: "はじめまして", kanji: nil, romaji: "hajimemashite", vietnameseMeaning: "Rất vui được gặp bạn", exampleSentenceJp: "はじめまして、よろしくお願いします。", exampleSentenceVn: "Rất vui được gặp bạn, xin hãy giúp đỡ."),
//        Word(id: 5, japaneseWord: "さようなら", kanji: nil, romaji: "sayounara", vietnameseMeaning: "Tạm biệt", exampleSentenceJp: "さようなら、また明日。", exampleSentenceVn: "Tạm biệt, hẹn gặp lại ngày mai.")
    ]
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            if showCompletionScreen {
                // ✨ NEW: Completion Screen
                completionView
            } else {
                // Normal study view
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
                    if showControls && !words.isEmpty && !isSessionComplete {
                        controlsView
                    }
                    
                    Spacer(minLength: 50)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            sessionStartTime = Date()
            loadWords()
        }
    }
    // ✨ NEW: Completion Screen
    private var completionView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Celebration animation
            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 80))
                    .scaleEffect(isUpdatingProgress ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isUpdatingProgress)
                
                Text("Chúc mừng!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Bạn đã hoàn thành chủ đề")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(category.name)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(level.color)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                    )
            }
            
            // Stats
            VStack(spacing: 15) {
                HStack(spacing: 40) {
                    StatItem(icon: "book.fill", value: "\(words.count)", label: "Từ đã học")
                    StatItem(icon: "clock.fill", value: studyTimeString, label: "Thời gian")
                    StatItem(icon: "star.fill", value: "100%", label: "Hoàn thành")
                }
                
                if isUpdatingProgress {
                    HStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        
                        Text("Đang cập nhật tiến độ...")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 10)
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 15) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Hoàn thành")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(level.color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    restartSession()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Học lại")
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
        .background(backgroundView)
        .onAppear {
            saveCompletionProgress()
        }
    }    // ✨ NEW: Stat Item Component
    private func StatItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(level.color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    // ✨ NEW: Study time string
    private var studyTimeString: String {
         let timeInterval = Date().timeIntervalSince(sessionStartTime)
         let minutes = Int(timeInterval / 60)
         let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
         return String(format: "%d:%02d", minutes, seconds)
     }
     
     // ✨ NEW: Check if session is complete
     private var isSessionComplete: Bool {
         return currentIndex >= words.count && !words.isEmpty
     }
    
    // ✨ NEW: Save completion progress to server
    private func saveCompletionProgress() {
        isUpdatingProgress = true
        
        Task {
            do {
                let studyTime = Int(Date().timeIntervalSince(sessionStartTime))
                
                // Call API để cập nhật tiến độ
                try await apiService.updateCategoryProgress(
                    categoryId: category.id,
                    wordsLearned: words.count,
                    wordsMastered: words.count, // Assume all mastered khi hoàn thành
                    studyTime: studyTime,
                    isCompleted: true
                )
                
                // Unlock next category nếu có
                try await apiService.unlockNextCategory(completedCategoryId: category.id)
                
                print("✅ Progress saved successfully")
                
                // Show achievement
                await MainActor.run {
                    isUpdatingProgress = false
                    // Could add achievement notification here
                }
                
            } catch {
                print("❌ Failed to save progress: \(error)")
                await MainActor.run {
                    isUpdatingProgress = false
                    // Could show error message
                }
            }
        }
    }
    
    // ✨ NEW: Restart session
    private func restartSession() {
        withAnimation(.spring()) {
            currentIndex = 0
            isFlipped = false
            studiedCount = 0
            showCompletionScreen = false
            sessionStartTime = Date()
        }
    }
    // MARK: - Background (Updated to green theme)
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.906, green: 1.0, blue: 0.808),    // #E7FFCE
                Color(red: 0.85, green: 0.95, blue: 0.75),     // Slightly darker
                Color(red: 0.8, green: 0.9, blue: 0.7)        // Darker for depth
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header (Updated colors)
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.3))
                    .padding(12)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.2))
                
                Text("JLPT \(level.displayName)")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.3))
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    showControls.toggle()
                }
            }) {
                Image(systemName: showControls ? "eye.slash" : "eye")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.3))
                    .padding(12)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Progress (Updated colors)
    private var progressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Tiến độ: \(currentIndex + 1)/\(words.count)")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.3))
                
                Spacer()
                
                Text("Đã học: \(studiedCount)")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.3))
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.6))
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
            
            // Nội dung thẻ (front/back)
            if !isFlipped {
                frontSide(word: currentWord)
            } else {
                backSide(word: currentWord)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0)) // Lật lại chữ mặt sau
            }
        }
        .frame(width: UIScreen.main.bounds.width - 40, height: 300)
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0)) // Áp lên cả card
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
    private func flashcardBackground(colors: [Color]) -> some View {
        ZStack {
            // Gradient nhiều lớp cho chiều sâu
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 0.5)
            .opacity(0.92)
            
            // Glassmorphism - blur nhẹ trên cùng (tăng chiều sâu)
            Color.white.opacity(0.24)
                .blur(radius: 15)
            
            // Viền sáng, hiệu ứng border glow
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [
                            colors.first!.opacity(0.65),
                            .white.opacity(0.7),
                            colors.last!.opacity(0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .shadow(color: colors.last!.opacity(0.2), radius: 8, x: 0, y: 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
    private func frontSide(word: Word) -> some View {
        ZStack {
            flashcardBackground(colors: [
                Color(red: 0.7, green: 0.92, blue: 0.95),
                Color(red: 0.84, green: 1, blue: 0.84),
                Color(red: 0.95, green: 0.91, blue: 1.0)
            ])
            // Bạn có thể tuỳ chỉnh màu gradient tuỳ theo level nếu muốn

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
    }
    private func backSide(word: Word) -> some View {
        ZStack {
            flashcardBackground(colors: [
                Color(red: 1.0, green: 0.92, blue: 0.85),
                Color(red: 0.96, green: 0.97, blue: 1.0),
                Color(red: 0.85, green: 0.98, blue: 0.97)
            ])
            
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("🇻🇳")
                        .font(.system(size: 40))
                    
                    Text("Nghĩa tiếng Việt")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 16) {
                    Text(word.vietnameseMeaning)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
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
    }

    
    // MARK: - Controls (Updated colors)
    private var controlsView: some View {
        HStack(spacing: 20) {
            // Previous button
            Button(action: previousCard) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Trước")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.3))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.8))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
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
                .shadow(color: level.color.opacity(0.4), radius: 4, x: 0, y: 2)
            }
            
            // Next button
            Button(action: nextCard) {
                HStack {
                    Text("Sau")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.3))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.8))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            }
            .disabled(currentIndex >= words.count - 1)
            .opacity(currentIndex >= words.count - 1 ? 0.5 : 1.0)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Loading & Empty States (Updated colors)
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.2, green: 0.6, blue: 0.4)))
                .scaleEffect(1.5)
            
            Text("Đang tải từ vựng...")
                .font(.headline)
                .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.2))
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Text("📚")
                .font(.system(size: 60))
            
            Text("Không có từ vựng")
                .font(.headline)
                .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.2))
            
            Text("Chủ đề này chưa có từ vựng nào cho level \(level.displayName)")
                .font(.body)
                .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.3))
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
        guard currentIndex < words.count - 1 else {
            // ✨ Session completed!
            withAnimation(.spring()) {
                showCompletionScreen = true
            }
            return
        }
        
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

// MARK: - Extension Category
extension Category {
    var primaryColor: Color {
        // Parse category_color từ database hoặc fallback
        if !color.isEmpty {
            return Color(hex: color)
        }
        return defaultCategoryColor
    }
    
    var gradientColors: [Color] {
        let primary = primaryColor
        let darker = primary.opacity(0.8)
        return [primary, darker]
    }
    
    // ✨ NEW: SF Symbol mapping cho từng category
    var sfSymbol: String {
        switch name.lowercased() {
        case let x where x.contains("chào hỏi") || x.contains("giao tiếp"):
            return "bubble.left.and.bubble.right.fill"
        case let x where x.contains("gia đình") || x.contains("người thân"):
            return "figure.2.and.child.holdinghands"
        case let x where x.contains("màu sắc") || x.contains("hình dáng"):
            return "paintpalette.fill"
        case let x where x.contains("số đếm") || x.contains("đơn vị"):
            return "number.circle.fill"
        case let x where x.contains("cơ thể"):
            return "figure.arms.open"
        case let x where x.contains("nhà ở") || x.contains("đồ vật"):
            return "house.fill"
        case let x where x.contains("thời gian") || x.contains("ngày tháng"):
            return "clock.fill"
        case let x where x.contains("đồ ăn") || x.contains("thức uống"):
            return "fork.knife.circle.fill"
        case let x where x.contains("phương tiện") || x.contains("giao thông"):
            return "car.fill"
        case let x where x.contains("động vật"):
            return "pawprint.fill"
        case let x where x.contains("học tập") || x.contains("giáo dục"):
            return "graduationcap.fill"
        case let x where x.contains("công việc") || x.contains("nghề nghiệp"):
            return "briefcase.fill"
        case let x where x.contains("thể thao") || x.contains("giải trí"):
            return "sportscourt.fill"
        case let x where x.contains("du lịch") || x.contains("địa điểm"):
            return "location.fill"
        case let x where x.contains("mua sắm") || x.contains("tiền bạc"):
            return "creditcard.fill"
        case let x where x.contains("khẩn cấp") || x.contains("y tế"):
            return "cross.case.fill"
        case let x where x.contains("thời tiết") || x.contains("khí hậu"):
            return "cloud.sun.fill"
        case let x where x.contains("tin tức") || x.contains("truyền thông"):
            return "newspaper.fill"
        case let x where x.contains("công nghệ"):
            return "laptopcomputer"
        case let x where x.contains("tình cảm") || x.contains("cảm xúc"):
            return "heart.fill"
        default:
            return "book.fill" // Default fallback
        }
    }
    
    private var defaultCategoryColor: Color {
        // Fallback colors dựa trên category name
        switch name.lowercased() {
        case let x where x.contains("chào hỏi"):
            return Color(red: 1.0, green: 0.42, blue: 0.42) // #FF6B6B
        case let x where x.contains("gia đình"):
            return Color(red: 0.31, green: 0.8, blue: 0.77) // #4ECDC4
        case let x where x.contains("màu sắc"):
            return Color(red: 0.97, green: 0.45, blue: 0.5) // #F67280
        case let x where x.contains("số đếm"):
            return Color(red: 1.0, green: 0.71, blue: 0.47) // #FFB677
        case let x where x.contains("cơ thể"):
            return Color(red: 0.42, green: 0.36, blue: 0.48) // #6C5B7B
        case let x where x.contains("nhà ở"):
            return Color(red: 0.27, green: 0.72, blue: 0.82) // #45B7D1
        case let x where x.contains("thời gian"):
            return Color(red: 0.59, green: 0.81, blue: 0.71) // #96CEB4
        case let x where x.contains("đồ ăn"):
            return Color(red: 1.0, green: 0.92, blue: 0.65) // #FFEAA7
        case let x where x.contains("phương tiện"):
            return Color(red: 0.21, green: 0.36, blue: 0.49) // #355C7D
        case let x where x.contains("động vật"):
            return Color(red: 0.4, green: 0.8, blue: 0.4) // Green
        case let x where x.contains("học tập"):
            return Color(red: 0.2, green: 0.4, blue: 0.8) // Blue
        case let x where x.contains("công việc"):
            return Color(red: 0.5, green: 0.5, blue: 0.5) // Gray
        case let x where x.contains("thể thao"):
            return Color(red: 1.0, green: 0.5, blue: 0.0) // Orange
        case let x where x.contains("du lịch"):
            return Color(red: 0.0, green: 0.7, blue: 0.9) // Cyan
        case let x where x.contains("mua sắm"):
            return Color(red: 0.9, green: 0.7, blue: 0.0) // Gold
        case let x where x.contains("khẩn cấp"):
            return Color(red: 0.84, green: 0.19, blue: 0.19) // Red
        case let x where x.contains("thời tiết"):
            return Color(red: 0.0, green: 0.81, blue: 0.79) // Turquoise
        case let x where x.contains("tin tức"):
            return Color(red: 0.18, green: 0.20, blue: 0.21) // Dark
        case let x where x.contains("công nghệ"):
            return Color(red: 0.4, green: 0.4, blue: 0.9) // Purple
        case let x where x.contains("tình cảm"):
            return Color(red: 1.0, green: 0.2, blue: 0.4) // Pink
        default:
            return Color.blue
        }
    }
}


// MARK: - Preview
struct StudyView_Previews: PreviewProvider {
    static var previews: some View {
        StudyView()
    }
}
