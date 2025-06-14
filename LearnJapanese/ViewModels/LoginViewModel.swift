// ViewModels/LoginViewModel.swift
import Foundation
import SwiftUI

@MainActor
class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isLoggedIn = false
    
    private let apiService = APIService.shared
    
    init() {
        // Check if user is already logged in
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        let savedLoginStatus = UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn)
        print("🔍 LoginViewModel checkLoginStatus: \(savedLoginStatus)")
        isLoggedIn = savedLoginStatus
    }
    
    func login() async {
        guard !username.isEmpty && !password.isEmpty else {
            errorMessage = "Vui lòng nhập username và password"
            return
        }
        
        // ✨ TRÁNH DOUBLE CALL
        guard !isLoading else {
            print("⚠️ Login đang xử lý, bỏ qua request")
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            print("🚀 Đang gửi request login...")
            print("📤 Username: \(username)")
            
            let response = try await apiService.login(username: username, password: password)
            
            print("📥 Response nhận được:")
            print("✅ Success: \(response.success)")
            print("💬 Message: \(response.message ?? "nil")")
            print("👤 User: \(response.actualUser?.username ?? "nil")")
            print("🔑 Token: \(response.token ?? "nil")")
            
            if response.success {
                print("🎉 Login thành công!")
                
                // ✨ QUAN TRỌNG: Đảm bảo save vào UserDefaults TRƯỚC khi set isLoggedIn
                UserDefaults.standard.set(true, forKey: Constants.Storage.isLoggedIn)
                UserDefaults.standard.synchronize() // Force save ngay lập tức
                
                // Verify việc save
                let verified = UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn)
                print("✅ UserDefaults saved and verified: \(verified)")
                
                // ✨ FORCE UI UPDATE trên main thread
                await MainActor.run {
                    print("🔄 Setting isLoggedIn = true on main thread")
                    isLoggedIn = true
                    
                    // Clear form
                    username = ""
                    password = ""
                    
                    // ✨ THÊM: Force update binding sau một chút
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        print("🔄 Double-check isLoggedIn = \(self.isLoggedIn)")
                        if !self.isLoggedIn {
                            print("⚠️ isLoggedIn bị reset, setting lại")
                            self.isLoggedIn = true
                        }
                    }
                }
            } else {
                await MainActor.run {
                    errorMessage = response.message ?? "Đăng nhập thất bại"
                    print("❌ Login thất bại: \(errorMessage)")
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Lỗi kết nối: \(error.localizedDescription)"
                print("🚨 Lỗi: \(error)")
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func logout() {
        print("🚪 LoginViewModel logout() called")
        
        // Clear UserDefaults TRƯỚC
        UserDefaults.standard.removeObject(forKey: Constants.Storage.isLoggedIn)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.userId)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.username)
        UserDefaults.standard.removeObject(forKey: Constants.Storage.userToken)
        UserDefaults.standard.synchronize() // Force save
        
        // Verify việc xóa
        let verified = UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn)
        print("✅ UserDefaults cleared and verified: \(verified)")
        
        // Clear APIService
        apiService.logout()
        
        // Set isLoggedIn cuối cùng
        isLoggedIn = false
        
        // Clear form
        username = ""
        password = ""
        errorMessage = ""
    }
}
