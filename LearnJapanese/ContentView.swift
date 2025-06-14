// ContentView.swift - Smooth transition version
import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var showSplash = true // ✨ THÊM: Splash screen
    
    var body: some View {
        ZStack {
            if showSplash {
                // ✨ Simple splash screen while loading
                splashScreen
                    .transition(.opacity)
            } else {
                Group {
                    if isLoggedIn {
                        HomeView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        LoginView(isLoggedIn: $isLoggedIn)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
            }
        }
        .onAppear {
            // ✨ Delay initial check để UI render trước
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                checkInitialLoginState()
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
        .onChange(of: isLoggedIn) { newValue in
            print("🔄 ContentView onChange: isLoggedIn = \(newValue)")
            
            // ✨ Smooth animation với delay nhỏ
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                // Animation được handle bởi transition
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogout"))) { _ in
            print("📡 ContentView received logout notification")
            performLogout()
        }
    }
    
    // ✨ Simple splash screen
    private var splashScreen: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "667eea"),
                    Color(hex: "764ba2")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("愛")
                    .font(.system(size: 60, weight: .ultraLight))
                    .foregroundColor(.white)
                
                Text("Japanese FlashCard")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white.opacity(0.9))
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            }
        }
    }
    
    // ✨ Optimized initial state check
    private func checkInitialLoginState() {
        let savedLoginStatus = UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn)
        let savedUsername = UserDefaults.standard.string(forKey: Constants.Storage.username)
        
        print("📱 ContentView checkInitialLoginState:")
        print("   - isLoggedIn from UserDefaults: \(savedLoginStatus)")
        print("   - saved username: \(savedUsername ?? "nil")")
        
        if savedLoginStatus && savedUsername != nil {
            print("✅ User is logged in, showing HomeView")
            isLoggedIn = true
        } else {
            print("❌ User not logged in, showing LoginView")
            isLoggedIn = false
            clearCorruptData()
        }
    }
    
    private func clearCorruptData() {
        UserDefaults.standard.removeObject(forKey: Constants.Storage.isLoggedIn)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.userId)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.username)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.userToken)
    }
    
    private func performLogout() {
        print("🚪 ContentView performLogout() called")
        clearCorruptData()
        UserDefaults.standard.synchronize()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isLoggedIn = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
