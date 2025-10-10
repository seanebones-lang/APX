//
//  ParticleEffect.swift
//  MacCleaner
//
//  Particle system for cleaning animations
//

import SwiftUI

struct ParticleEffect: View {
    let particleCount: Int
    let colors: [Color]
    
    @State private var particles: [Particle] = []
    
    init(particleCount: Int = 30, colors: [Color] = [.purple, .blue, .pink]) {
        self.particleCount = particleCount
        self.colors = colors
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .blur(radius: particle.blur)
                }
            }
            .onAppear {
                initializeParticles(in: geometry.size)
                startAnimation()
            }
        }
    }
    
    private func initializeParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 4...12),
                opacity: Double.random(in: 0.3...0.8),
                blur: CGFloat.random(in: 0...2)
            )
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for index in particles.indices {
                // Update particle position
                var particle = particles[index]
                particle.position.y -= 2
                particle.opacity -= 0.01
                
                // Reset particle if it goes off screen
                if particle.position.y < -10 || particle.opacity <= 0 {
                    particle.position.y = UIScreen.main.bounds.height + 10
                    particle.position.x = CGFloat.random(in: 0...UIScreen.main.bounds.width)
                    particle.opacity = Double.random(in: 0.3...0.8)
                }
                
                particles[index] = particle
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
    let blur: CGFloat
}

struct ParticleEffect_Previews: PreviewProvider {
    static var previews: some View {
        ParticleEffect()
            .frame(width: 400, height: 400)
            .background(Color.black)
    }
}

