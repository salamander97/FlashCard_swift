// Utils/Constants.swift

import Foundation
import SwiftUI

struct Constants {
    // MARK: - API Configuration
    struct API {
        static let baseURL = "https://trunghieu.tech/php"
        static let timeout: TimeInterval = 30
        
        struct Endpoints {
            static let auth = "/auth.php"
            static let vocabulary = "/vocabulary-api.php"
            static let progress = "/user-progress.php"
            static let dashboard = "/dashboard.php"
        }
    }
    
    // MARK: - App Colors
    struct Colors {
        static let primary = Color(hex: "#007AFF")        // Blue
        static let success = Color(hex: "#34C759")        // Green
        static let background = Color(hex: "#F2F2F7")     // Light Gray
        static let cardBackground = Color.white
        static let textPrimary = Color.black
        static let textSecondary = Color.gray
    }
    
    // MARK: - Storage Keys
    struct Storage {
        static let userToken = "user_token"
        static let userId = "user_id"
        static let username = "username"
        static let isLoggedIn = "is_logged_in"
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 8
        static let animationDuration: Double = 0.3
        static let cardPadding: CGFloat = 16
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
