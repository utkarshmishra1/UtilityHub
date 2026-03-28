//
//  ProgressRingView.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import SwiftUI

struct ProgressRingView: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 12
    var label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            Text(label)
                .font(.system(.headline, design: .rounded).weight(.bold))
        }
    }
}
