//
//  Color+Extensions.swift
//  MacCleaner
//

import SwiftUI

extension Color {
    // CleanMyMac-inspired color palette
    static let primaryPurple = Color(red: 139/255, green: 92/255, blue: 246/255)
    static let primaryBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    static let successGreen = Color(red: 16/255, green: 185/255, blue: 129/255)
    static let warningOrange = Color(red: 245/255, green: 158/255, blue: 11/255)
    static let dangerRed = Color(red: 239/255, green: 68/255, blue: 68/255)
    
    // Gradient presets
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primaryPurple, primaryBlue],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var successGradient: LinearGradient {
        LinearGradient(
            colors: [Color.green, successGreen],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var dangerGradient: LinearGradient {
        LinearGradient(
            colors: [dangerRed, Color.orange],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
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
            (a, r, g, b) = (255, 0, 0, 0)
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

