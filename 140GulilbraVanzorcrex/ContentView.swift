import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()

    var body: some View {
        ZStack {
            if gameState.hasSeenOnboarding == false {
                SkyAtmosphereBackground()
            }
            Group {
                if gameState.hasSeenOnboarding {
                    MainTabShellView()
                } else {
                    OnboardingFlowView()
                }
            }
            .environmentObject(gameState)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
