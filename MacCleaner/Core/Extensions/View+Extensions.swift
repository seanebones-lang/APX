//
//  View+Extensions.swift
//  MacCleaner
//

import SwiftUI

extension View {
    /// Apply a subtle bounce animation
    func bounceEffect(isTriggered: Bool) -> some View {
        self.scaleEffect(isTriggered ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isTriggered)
    }
    
    /// Apply a shake animation
    func shake(isShaking: Bool) -> some View {
        self.modifier(ShakeEffect(shakes: isShaking ? 2 : 0))
    }
    
    /// Apply a pulsing glow effect
    func glowEffect(color: Color, intensity: CGFloat = 0.5) -> some View {
        self.shadow(color: color.opacity(intensity), radius: 10)
            .shadow(color: color.opacity(intensity * 0.5), radius: 20)
    }
    
    /// Conditional modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: 10 * sin(shakes * 2 * .pi), y: 0)
        )
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

