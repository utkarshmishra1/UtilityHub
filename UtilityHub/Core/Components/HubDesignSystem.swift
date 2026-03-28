//
//  HubDesignSystem.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import SwiftUI

enum HubTheme {
    static let cardRadius: CGFloat = 16
    static let sectionSpacing: CGFloat = 18
    static let horizontalPadding: CGFloat = 18
    static let cardShadowRadius: CGFloat = 14
    static var accentGradient: LinearGradient {
        AppAccent.current.gradient
    }

    static func cardSurface(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.22, blue: 0.27),
                    Color(red: 0.14, green: 0.16, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.white,
                Color(red: 0.95, green: 0.97, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func cardStroke(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.22),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.white.opacity(0.95),
                Color.black.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct HubSectionHeader: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}
