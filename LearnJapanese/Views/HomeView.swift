// Views/HomeView.swift
import SwiftUI

struct HomeView: View {
    @State private var showingStudy = false
    @State private var showingQuiz = false
    @State private var showingProgress = false
    @State private var animateBackground = false
    @State private var animateCards = false
    @State private var selectedCard = -1
    @State private var showProfile = false
    @State private var floatingOffset: CGFloat = 0
    @State private var particlesOpacity: Double = 0
    @State private var showImagePicker = false
    @State private var profileImage: UIImage?
    
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic Animated Background
                dynamicBackground
                
                // Floating Particles
                floatingParticles
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 25) {
                        // Dynamic Header
                        dynamicHeader
                            .padding(.top, 20)
                        
                        // Stats Cards Row
                        statsCardsRow
                            .padding(.horizontal, 20)
                        
                        // Main Action Cards
                        mainActionCards
                            .padding(.horizontal, 20)
                        
                        // Quick Actions
                        quickActionsSection
                            .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Profile Panel Overlay
                if showProfile {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showProfile = false
                            }
                        }
                    
                    profilePanel
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startAnimations()
        }
        .sheet(isPresented: $showingStudy) {
            StudyView()
        }
        .sheet(isPresented: $showingQuiz) {
            QuizView()
        }
        .sheet(isPresented: $showingProgress) {
            ProgressDetailView()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $profileImage)
        }
    }
    
    // MARK: - Profile Panel
    private var profilePanel: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 25) {
                // Handle bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 6)
                    .padding(.top, 12)
                
                // Profile Image Section
                VStack(spacing: 15) {
                    ZStack {
                        // Profile Image Background
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 4)
                            )
                        
                        // Profile Image
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        // Camera button
                        Button(action: {
                            showImagePicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: .black.opacity(0.2), radius: 4)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "667eea"))
                            }
                        }
                        .offset(x: 35, y: 35)
                    }
                    
                    // User Info
                    VStack(spacing: 8) {
                        if let username = UserDefaults.standard.string(forKey: Constants.Storage.username) {
                            Text(username)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Học viên tiếng Nhật")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Stats row
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text("142")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Từ đã học")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 1, height: 30)
                            
                            VStack(spacing: 4) {
                                Text("7")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Ngày streak")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 1, height: 30)
                            
                            VStack(spacing: 4) {
                                Text("89%")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Độ chính xác")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
                
                // Menu Options
                VStack(spacing: 12) {
                    ProfileMenuItem(
                        icon: "person.fill",
                        title: "Chỉnh sửa hồ sơ",
                        action: {}
                    )
                    
                    ProfileMenuItem(
                        icon: "gear",
                        title: "Cài đặt",
                        action: {}
                    )
                    
                    ProfileMenuItem(
                        icon: "questionmark.circle",
                        title: "Trợ giúp",
                        action: {}
                    )
                    
                    ProfileMenuItem(
                        icon: "star.fill",
                        title: "Đánh giá ứng dụng",
                        action: {}
                    )
                }
                
                // Logout Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showProfile = false
                    }
                    
                    // Delay logout để animation hoàn thành
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        performLogout()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.square")
                            .font(.system(size: 18))
                        
                        Text("Đăng xuất")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.red.opacity(0.6), lineWidth: 1)
                            )
                    )
                }
                .padding(.top, 10)
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 25)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "667eea").opacity(0.95),
                        Color(hex: "764ba2").opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.1))
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: -5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Dynamic Background
    private var dynamicBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "667eea"),
                    Color(hex: "764ba2"),
                    Color(hex: "f093fb"),
                    Color(hex: "f5576c")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated overlay circles
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -300...300)
                    )
                    .scaleEffect(animateBackground ? 1.5 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...6))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.5),
                        value: animateBackground
                    )
            }
        }
    }
    
    // MARK: - Floating Particles
    private var floatingParticles: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: CGFloat.random(in: 2...6))
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: floatingOffset + CGFloat(index * 50)
                    )
                    .opacity(particlesOpacity)
                    .animation(
                        Animation.linear(duration: Double.random(in: 8...15))
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.2),
                        value: floatingOffset
                    )
            }
        }
        .onReceive(timer) { _ in
            if floatingOffset == 0 {
                floatingOffset = -800
                particlesOpacity = 1.0
            }
        }
    }
    
    // MARK: - Dynamic Header
    private var dynamicHeader: some View {
        VStack(spacing: 20) {
            // Profile Section
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("おかえりなさい! 🌸")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    if let username = UserDefaults.standard.string(forKey: Constants.Storage.username) {
                        Text(username)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Xin chào vợ yêuuu😍")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Profile Avatar with notification
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showProfile = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 55, height: 55)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            )
                        
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 55, height: 55)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                        
                        // Notification badge
                        Circle()
                            .fill(Color.red)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text("3")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 20, y: -20)
                    }
                }
                .scaleEffect(animateCards ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateCards)
            }
            .padding(.horizontal, 25)
            
            // Streak indicator
            streakIndicator
                .padding(.horizontal, 25)
        }
    }
    
    // MARK: - Streak Indicator
    private var streakIndicator: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)
                .scaleEffect(animateCards ? 1.2 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: animateCards
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("7 ngày Thử thách!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Tiếp tục phát huy vợ nhé!! 🎯")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text("🎉")
                .font(.system(size: 24))
                .rotationEffect(.degrees(animateCards ? 15 : -15))
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                    value: animateCards
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .blur(radius: 0.5)
        )
    }
    
    // MARK: - Stats Cards Row
    private var statsCardsRow: some View {
        HStack(spacing: 15) {
            StatMiniCard(
                icon: "brain.head.profile",
                value: "142",
                label: "Từ vựng\nđã học",
                color: Color.blue,
                index: 0
            )
            
            StatMiniCard(
                icon: "target",
                value: "89%",
                label: "Độ chính xác\nBài quiz",
                color: Color.green,
                index: 1
            )
            
            StatMiniCard(
                icon: "clock.fill",
                value: "2.5h",
                label: "Thời gian\nhọc tập",
                color: Color.purple,
                index: 2
            )
        }
    }
    
    // MARK: - Main Action Cards
    private var mainActionCards: some View {
        VStack(spacing: 20) {
            // Study Card - Featured
            FeaturedActionCard(
                icon: "graduationcap.fill",
                title: "Tiếp tục học tập",
                subtitle: "15 từ vựng đang chờ ôn tập",
                progress: 0.65,
                gradient: [Color(hex: "667eea"), Color(hex: "764ba2")],
                action: { showingStudy = true },
                index: 0
            )
            
            // Two smaller cards
            HStack(spacing: 15) {
                ActionCard(
                    icon: "brain.head.profile",
                    title: "Làm bài quiz",
                    subtitle: "Kiểm tra kiến thức",
                    gradient: [Color(hex: "11998e"), Color(hex: "38ef7d")],
                    action: { showingQuiz = true },
                    index: 1
                )
                
                ActionCard(
                    icon: "chart.bar.fill",
                    title: "Tiến độ",
                    subtitle: "Xem thống kê",
                    gradient: [Color(hex: "fc466b"), Color(hex: "3f5efb")],
                    action: { showingProgress = true },
                    index: 2
                )
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Thao tác nhanh")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 5)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                QuickActionButton(icon: "bookmark.fill", title: "Đánh dấu", color: Color.orange)
                QuickActionButton(icon: "heart.fill", title: "Yêu thích", color: Color.pink)
                QuickActionButton(icon: "trophy.fill", title: "Thành tích", color: Color.yellow)
                QuickActionButton(icon: "gear", title: "Cài đặt", color: Color.gray)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func performLogout() {
        print("🚪 Đăng xuất...")
        
        // Clear user data and logout
        UserDefaults.standard.removeObject(forKey: Constants.Storage.isLoggedIn)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.userId)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.username)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.userToken)
        
        print("🗑️ Đã xóa dữ liệu người dùng")
        print("📤 Gửi thông báo đăng xuất...")
        
        // This will trigger ContentView to show LoginView
        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
        
        print("✅ Đã gửi thông báo đăng xuất")
    }
    
    // MARK: - Animation Functions
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.8)) {
            animateCards = true
        }
        
        withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
            animateBackground = true
        }
    }
}

