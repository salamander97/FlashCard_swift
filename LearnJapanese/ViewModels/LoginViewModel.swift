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
        isLoggedIn = UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn)
    }
    
    func login() async {
        guard !username.isEmpty && !password.isEmpty else {
            errorMessage = "Vui lòng nhập username và password"
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
                isLoggedIn = true
                // Clear form
                username = ""
                password = ""
            } else {
                errorMessage = response.message ?? "Đăng nhập thất bại"
                print("❌ Login thất bại: \(errorMessage)")
            }
        } catch {
            errorMessage = "Lỗi kết nối: \(error.localizedDescription)"
            print("🚨 Lỗi: \(error)")
        }
        
        isLoading = false
    }
    
    func logout() {
        apiService.logout()
        isLoggedIn = false
        username = ""
        password = ""
        errorMessage = ""
    }
}
