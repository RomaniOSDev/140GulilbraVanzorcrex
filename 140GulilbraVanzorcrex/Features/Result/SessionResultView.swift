import SwiftUI

struct SessionResultView: View {
    @EnvironmentObject private var gameState: GameState

    let payload: SessionResultPayload
    let onAction: (SessionResultAction) -> Void

    @State private var litStars = 0
    @State private var achievementOffset: CGFloat = 40
    @State private var achievementOpacity: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 22) {
                    Text(payload.headline)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)

                    starStack

                    if payload.hintUsed {
                        Text("Hint was used — your star ceiling for this run was reduced by one.")
                            .font(.footnote)
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(payload.details, id: \.self) { line in
                            Text(line)
                                .font(.body)
                                .foregroundStyle(Color.appTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if payload.newlyUnlockedAchievementIDs.isEmpty == false {
                        achievementPanel
                            .offset(y: achievementOffset)
                            .opacity(achievementOpacity)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.appSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.appTextSecondary.opacity(0.2), lineWidth: 1)
                        )
                )

                VStack(spacing: 12) {
                    if canAdvance {
                        Button(action: { onAction(.next) }) {
                            Text("Next Level")
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .foregroundStyle(Color.appBackground)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .frame(minHeight: CarnivalLayout.minimumTap)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.appPrimary)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: { onAction(.retry) }) {
                        Text("Retry")
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(Color.appTextPrimary)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(minHeight: CarnivalLayout.minimumTap)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.appSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(Color.appAccent.opacity(0.35), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: { onAction(.home) }) {
                        Text("Back to Carnival")
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .foregroundStyle(Color.appTextPrimary)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(minHeight: CarnivalLayout.minimumTap)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.appSurface.opacity(0.9))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(Color.appTextSecondary.opacity(0.25), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(CarnivalLayout.padding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SkyAtmosphereBackground())
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .onAppear {
            scheduleStarReveal()
            revealAchievementsIfNeeded()
        }
    }

    private var canAdvance: Bool {
        guard payload.sessionSucceeded else { return false }
        let next = payload.level + 1
        guard next <= ActivityRoute.levelsPerActivity else { return false }
        return gameState.isStageUnlocked(activity: payload.activity, level: next)
    }

    private var starStack: some View {
        HStack(spacing: 18) {
            ForEach(0 ..< 3, id: \.self) { index in
                StarGlyph(filled: index < litStars, diameter: 44)
                    .scaleEffect(index < litStars ? 1 : 0.88)
                    .animation(.spring(response: 0.45, dampingFraction: 0.68).delay(Double(index) * 0.15), value: litStars)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private var achievementPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New trophy highlights")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            ForEach(unlockedItems) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: item.systemImage)
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                        Text(item.detail)
                            .font(.footnote)
                            .foregroundStyle(Color.appTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.appSurface.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.appTextSecondary.opacity(0.18), lineWidth: 1)
                        )
                )
            }
        }
    }

    private var unlockedItems: [AchievementItem] {
        let ids = Set(payload.newlyUnlockedAchievementIDs)
        return AchievementItem.catalog.filter { ids.contains($0.id) }
    }

    private func scheduleStarReveal() {
        litStars = 0
        let total = min(3, max(0, payload.stars))
        guard total > 0 else { return }
        for index in 0 ..< total {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
                    litStars = index + 1
                }
            }
        }
    }

    private func revealAchievementsIfNeeded() {
        guard payload.newlyUnlockedAchievementIDs.isEmpty == false else { return }
        achievementOffset = 40
        achievementOpacity = 0
        withAnimation(.easeOut(duration: 2.0)) {
            achievementOffset = 0
            achievementOpacity = 1
        }
    }
}
