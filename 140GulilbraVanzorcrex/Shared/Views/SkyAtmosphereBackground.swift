import SwiftUI

/// Full-screen layered gradients tuned to `AppBackground` / `AppPrimary` / `AppAccent`.
struct SkyAtmosphereBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.01, green: 0.04, blue: 0.12),
                    Color.appBackground.opacity(0.92),
                    Color(red: 0.02, green: 0.05, blue: 0.11)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.appPrimary.opacity(0.45), Color.clear],
                center: UnitPoint(x: 0.9, y: 0.1),
                startRadius: 20,
                endRadius: 380
            )

            RadialGradient(
                colors: [Color.appAccent.opacity(0.32), Color.clear],
                center: UnitPoint(x: 0.08, y: 0.82),
                startRadius: 30,
                endRadius: 420
            )

            RadialGradient(
                colors: [Color.appPrimary.opacity(0.2), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 60,
                endRadius: 220
            )

            LinearGradient(
                colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.25),
                    Color.black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}
