//
//  HubCard.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import SwiftUI

struct HubCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: HubTheme.cardRadius, style: .continuous)
                    .fill(HubTheme.cardSurface(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: HubTheme.cardRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.4),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: HubTheme.cardRadius, style: .continuous)
                    .stroke(HubTheme.cardStroke(for: colorScheme), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.10),
                radius: HubTheme.cardShadowRadius,
                x: 0,
                y: 8
            )
    }
}
