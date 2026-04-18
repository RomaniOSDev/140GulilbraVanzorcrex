import SwiftUI

private enum HomeRoute: Hashable {
    case play(ActivityRoute, Int, PlayDifficulty)
    case outcome(SessionResultPayload)
}

struct HomeView: View {
    @EnvironmentObject private var gameState: GameState
    let onSelectTab: (Int) -> Void

    @State private var path: [HomeRoute] = []
    @State private var quickDifficulty: PlayDifficulty = .steady

    private let carnivalTabIndex = 1
    private let trophiesTabIndex = 2
    private let progressTabIndex = 3
    private let settingsTabIndex = 4

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 18) {
                    heroWidget
                    dailySpotlightWidget
                    statsWidget
                    quickPlayWidget
                    shortcutsWidget
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, CarnivalLayout.padding)
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case let .play(activity, level, diff):
                    homeActivityDestination(activity: activity, level: level, difficulty: diff)
                case let .outcome(payload):
                    SessionResultView(payload: payload) { action in
                        handleHomeResult(action: action, payload: payload)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SkyAtmosphereBackground())
        }
    }

    // MARK: - Hero

    private var heroWidget: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.appTextSecondary.opacity(0.22), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(greetingLine)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Text("Your coordination hub — quick stats and fast jumps back into play.")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.appAccent)
                }

                HStack(spacing: 10) {
                    heroMetric(title: "Stars", value: "\(gameState.totalStarsCollected())", icon: "star.fill")
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    heroMetric(title: "Cleared", value: "\(gameState.stagesClearedCount())", icon: "checkmark.circle.fill")
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    heroMetric(title: "Runs", value: "\(gameState.totalSessions)", icon: "play.circle.fill")
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5 ..< 12:
            return "Good morning"
        case 12 ..< 17:
            return "Good afternoon"
        case 17 ..< 22:
            return "Good evening"
        default:
            return "Welcome back"
        }
    }

    private func heroMetric(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.appSurface.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.appTextSecondary.opacity(0.18), lineWidth: 1)
                )
        )
    }

    // MARK: - Daily

    private var dailySpotlightWidget: some View {
        let spot = gameState.dailySpotlight()
        let done = gameState.isDailySpotlightCompleteToday()
        let unlocked = gameState.isStageUnlocked(activity: spot.activity, level: spot.level)

        return WidgetCard(title: "Today's spotlight", systemImage: "sun.max.fill") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 8) {
                    Text("\(spot.activity.title) · Stage \(spot.level)")
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    if done {
                        Text("Done")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.appBackground)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.appAccent))
                    }
                }
                Text("Refreshes at UTC midnight. Uses your current pace below.")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)

                Picker("Pace", selection: $quickDifficulty) {
                    ForEach(PlayDifficulty.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    path.append(.play(spot.activity, spot.level, quickDifficulty))
                } label: {
                    Label("Play spotlight", systemImage: "play.fill")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
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
                    Text("Unlock earlier stages in this activity on the Carnival tab.")
                        .font(.caption2)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
    }

    // MARK: - Stats

    private var statsWidget: some View {
        let totalStages = ActivityRoute.allCases.count * ActivityRoute.levelsPerActivity
        let cleared = gameState.stagesClearedCount()
        let ratio = totalStages > 0 ? Double(cleared) / Double(totalStages) : 0

        return WidgetCard(title: "Progress pulse", systemImage: "waveform.path.ecg") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stages cleared")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text("\(cleared) / \(totalStages)")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    ZStack {
                        Circle()
                            .stroke(Color.appTextSecondary.opacity(0.25), lineWidth: 10)
                            .frame(width: 72, height: 72)
                        Circle()
                            .trim(from: 0, to: ratio)
                            .stroke(Color.appAccent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 72, height: 72)
                            .rotationEffect(.degrees(-90))
                        Text("\(Int((ratio * 100).rounded()))%")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.appTextPrimary)
                    }
                }
                HStack(spacing: 10) {
                    statChip(title: "Three-star", value: "\(gameState.tripleStarStageKeys.count)", icon: "triangle.fill")
                        .frame(minWidth: 0, maxWidth: .infinity)
                    statChip(title: "Sessions", value: "\(gameState.totalSessions)", icon: "arrow.triangle.2.circlepath")
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
        }
    }

    private func statChip(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.appAccent)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appSurface.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.appTextSecondary.opacity(0.18), lineWidth: 1)
                )
        )
    }

    // MARK: - Quick play

    private var quickPlayWidget: some View {
        WidgetCard(title: "Jump in", systemImage: "bolt.horizontal.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Pick a recommended stage. Pace matches the spotlight control above.")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)

                Group {
                    let picks = recommendedStages()
                    if picks.isEmpty {
                        Text("Play any stage from Carnival to unlock personalized picks here.")
                            .font(.footnote)
                            .foregroundStyle(Color.appTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(picks, id: \.id) { item in
                                    Button {
                                        path.append(.play(item.activity, item.level, quickDifficulty))
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(item.activity.title)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(Color.appTextPrimary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                            Text("Stage \(item.level)")
                                                .font(.title3.weight(.bold))
                                                .foregroundStyle(Color.appAccent)
                                            HStack(spacing: 4) {
                                                ForEach(0 ..< 3, id: \.self) { i in
                                                    Circle()
                                                        .fill(i < item.stars ? Color.appAccent : Color.appTextSecondary.opacity(0.25))
                                                        .frame(width: 6, height: 6)
                                                }
                                            }
                                        }
                                        .padding(14)
                                        .frame(width: 148, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(Color.appSurface)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                        .strokeBorder(Color.appTextSecondary.opacity(0.2), lineWidth: 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    private struct RecommendedStage: Identifiable {
        let id: String
        let activity: ActivityRoute
        let level: Int
        let stars: Int
    }

    private func recommendedStages() -> [RecommendedStage] {
        var picks: [RecommendedStage] = []
        for activity in ActivityRoute.allCases {
            for level in 1 ... ActivityRoute.levelsPerActivity {
                guard gameState.isStageUnlocked(activity: activity, level: level) else { continue }
                let stars = gameState.stars(activity: activity, level: level)
                picks.append(RecommendedStage(
                    id: "\(activity.rawValue).\(level)",
                    activity: activity,
                    level: level,
                    stars: stars
                ))
            }
        }
        picks.sort { a, b in
            if a.stars != b.stars { return a.stars < b.stars }
            if a.activity.rawValue != b.activity.rawValue { return a.activity.rawValue < b.activity.rawValue }
            return a.level < b.level
        }
        return Array(picks.prefix(10))
    }

    // MARK: - Shortcuts

    private var shortcutsWidget: some View {
        WidgetCard(title: "Places", systemImage: "square.grid.2x2.fill") {
            VStack(spacing: 12) {
                shortcutRow(title: "Carnival", subtitle: "Browse every stage", icon: "party.popper.fill") {
                    onSelectTab(carnivalTabIndex)
                }
                shortcutRow(title: "Trophies", subtitle: "Achievement shelf", icon: "trophy.fill") {
                    onSelectTab(trophiesTabIndex)
                }
                shortcutRow(title: "Progress", subtitle: "Numbers & reset", icon: "chart.line.uptrend.xyaxis") {
                    onSelectTab(progressTabIndex)
                }
                shortcutRow(title: "Settings", subtitle: "Rate us, privacy, terms", icon: "gearshape.fill") {
                    onSelectTab(settingsTabIndex)
                }
            }
        }
    }

    private func shortcutRow(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.55), Color.appAccent.opacity(0.28)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 8, y: 4)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(Color.appTextPrimary)
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.appTextSecondary.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Navigation helpers

    @ViewBuilder
    private func homeActivityDestination(activity: ActivityRoute, level: Int, difficulty: PlayDifficulty) -> some View {
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

    private func handleHomeResult(action: SessionResultAction, payload: SessionResultPayload) {
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

// MARK: - Widget shell

private struct WidgetCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.appPrimary.opacity(0.25))
                    )
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            content()
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.appTextSecondary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