// MARK: - Profile Menu Item Component
struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isPressed ? 0.2 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Stat Mini Card Component
struct StatMiniCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let index: Int
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            .scaleEffect(animate ? 1.1 : 1.0)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.3),
                value: animate
            )
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Featured Action Card
struct FeaturedActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let progress: Double
    let gradient: [Color]
    let action: () -> Void
    let index: Int
    @State private var animateProgress = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .offset(x: isPressed ? 5 : 0)
                        .animation(.easeInOut(duration: 0.2), value: isPressed)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Progress bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Tiến độ")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .frame(width: animateProgress ? CGFloat(progress) * 200 : 0, height: 6)
                            .animation(.easeInOut(duration: 1.5).delay(0.5), value: animateProgress)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: gradient[0].opacity(0.3), radius: 10, x: 0, y: 5)
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            animateProgress = true
        }
    }
}

// MARK: - Action Card Component
struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void
    let index: Int
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding(18)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: gradient[0].opacity(0.2), radius: 8, x: 0, y: 4)
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

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
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
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Temporary Views
struct StudyView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("📚 Màn hình học tập")
                    .font(.largeTitle)
                Text("Đang phát triển...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Học tập")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct QuizView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("🧠 Màn hình Quiz")
                    .font(.largeTitle)
                Text("Đang phát triển...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ProgressDetailView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("📊 Màn hình Tiến độ")
                    .font(.largeTitle)
                Text("Đang phát triển...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Tiến độ")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
