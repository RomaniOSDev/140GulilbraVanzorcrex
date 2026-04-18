import SwiftUI

struct TrophiesHubView: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(AchievementItem.catalog) { item in
                        let unlocked = gameState.isUnlocked(achievement: item)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: item.systemImage)
                                    .font(.title2)
                                    .foregroundStyle(unlocked ? Color.appAccent : Color.appTextSecondary.opacity(0.55))
                                    .frame(width: CarnivalLayout.minimumTap, height: CarnivalLayout.minimumTap)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: unlocked
                                                            ? [Color.appAccent.opacity(0.28), Color.appPrimary.opacity(0.18)]
                                                            : [Color.appSurface.opacity(0.6), Color.appSurface.opacity(0.35)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(Color.white.opacity(unlocked ? 0.14 : 0.06), lineWidth: 1)
                                        }
                                    )
                                    .shadow(color: Color.black.opacity(unlocked ? 0.25 : 0.12), radius: unlocked ? 6 : 3, y: 3)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.title)
                                        .font(.headline)
                                        .foregroundStyle(Color.appTextPrimary)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.85)
                                    Text(item.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.appTextSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                Spacer(minLength: 0)
                            }

                            Text(unlocked ? "Unlocked" : "Locked")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(unlocked ? Color.appAccent : Color.appTextSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.appSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.appTextSecondary.opacity(unlocked ? 0.22 : 0.14), lineWidth: 1)
                                )
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(CarnivalLayout.padding)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .navigationTitle("Trophies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SkyAtmosphereBackground())
        }
    }
}
