//
//  QuickActionButton.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import SwiftUI

struct QuickActionButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let symbol: String
    let title: String
    let tint: Color
    var isPressed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tint.opacity(0.24),
                                    tint.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 62, height: 62)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(colorScheme == .dark ? 0.28 : 0.8),
                                            Color.white.opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    Image(systemName: symbol)
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [tint.opacity(0.9), tint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(isPressed ? 0.9 : 1)
                .rotationEffect(.degrees(isPressed ? -3 : 0))
                .animation(.spring(response: 0.24, dampingFraction: 0.7), value: isPressed)
                .shadow(color: tint.opacity(colorScheme == .dark ? 0.30 : 0.18), radius: 10, x: 0, y: 6)

                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 74)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}
