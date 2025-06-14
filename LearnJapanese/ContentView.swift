// ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false
    
    var body: some View {
        Group {
            if isLoggedIn {
                HomeView()
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
        .onAppear {
            // Check if user is already logged in
            let loggedIn = UserDefaults.standard.bool(forKey: Constants.Storage.isLoggedIn)
            print("📱 ContentView onAppear: isLoggedIn = \(loggedIn)")
            isLoggedIn = loggedIn
        }
        .onChange(of: isLoggedIn) { newValue in
            print("🔄 ContentView onChange: isLoggedIn = \(newValue)")
            if newValue {
                print("🏠 Switching to HomeView...")
            } else {
                print("🔐 Switching to LoginView...")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogout"))) { _ in
            print("📡 Received logout notification")
            print("🔄 Current isLoggedIn: \(isLoggedIn)")
            
            // Only change if currently logged in to avoid multiple calls
            if isLoggedIn {
                withAnimation(.spring()) {
                    print("🔄 Setting isLoggedIn = false")
                    isLoggedIn = false
                }
            } else {
                print("⚠️ Already logged out, ignoring notification")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
