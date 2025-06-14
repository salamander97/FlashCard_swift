// Views/Authentication/LoginView.swift
import SwiftUI

struct LoginView: View {
    @StateObject private var loginViewModel = LoginViewModel()
    @Binding var isLoggedIn: Bool
    @State private var showPassword = false
    @State private var animateBackground = false
    @State private var animateCards = false
    @State private var currentCardIndex = 0
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var charPositions: [(x: CGFloat, y: CGFloat)] = []
    @State private var charSizes: [CGFloat] = []
    @State private var isPositionsInitialized = false

    // Japanese characters for background animation
    let japaneseChars = ["Phương Thảo", "xinh gái","🥰","đáng yêu","Vợ yêu"]
    
    var body: some View {
         GeometryReader { geometry in
             ZStack {
                 // Animated Background
                 backgroundView(geometry: geometry)
                 
                 // Floating Japanese Characters
                 floatingCharacters(geometry: geometry)
                 
                 // Main Content with keyboard handling
                 ScrollView(showsIndicators: false) {
                     VStack(spacing: 0) {
                         // Top spacing adjusts based on keyboard
                         Spacer(minLength: keyboardHeight > 0 ? 20 : 80)
                         
                         // App Branding Section - hide when keyboard is up
                         if keyboardHeight == 0 {
                             brandingSection
                                 .transition(.asymmetric(
                                     insertion: .move(edge: .top).combined(with: .opacity),
                                     removal: .move(edge: .top).combined(with: .opacity)
                                 ))
                         }
                         
                         // Login Form with Glassmorphism
                         loginFormSection
                         
                         // Bottom spacing adjusts based on keyboard
                         Spacer(minLength: keyboardHeight > 0 ? 20 : 60)
                     }
                 }
                 .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
             }
         }
         .navigationBarHidden(true)
         .onAppear {
             startAnimations()
             setupKeyboardObservers()
         }
         .onDisappear {
             removeKeyboardObservers()
         }
         // ✨ SIMPLIFIED: Chỉ một listener duy nhất
         .onChange(of: loginViewModel.isLoggedIn) { newValue in
             print("🔄 LoginView onChange: loginViewModel.isLoggedIn = \(newValue)")
             
             if newValue {
                 print("🎉 Login successful! Updating parent binding...")
                 // ✨ SIMPLE & DIRECT
                 isLoggedIn = true
                 print("✅ Parent isLoggedIn set to: \(isLoggedIn)")
             }
         }
         // ✨ XÓA: Tất cả UserDefaults listeners khác
         // ✨ XÓA: onReceive UserDefaults.didChangeNotification
         // ✨ GIỮ: Chỉ logout notification
         .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogout"))) { _ in
             print("📡 LoginView received logout notification")
             loginViewModel.isLoggedIn = false
             isLoggedIn = false
         }
     }
    private func initializeCharPositions(geometry: GeometryProxy) {
         guard !isPositionsInitialized else { return }
         
         print("🎯 Initializing char positions - ONE TIME ONLY")
         
         // Tạo vị trí random một lần
         charPositions = (0..<8).map { _ in
             (
                 x: CGFloat.random(in: 0...geometry.size.width),
                 y: CGFloat.random(in: 0...geometry.size.height)
             )
         }
         
         // Tạo size random một lần
         charSizes = (0..<8).map { index in
             CGFloat(40 + index * 10)
         }
         
         isPositionsInitialized = true
         print("✅ Char positions initialized: \(charPositions.count)")
     }
     
     // ✨ THÊM: Get vị trí ổn định cho mỗi character
     private func getCharPosition(index: Int, geometry: GeometryProxy) -> CGPoint {
         guard index < charPositions.count else {
             // Fallback nếu chưa khởi tạo
             return CGPoint(x: 100, y: 100)
         }
         
         return CGPoint(
             x: charPositions[index].x,
             y: charPositions[index].y
         )
     }
     
     // ✨ THÊM: Get size ổn định cho mỗi character
     private func getCharSize(index: Int) -> CGFloat {
         guard index < charSizes.count else {
             return 40 + CGFloat(index * 10) // Fallback
         }
         
         return charSizes[index]
     }
    
    // MARK: - Background View
    private func backgroundView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color(red: 0.2, green: 0.1, blue: 0.4),
                    Color(red: 0.4, green: 0.2, blue: 0.6),
                    Color(red: 0.6, green: 0.3, blue: 0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated wave layers
            ForEach(0..<3, id: \.self) { index in
                Wave(
                    animateBackground: animateBackground,
                    amplitude: 20 + CGFloat(index * 10),
                    frequency: 1.5 + Double(index) * 0.5,
                    phase: Double(index) * .pi / 3
                )
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.1 - Double(index) * 0.02),
                            Color.cyan.opacity(0.05 - Double(index) * 0.01)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(y: CGFloat(index * 50))
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Floating Characters
    private func floatingCharacters(geometry: GeometryProxy) -> some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                let char = japaneseChars[index % japaneseChars.count]
                
                Text(char)
                    .font(getBeautifulFont(for: char, index: index))
                    .foregroundStyle(getGradientForChar(char))
                    .position(getCharPosition(index: index, geometry: geometry))
                    .rotation3DEffect(
                        .degrees(animateBackground ? 360 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .scaleEffect(animateBackground ? 1.2 : 0.8)
                    .shadow(
                        color: getShadowColorForChar(char),
                        radius: 10,
                        x: 0,
                        y: 0
                    )
                    .animation(
                        .easeInOut(duration: 4 + Double(index))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.5),
                        value: animateBackground
                    )
            }
        }
        .onAppear {
            print("✅ Using working fonts: Alex Brush & Dancing Script")
            initializeCharPositions(geometry: geometry)
        }
    }

    // ✨ THÊM: Mix fonts đẹp mắt
    private func getBeautifulFont(for char: String, index: Int) -> Font {
        let size = getCharSize(index: index)
        
        switch char {
        case "Phương Thảo":
            // Font cursive đẹp cho tên vợ
            return .custom("AlexBrush-Regular", size: size + 8)
        case "xinh gái":
            // Font dancing script cho "xinh gái"
            return .custom("DancingScript-Medium", size: size + 4)
        case "😍":
            // Emoji giữ system font
            return .system(size: size + 3, weight: .bold, design: .rounded)
        case "yêu vợ":
            // Font đậm cho "yêu vợ"
            return .custom("DancingScript-Bold", size: size + 10)
        default:
            // Default dancing script
            return .custom("DancingScript-Regular", size: size)
        }
    }

    // ✨ THÊM: Gradient đẹp cho từng text
    private func getGradientForChar(_ char: String) -> LinearGradient {
        switch char {
        case "Phương Thảo":
            return LinearGradient(
                colors: [.pink.opacity(0.25), .purple.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "xinh gái":
            return LinearGradient(
                colors: [.cyan.opacity(0.2), .blue.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
        case "😍":
            return LinearGradient(
                colors: [.red.opacity(0.25), .pink.opacity(0.15)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case "yêu vợ":
            return LinearGradient(
                colors: [.yellow.opacity(0.2), .orange.opacity(0.12)],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        default:
            return LinearGradient(
                colors: [.white.opacity(0.12), .white.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // ✨ THÊM: Shadow colors
    private func getShadowColorForChar(_ char: String) -> Color {
        switch char {
        case "Phương Thảo": return .pink.opacity(0.4)
        case "xinh gái": return .cyan.opacity(0.4)
        case "😍": return .red.opacity(0.5)
        case "yêu vợ": return .yellow.opacity(0.4)
        default: return .white.opacity(0.3)
        }
    }
    
    // MARK: - Branding Section
    private var brandingSection: some View {
        VStack(spacing: 25) {
            // Logo with particle effect
            ZStack {
                // Particle rings
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(
                            Color.white.opacity(0.2),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 10])
                        )
                        .frame(width: 100 + CGFloat(ring * 30))
                        .rotationEffect(.degrees(animateBackground ? 360 : 0))
                        .animation(
                            .linear(duration: 10 + Double(ring * 2))
                            .repeatForever(autoreverses: false),
                            value: animateBackground
                        )
                }
                
                // Main logo
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.3),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 5,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateBackground ? 1.2 : 1.0)
                    
                    // Logo symbol
                    Text("愛")
                        .font(.custom("KaiseiDecol-Regular",size: 80))

                        .foregroundColor(.white)
                        .shadow(color: .cyan, radius: 10)
                }
            }
            .scaleEffect(loginViewModel.isLoading ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: loginViewModel.isLoading)
            
            // App title with typewriter effect
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("Japanese")
                        .font(.system(size: 36, weight: .ultraLight, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("FlashCard")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.cyan, Color.pink]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                

            }
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Login Form Section
    private var loginFormSection: some View {
        VStack(spacing: 30) {
            // Glassmorphism card
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 12) {
                    Text("Hế lô vợ yêu 💞")
                        .font(.custom("Cabin",size: 28))
                        .foregroundColor(.white)
                    
                    Text("Bắt đầu học thôi nào vợ yêuuu 😘")
                        .font(.custom("Cabin",size: 18))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Input fields with floating labels
                VStack(spacing: 20) {
                    // Username field
                    FloatingLabelTextField(
                        text: $loginViewModel.username,
                        placeholder: "Tên đăng nhập",
                        icon: "person.circle.fill"
                    )
                    
                    // Password field
                    FloatingLabelSecureField(
                        text: $loginViewModel.password,
                        placeholder: "Mật khẩu",
                        icon: "lock.circle.fill",
                        showPassword: $showPassword
                    )
                }
                
                // Error message with slide animation
                if !loginViewModel.errorMessage.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(loginViewModel.errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.15))
                            .background(Color.black.opacity(0.2))
                    )
                    .transition(.asymmetric(
                        insertion: .slide.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
                
                // Login button with morphing animation
                Button(action: {
                    Task {
                        await loginViewModel.login()
                    }
                }) {
                    ZStack {
                        // Background morphing shape
                        RoundedRectangle(cornerRadius: loginViewModel.isLoading ? 25 : 15)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.cyan,
                                        Color.blue,
                                        Color.purple
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(
                                width: loginViewModel.isLoading ? 50 : nil,
                                height: 50
                            )
                            .shadow(color: .cyan.opacity(0.5), radius: 15, x: 0, y: 5)
                        
                        // Content
                        if loginViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                                Text("Đăng Nhập")
                                    .font(.custom("Huninn-Regular", size: 20))
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: loginViewModel.isLoading ? 50 : .infinity)
                }
                .disabled(loginViewModel.isLoading)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: loginViewModel.isLoading)
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 35)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.3))
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.1))
                    )
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.clear,
                                Color.white.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .padding(.horizontal, 20)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Animations
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            animateBackground = true
        }
        
        withAnimation(.easeOut(duration: 1).delay(0.5)) {
            animateCards = true
        }
    }
}

