import SwiftUI

struct ProgressHubView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var resetRequested = false
    @State private var refreshToken = UUID()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statRow(title: "Sessions finished", value: "\(gameState.totalSessions)")
                    statRow(title: "Stars collected", value: "\(gameState.totalStarsCollected())")
                    statRow(title: "Stages cleared", value: "\(gameState.stagesClearedCount()) / \(ActivityRoute.allCases.count * ActivityRoute.levelsPerActivity)")
                    statRow(title: "Three-star stages", value: "\(gameState.tripleStarStageKeys.count)")
                    statRow(title: "Daily spotlight today", value: gameState.isDailySpotlightCompleteToday() ? "Done" : "Open")
                } header: {
                    Text("Overview")
                        .foregroundStyle(Color.appTextSecondary)
                }

                Section {
                    Button(role: .destructive) {
                        resetRequested = true
                    } label: {
                        Text("Reset All Progress")
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(minHeight: CarnivalLayout.minimumTap)
                    }
                    .listRowBackground(progressResetRowBackground)
                } footer: {
                    Text("Reset clears stars, sessions, daily spotlight, best marks, trophies progress, and shows onboarding again.")
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .id(refreshToken)
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .background(Color.clear)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .background(SkyAtmosphereBackground())
            .alert("Reset everything?", isPresented: $resetRequested) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    gameState.resetAllProgress()
                    refreshToken = UUID()
                }
            } message: {
                Text("This cannot be undone.")
            }
            .onReceive(NotificationCenter.default.publisher(for: .gameStateDidReset)) { _ in
                refreshToken = UUID()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var progressResetRowBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.red.opacity(0.22))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.red.opacity(0.45), lineWidth: 1)
            )
            .padding(.vertical, 4)
    }

    private func statRow(title: String, value: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .layoutPriority(0)
            Text(value)
                .foregroundStyle(Color.appAccent)
                .font(.body.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.trailing)
                .layoutPriority(1)
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appSurface.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.appTextSecondary.opacity(0.15), lineWidth: 1)
                )
                .padding(.vertical, 4)
        )
    }
}
