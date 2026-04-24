import SwiftUI

struct AppSplashView: View {
    // Animation state
    @State private var orbsDrift = false
    @State private var ringsPulse = false
    @State private var arcProgress: CGFloat = 0
    @State private var checkProgress: CGFloat = 0
    @State private var bar1Visible = false
    @State private var bar2Visible = false
    @State private var bar3Visible = false
    @State private var titleVisible = false
    @State private var taglineVisible = false

    // Palette (matches the Orbyt splash gradient)
    private let bgTop = Color(red: 0.05, green: 0.11, blue: 0.31)
    private let bgMid = Color(red: 0.11, green: 0.36, blue: 0.68)
    private let bgBottom = Color(red: 0.18, green: 0.71, blue: 0.59)
    private let teal = Color(red: 0.31, green: 0.89, blue: 0.76)
    private let tealMid = Color(red: 0.44, green: 0.92, blue: 0.82)
    private let tealLight = Color(red: 0.56, green: 0.94, blue: 0.87)
    private let disc = Color(red: 0.05, green: 0.14, blue: 0.28)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [bgTop, bgMid, bgBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            driftingOrbs
            logoBlock
            textBlock
        }
        .onAppear(perform: runAnimation)
    }

    // MARK: - Drifting orbs

    private var driftingOrbs: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 280, height: 280)
                    .blur(radius: 6)
                    .offset(
                        x: orbsDrift ? -geo.size.width * 0.42 : -geo.size.width * 0.48,
                        y: orbsDrift ? -geo.size.height * 0.18 : -geo.size.height * 0.14
                    )
                    .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: orbsDrift)

                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 200, height: 200)
                    .blur(radius: 6)
                    .offset(
                        x: orbsDrift ? geo.size.width * 0.40 : geo.size.width * 0.34,
                        y: orbsDrift ? geo.size.height * 0.12 : geo.size.height * 0.08
                    )
                    .animation(.easeInOut(duration: 11).repeatForever(autoreverses: true), value: orbsDrift)

                Circle()
                    .fill(Color.white.opacity(0.09))
                    .frame(width: 130, height: 130)
                    .blur(radius: 4)
                    .offset(
                        x: orbsDrift ? -geo.size.width * 0.22 : -geo.size.width * 0.28,
                        y: orbsDrift ? geo.size.height * 0.28 : geo.size.height * 0.32
                    )
                    .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: orbsDrift)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Logo block (rings + arc + check + bars)

    private var logoBlock: some View {
        ZStack {
            // Three concentric rings, each pulsing outward on a loop
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 170, height: 170)
                    .scaleEffect(ringsPulse ? 1.35 : 0.85)
                    .opacity(ringsPulse ? 0 : 0.55)
                    .animation(
                        .easeOut(duration: 2.4)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.8),
                        value: ringsPulse
                    )
            }

            // Dark inner disc
            Circle()
                .fill(disc)
                .frame(width: 108, height: 108)

            // Teal arc strokes in around the disc
            Circle()
                .trim(from: 0, to: arcProgress)
                .stroke(teal, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 128, height: 128)
                .rotationEffect(.degrees(-90))

            // Checkmark draws in inside the arc
            CheckmarkShape()
                .trim(from: 0, to: checkProgress)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .frame(width: 56, height: 36)
                .offset(y: -4)

            // Three bars rise below the logo
            HStack(alignment: .bottom, spacing: 6) {
                splashBar(color: teal, height: 22, visible: bar1Visible)
                splashBar(color: tealMid, height: 34, visible: bar2Visible)
                splashBar(color: tealLight, height: 46, visible: bar3Visible)
            }
            .offset(y: 78)
        }
        .frame(width: 200, height: 200)
        .offset(y: -40)
    }

    private func splashBar(color: Color, height: CGFloat, visible: Bool) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color)
            .frame(width: 14, height: height)
            .scaleEffect(x: 1, y: visible ? 1 : 0, anchor: .bottom)
            .opacity(visible ? 1 : 0)
    }

    // MARK: - Text block

    private var textBlock: some View {
        VStack(spacing: 8) {
            Spacer()

            Text("Orbyt")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: teal.opacity(0.45), radius: 14)
                .opacity(titleVisible ? 1 : 0)
                .offset(y: titleVisible ? 0 : 12)

            Text("Power your day, beautifully")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.78))
                .opacity(taglineVisible ? 1 : 0)
                .offset(y: taglineVisible ? 0 : 8)
                .padding(.bottom, 90)
        }
    }

    // MARK: - Animation choreography (~1.9s total)

    private func runAnimation() {
        orbsDrift = true
        ringsPulse = true

        withAnimation(.easeOut(duration: 0.9).delay(0.15)) {
            arcProgress = 1
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.9)) {
            checkProgress = 1
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(1.1)) {
            bar1Visible = true
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(1.22)) {
            bar2Visible = true
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(1.34)) {
            bar3Visible = true
        }
        withAnimation(.easeOut(duration: 0.45).delay(1.5)) {
            titleVisible = true
        }
        withAnimation(.easeOut(duration: 0.45).delay(1.7)) {
            taglineVisible = true
        }
    }
}

// MARK: - Checkmark shape (for stroke draw-in)

private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.05))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}

#Preview {
    AppSplashView()
}
