import SwiftUI

struct AppSplashView: View {
    // Replace with the exact name of your asset image, e.g. "YourImageName"
    var imageName: String = "Image"

    @State private var didAppear = false

    var body: some View {
        ZStack {
            // Background to match the app's dark style
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.19),
                    Color(red: 0.06, green: 0.14, blue: 0.28),
                    Color(red: 0.08, green: 0.18, blue: 0.34)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Soft glow accents
            Circle()
                .fill(Color.cyan.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 40)
                .offset(x: 130, y: -280)

            Circle()
                .fill(Color.green.opacity(0.13))
                .frame(width: 320, height: 320)
                .blur(radius: 50)
                .offset(x: -170, y: 360)

            // App logo / splash image from Assets (full screen)
            Image(imageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .scaleEffect(didAppear ? 1 : 1.04)
                .opacity(didAppear ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.85), value: didAppear)
                .accessibilityHidden(true)
        }
        .onAppear {
            didAppear = true
        }
    }
}

#Preview {
    AppSplashView()
}
