import SwiftUI

struct AppStartupView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            // Main app content
            RootView()
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                AppSplashView(imageName: "Image") // Replace with your asset name if different
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Keep the splash for a brief moment; adjust as needed or tie to async startup tasks
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    AppStartupView()
}
