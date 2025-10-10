//
//  AnimatedProgressRing.swift
//  MacCleaner
//
//  Beautiful circular progress indicator with gradient
//

import SwiftUI

struct AnimatedProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let colors: [Color]
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        size: CGFloat = 280,
        colors: [Color] = [.purple, .blue]
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.colors = colors
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animatedProgress)
            
            // Animated gradient overlay
            if animatedProgress > 0 {
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        AngularGradient(
                            colors: colors + [colors.first!],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth / 2, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .opacity(0.5)
                    .blur(radius: 2)
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
    }
}

struct AnimatedProgressRing_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            AnimatedProgressRing(progress: 0.3)
            AnimatedProgressRing(progress: 0.7)
            AnimatedProgressRing(progress: 1.0)
        }
        .padding(40)
    }
}

