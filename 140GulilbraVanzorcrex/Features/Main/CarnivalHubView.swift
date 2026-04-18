import SwiftUI

private enum CarnivalRoute: Hashable {
    case play(ActivityRoute, Int, PlayDifficulty)
    case outcome(SessionResultPayload)
}

private enum ActivityListFilter: String, CaseIterable, Identifiable, Hashable {
    case all
    case ringTwirl
    case flickCatch
    case glowFlow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .ringTwirl: return "Ring"
        case .flickCatch: return "Flick"
        case .glowFlow: return "Glow"
        }
    }

    func includes(_ activity: ActivityRoute) -> Bool {
        switch self {
        case .all:
            return true
        case .ringTwirl:
            return activity == .ringTwirl
        case .flickCatch:
            return activity == .flickCatch
        case .glowFlow:
            return activity == .glowFlow
        }
    }
}

struct CarnivalHubView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var difficulty: PlayDifficulty = .steady
    @State private var path: [CarnivalRoute] = []
    @State private var activityFilter: ActivityListFilter = .all

    private let stageGridColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var filteredActivities: [ActivityRoute] {
        ActivityRoute.allCases.filter { activityFilter.includes($0) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                List {
                        dailySpotlightSection

                        Section {
                            Picker("Pace", selection: $difficulty) {
                                ForEach(PlayDifficulty.allCases) { item in
                                    Text(item.title).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)
                            .listRowInsets(EdgeInsets(top: 12, leading: CarnivalLayout.padding, bottom: 6, trailing: CarnivalLayout.padding))
                            .listRowBackground(Color.clear)
                        }

                        Section {
                            Text("Higher pace tightens timing windows and speeds motion.")
                                .font(.footnote)
                                .foregroundStyle(Color.appTextSecondary)
                                .listRowInsets(EdgeInsets(top: 4, leading: CarnivalLayout.padding, bottom: 10, trailing: CarnivalLayout.padding))
                                .listRowBackground(Color.clear)
                        }

                        Section {
                            Picker("Activities", selection: $activityFilter) {
                                ForEach(ActivityListFilter.allCases) { item in
                                    Text(item.title).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)
                            .listRowInsets(EdgeInsets(top: 4, leading: CarnivalLayout.padding, bottom: 8, trailing: CarnivalLayout.padding))
                            .listRowBackground(Color.clear)
                        }

                        Section {
                            DisclosureGroup("How to play") {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Ring Twirl: drag in a circle on a ring to spin it. Line bright bands with the top marker, then hold steady briefly.")
                                    Text("Flick n' Catch: flick orbs upward so they land in the moving basket. Watch the timer and your lives.")
                                    Text("Glow Flow: tap only the pulsing node while the highlight overlaps it. Fewer slips means a cleaner run.")
                                    Text("Pause and Hint live in the top bar on each activity. A hint lowers your best possible star rating by one if you clear the stage.")
                                }
                                .font(.footnote)
                                .foregroundStyle(Color.appTextSecondary)
                                .padding(.vertical, 6)
                            }
                            .tint(Color.appAccent)
                            .listRowInsets(EdgeInsets(top: 4, leading: CarnivalLayout.padding, bottom: 8, trailing: CarnivalLayout.padding))
                            .listRowBackground(Color.clear)
                        }

                        ForEach(filteredActivities) { activity in
                            Section {
                                LazyVGrid(columns: stageGridColumns, spacing: 10) {
                                    ForEach(1 ... ActivityRoute.levelsPerActivity, id: \.self) { level in
                                        levelCell(activity: activity, level: level)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowInsets(EdgeInsets(top: 6, leading: CarnivalLayout.padding, bottom: 12, trailing: CarnivalLayout.padding))
                                .listRowBackground(Color.clear)
                            } header: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(activity.title)
                                        .font(.headline)
                                        .foregroundStyle(Color.appTextPrimary)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.85)
                                    Text(activity.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.appTextSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 6)
                                .padding(.horizontal, CarnivalLayout.padding)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                    .navigationDestination(for: CarnivalRoute.self) { route in
                        switch route {
                        case let .play(activity, level, diff):
                            activityDestination(activity: activity, level: level, difficulty: diff)
                        case let .outcome(payload):
                            SessionResultView(payload: payload) { action in
                                handleResult(action: action, payload: payload)
                            }
                        }
                    }
                    .navigationTitle("Carnival")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                    .background(SkyAtmosphereBackground())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var dailySpotlightSection: some View {
        let spot = gameState.dailySpotlight()
        let done = gameState.isDailySpotlightCompleteToday()
        let unlocked = gameState.isStageUnlocked(activity: spot.activity, level: spot.level)
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Today's spotlight")
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                    Spacer(minLength: 8)
                    if done {
                        Text("Cleared")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
                Text("\(spot.activity.title) · Stage \(spot.level)")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                Text("Refreshes each calendar day (UTC).")
                    .font(.caption2)
                    .foregroundStyle(Color.appTextSecondary)
                Button {
                    path.append(.play(spot.activity, spot.level, difficulty))
                } label: {
                    Text("Play spotlight")
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .foregroundStyle(Color.appBackground)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: CarnivalLayout.minimumTap)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.appPrimary)
                        )
                }
                .buttonStyle(.plain)
                .disabled(done || unlocked == false)
                if unlocked == false {
                    Text("Clear earlier stages in this activity to unlock this spotlight stage.")
                        .font(.caption2)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.appTextSecondary.opacity(0.2), lineWidth: 1)
                    )
            )
            .listRowInsets(EdgeInsets(top: 10, leading: CarnivalLayout.padding, bottom: 12, trailing: CarnivalLayout.padding))
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private func activityDestination(activity: ActivityRoute, level: Int, difficulty: PlayDifficulty) -> some View {
        switch activity {
        case .ringTwirl:
            RingTwirlView(level: level, difficulty: difficulty) { payload in
                path = [.outcome(payload)]
            }
        case .flickCatch:
            FlickCatchView(level: level, difficulty: difficulty) { payload in
                path = [.outcome(payload)]
            }
        case .glowFlow:
            GlowFlowView(level: level, difficulty: difficulty) { payload in
                path = [.outcome(payload)]
            }
        }
    }

    private func levelCell(activity: ActivityRoute, level: Int) -> some View {
        let unlocked = gameState.isStageUnlocked(activity: activity, level: level)
        let stars = gameState.stars(activity: activity, level: level)
        let best = gameState.bestCaption(activity: activity, level: level)

        return StageLevelPickerCell(
            activity: activity,
            level: level,
            unlocked: unlocked,
            stars: stars,
            bestCaption: best
        ) {
            path.append(.play(activity, level, difficulty))
        }
    }

    private func handleResult(action: SessionResultAction, payload: SessionResultPayload) {
        switch action {
        case .retry:
            path = [.play(payload.activity, payload.level, payload.difficulty)]
        case .next:
            guard payload.sessionSucceeded else {
                path = []
                return
            }
            let nextLevel = payload.level + 1
            if nextLevel <= ActivityRoute.levelsPerActivity, gameState.isStageUnlocked(activity: payload.activity, level: nextLevel) {
                path = [.play(payload.activity, nextLevel, payload.difficulty)]
            } else {
                path = []
            }
        case .home:
            path = []
        }
    }
}
