//
//  AmbientHubBackground.swift
//  UtilityHub
//
//  Created by Claude on 13/04/26.
//

import SwiftUI

struct AmbientHubBackground: View {
    @State private var phase1 = false
    @State private var phase2 = false
    @State private var phase3 = false
    @State private var phase4 = false

    private var accent: AppAccent { AppAccent.current }
    private var secondaryColor: Color { accent.gradientColors.last ?? accent.tintColor }

    var body: some View {
        ZStack {
            // Base gradient — slow diagonal sweep
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.09),
                    accent.tintColor.opacity(phase1 ? 0.18 : 0.10),
                    Color(red: 0.04, green: 0.05, blue: 0.09)
                ],
                startPoint: phase1 ? .topLeading : .topTrailing,
                endPoint: phase1 ? .bottomTrailing : .bottomLeading
            )
            .ignoresSafeArea()

            // Primary accent orb — drifts across the top
            Circle()
                .fill(accent.tintColor.opacity(0.38))
                .frame(width: 320, height: 320)
                .blur(radius: 40)
                .offset(
                    x: phase1 ? 140 : 30,
                    y: phase1 ? -300 : -200
                )
                .scaleEffect(phase2 ? 1.15 : 0.88)

            // Secondary color orb — drifts across the bottom
            Circle()
                .fill(secondaryColor.opacity(0.30))
                .frame(width: 380, height: 380)
                .blur(radius: 40)
                .offset(
                    x: phase1 ? -120 : -30,
                    y: phase1 ? 300 : 180
                )
                .scaleEffect(phase3 ? 0.85 : 1.15)

            // Small accent highlight — slow breathing
            Circle()
                .fill(accent.tintColor.opacity(0.22))
                .frame(width: 200, height: 200)
                .blur(radius: 32)
                .offset(
                    x: phase2 ? -150 : -50,
                    y: phase2 ? -140 : -300
                )
                .opacity(phase4 ? 0.95 : 0.55)

            // Secondary glow — breathing + drift
            Circle()
                .fill(secondaryColor.opacity(0.14))
                .frame(width: 240, height: 240)
                .blur(radius: 32)
                .offset(
                    x: phase4 ? 140 : 50,
                    y: phase4 ? 160 : 300
                )
                .scaleEffect(phase3 ? 1.1 : 0.9)
        }
        .ignoresSafeArea()
        .task {
            withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) {
                phase1.toggle()
            }
            withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                phase2.toggle()
            }
            withAnimation(.easeInOut(duration: 9.0).repeatForever(autoreverses: true)) {
                phase3.toggle()
            }
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                phase4.toggle()
            }
        }
    }
}
