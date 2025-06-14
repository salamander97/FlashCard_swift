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
    
    // Japanese characters for background animation
    let japaneseChars = ["Phương Thảo", "xinh gái","😍", "yêu vợ"]
    
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
        .onChange(of: loginViewModel.isLoggedIn) { newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                isLoggedIn = newValue
            }
        }
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
                Text(japaneseChars[index % japaneseChars.count])
                    .font(.system(size: 40 + CGFloat(index * 10), weight: .thin))
                    .foregroundColor(.white.opacity(0.1))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .rotation3DEffect(
                        .degrees(animateBackground ? 360 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .scaleEffect(animateBackground ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 4 + Double(index))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.5),
                        value: animateBackground
                    )
            }
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
                        .font(.system(size: 45, weight: .ultraLight))
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
                    Text("Hế lô vợ yêu<3")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Bắt đầu học thôi nào vợ yêuuu😘")
                        .font(.system(size: 15))
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
                                Text("Sign In")
                                    .font(.system(size: 16, weight: .semibold))
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
