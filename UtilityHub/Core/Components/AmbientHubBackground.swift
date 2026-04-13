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

    private var accent: AppAccent { AppAccent.current }
    private var secondaryColor: Color { accent.gradientColors.last ?? accent.tintColor }

    var body: some View {
        ZStack {
            // Base gradient — dark but tinted with accent so theme is visible
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.09),
                    accent.tintColor.opacity(0.12),
                    Color(red: 0.04, green: 0.05, blue: 0.09)
                ],
                startPoint: phase1 ? .topLeading : .bottomTrailing,
                endPoint: phase1 ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()

            // Primary accent orb — top area
            Circle()
                .fill(accent.tintColor.opacity(0.38))
                .frame(width: 320, height: 320)
                .blur(radius: 65)
                .offset(
                    x: phase1 ? 130 : 30,
                    y: phase1 ? -340 : -200
                )
                .scaleEffect(phase2 ? 1.18 : 0.88)

            // Secondary color orb — bottom area
            Circle()
                .fill(secondaryColor.opacity(0.30))
                .frame(width: 380, height: 380)
                .blur(radius: 80)
                .offset(
                    x: phase1 ? -110 : -30,
                    y: phase1 ? 340 : 180
                )
                .scaleEffect(phase2 ? 0.85 : 1.15)

            // Small accent highlight — top-left
            Circle()
                .fill(accent.tintColor.opacity(0.22))
                .frame(width: 200, height: 200)
                .blur(radius: 45)
                .offset(
                    x: phase2 ? -150 : -50,
                    y: phase2 ? -140 : -300
                )

            // Accent-tinted glow — bottom-right
            Circle()
                .fill(secondaryColor.opacity(0.14))
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .offset(
                    x: phase2 ? 140 : 50,
                    y: phase2 ? 160 : 300
                )
        }
        .task {
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                phase1.toggle()
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                phase2.toggle()
            }
        }
    }
}
