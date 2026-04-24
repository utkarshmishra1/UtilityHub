import SwiftUI

struct AppStartupView: View {
    @State private var showSplash = true
    @StateObject private var adMobService = AdMobService.shared

    var body: some View {
        ZStack {
            // Main app content
            RootView()
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                AppSplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Hold the splash for 3 seconds so the full entrance animation lands with a beat, then fade out.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
        .task(id: showSplash) {
            guard !showSplash else { return }
            await adMobService.prepareAdsIfNeeded()
        }
    }
}

#Preview {
    AppStartupView()
}
