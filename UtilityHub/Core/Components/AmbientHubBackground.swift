//
//  AmbientHubBackground.swift
//  UtilityHub
//
//  Created by Claude on 13/04/26.
//

import SwiftUI

struct AmbientHubBackground: View {
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
                startPoint: .bottomTrailing,
                endPoint: .topLeading
            )
            .ignoresSafeArea()

            // Primary accent orb — top area
            Circle()
                .fill(accent.tintColor.opacity(0.38))
                .frame(width: 320, height: 320)
                .blur(radius: 40)
                .offset(x: 30, y: -200)
                .scaleEffect(0.88)

            // Secondary color orb — bottom area
            Circle()
                .fill(secondaryColor.opacity(0.30))
                .frame(width: 380, height: 380)
                .blur(radius: 40)
                .offset(x: -30, y: 180)
                .scaleEffect(1.15)

            // Small accent highlight — top-left
            Circle()
                .fill(accent.tintColor.opacity(0.22))
                .frame(width: 200, height: 200)
                .blur(radius: 32)
                .offset(x: -50, y: -300)

            // Accent-tinted glow — bottom-right
            Circle()
                .fill(secondaryColor.opacity(0.14))
                .frame(width: 240, height: 240)
                .blur(radius: 32)
                .offset(x: 50, y: 300)
        }
        .drawingGroup()
        .ignoresSafeArea()
    }
}
