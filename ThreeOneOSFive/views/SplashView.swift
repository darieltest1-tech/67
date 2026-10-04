import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void
    
    @State private var rotationAngle: Double = 0
    @State private var progress: CGFloat = 0
    @State private var currentStepIndex = 0
    @State private var appeared = false
    @State private var glowPulse = false
    
    private let steps: [String] = [
        "INITIALIZING SYSTEM",
        "LOADING USER DATA",
        "VERIFYING ACCESS",
        "PREPARING DARIELMODZ",
        "SYSTEM READY"
    ]
    
    private let appName = "DARIELMODZ"
    
    var body: some View {
        ZStack {
            background
            
            VStack(spacing: 0) {
                Spacer()
                
                logoSection
                
                Spacer().frame(height: 60)
                
                Text(appName)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(white: 0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .white.opacity(0.3), radius: 10)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
                
                Spacer().frame(height: 20)
                
                Text(steps[currentStepIndex])
                    .font(.system(size: 11, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(Color.white.opacity(0.75))
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: currentStepIndex)
                    .opacity(appeared ? 1 : 0)
                
                Spacer().frame(height: 14)
                
                progressBar
                    .padding(.horizontal, 80)
                    .opacity(appeared ? 1 : 0)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Background
    
    private var background: some View {
        ZStack {
            // Fondo negro puro
            Color.black
                .ignoresSafeArea()
            
            // Glow radial blanco sutil detrás del logo
            RadialGradient(
                colors: [
                    Color.white.opacity(glowPulse ? 0.15 : 0.05),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.45),
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        ZStack {
            // Halo blanco pulsante
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(glowPulse ? 0.25 : 0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 120
                    )
                )
                .frame(width: 260, height: 260)
            
            // Anillo de puntos girando
            ForEach(0..<28, id: \.self) { i in
                let angle = (Double(i) / 28.0) * 360.0
                let isHighlighted = i % 7 == 0
                
                Circle()
                    .fill(
                        isHighlighted
                            ? Color.white.opacity(0.95)
                            : Color.white.opacity(0.35)
                    )
                    .frame(
                        width: isHighlighted ? 4 : 2.5,
                        height: isHighlighted ? 4 : 2.5
                    )
                    .shadow(
                        color: isHighlighted ? .white.opacity(0.8) : .clear,
                        radius: isHighlighted ? 4 : 0
                    )
                    .offset(y: -95)
                    .rotationEffect(.degrees(angle + rotationAngle))
            }
            
            // Anillo conector
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(rotationAngle * 0.5))
            
            // Círculo con gradiente blanco
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 120, height: 120)
                .shadow(color: .white.opacity(0.5), radius: 15)
            
            // Círculo decorativo interior
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                .frame(width: 140, height: 140)
            
            // Logo
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
                .shadow(color: .white.opacity(0.4), radius: 12)
        }
        .frame(height: 260)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9)
        .animation(.easeOut(duration: 0.6), value: appeared)
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.08))
                .frame(height: 4)
            
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white,
                            Color.white.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: progress * 220, height: 4)
                .shadow(color: .white.opacity(0.8), radius: 6)
        }
        .frame(width: 220)
    }
    
    // MARK: - Animaciones
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.4)) {
            appeared = true
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
        
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        animateProgress()
    }
    
    private func animateProgress() {
        let stepDuration: Double = 0.9
        let totalDuration = stepDuration * Double(steps.count)
        
        withAnimation(.linear(duration: totalDuration)) {
            progress = 1.0
        }
        
        for (index, _) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(index)) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStepIndex = index
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.3) {
            onFinished()
        }
    }
}