// MARK: - Custom Wave Shape
struct Wave: Shape {
    var animateBackground: Bool
    var amplitude: CGFloat
    var frequency: Double
    var phase: Double
    
    var animatableData: Double {
        get { phase }
        set { self.phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let y = sin((relativeX * frequency * 2 * .pi) + phase) * amplitude + midHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Floating Label TextField
struct FloatingLabelTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Floating label
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.cyan)
                    .font(.title3)
                
                Text(placeholder)
                    .font(.system(size: isEditing || !text.isEmpty ? 12 : 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .animation(.easeInOut(duration: 0.2), value: isEditing || !text.isEmpty)
            }
            
            // Text field
            TextField("", text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isFocused)
                .onTapGesture {
                    isEditing = true
                    isFocused = true
                }
                .onSubmit {
                    isEditing = false
                    isFocused = false
                }
                .onChange(of: isFocused) { focused in
                    isEditing = focused
                }
            
            // Bottom line
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            isEditing ? .cyan : .white.opacity(0.3),
                            isEditing ? .blue : .white.opacity(0.1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: isEditing ? 2 : 1)
                .animation(.easeInOut(duration: 0.3), value: isEditing)
        }
    }
}

// MARK: - Floating Label Secure Field
struct FloatingLabelSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @Binding var showPassword: Bool
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Floating label
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text(placeholder)
                    .font(.system(size: isEditing || !text.isEmpty ? 12 : 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .animation(.easeInOut(duration: 0.2), value: isEditing || !text.isEmpty)
                
                Spacer()
                
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.title3)
                }
            }
            
            // Text/Secure field
            Group {
                if showPassword {
                    TextField("", text: $text)
                } else {
                    SecureField("", text: $text)
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .focused($isFocused)
            .onTapGesture {
                isEditing = true
                isFocused = true
            }
            .onSubmit {
                isEditing = false
                isFocused = false
            }
            .onChange(of: isFocused) { focused in
                isEditing = focused
            }
            
            // Bottom line
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            isEditing ? .purple : .white.opacity(0.3),
                            isEditing ? .pink : .white.opacity(0.1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: isEditing ? 2 : 1)
                .animation(.easeInOut(duration: 0.3), value: isEditing)
        }
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))
            .previewDevice("iPhone 15 Pro")
    }
}
