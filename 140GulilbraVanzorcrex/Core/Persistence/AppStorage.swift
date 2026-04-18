import Combine
import Foundation
import SwiftUI

extension Notification.Name {
    static let gameStateDidReset = Notification.Name("GameStateDidReset")
}

enum PlayDifficulty: String, CaseIterable, Identifiable {
    case relaxed
    case steady
    case sharp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .relaxed: return "Relaxed"
        case .steady: return "Steady"
        case .sharp: return "Sharp"
        }
    }

    var ringToleranceMultiplier: Double {
        switch self {
        case .relaxed: return 1.35
        case .steady: return 1.0
        case .sharp: return 0.72
        }
    }

    var flickBasketSpeedMultiplier: Double {
        switch self {
        case .relaxed: return 0.78
        case .steady: return 1.0
        case .sharp: return 1.28
        }
    }

    var flickSpawnIntervalMultiplier: Double {
        switch self {
        case .relaxed: return 1.2
        case .steady: return 1.0
        case .sharp: return 0.82
        }
    }

    var glowPhaseWindowMultiplier: Double {
        switch self {
        case .relaxed: return 1.25
        case .steady: return 1.0
        case .sharp: return 0.78
        }
    }
}

enum ActivityRoute: String, CaseIterable, Identifiable {
    case ringTwirl
    case flickCatch
    case glowFlow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ringTwirl: return "Ring Twirl"
        case .flickCatch: return "Flick n' Catch"
        case .glowFlow: return "Glow Flow"
        }
    }

    var detail: String {
        switch self {
        case .ringTwirl:
            return "Rotate rings to align glowing segments."
        case .flickCatch:
            return "Flick orbs into a moving basket before time runs out."
        case .glowFlow:
            return "Tap nodes when pulses meet to guide the flow."
        }
    }

    static let levelsPerActivity = 12
}

struct StageBests: Codable, Equatable {
    var ringClearSeconds: TimeInterval?
    var flickCatches: Int?
    var glowElapsedSeconds: TimeInterval?
    var glowMistakes: Int?
}

struct AchievementItem: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String

    static let catalog: [AchievementItem] = [
        AchievementItem(
            id: "first_clear",
            title: "First Clear",
            detail: "Finish any stage with at least one star.",
            systemImage: "sparkles"
        ),
        AchievementItem(
            id: "star_trail",
            title: "Star Trail",
            detail: "Collect 20 total stars across all stages.",
            systemImage: "star.circle.fill"
        ),
        AchievementItem(
            id: "clean_alignment",
            title: "Clean Alignment",
            detail: "Earn a three-star rating on any stage.",
            systemImage: "seal.fill"
        ),
        AchievementItem(
            id: "steady_visitor",
            title: "Steady Visitor",
            detail: "Complete 10 sessions across activities.",
            systemImage: "figure.walk"
        ),
        AchievementItem(
            id: "full_circuit",
            title: "Full Circuit",
            detail: "Clear every stage at least once.",
            systemImage: "map.fill"
        ),
        AchievementItem(
            id: "triple_showcase",
            title: "Triple Showcase",
            detail: "Hold 10 different three-star results.",
            systemImage: "triangle.fill"
        )
    ]
}

final class GameState: ObservableObject {
    private enum Keys {
        static let hasSeenOnboarding = "gs.hasSeenOnboarding"
        static let starsMapData = "gs.starsMapData"
        static let totalSessions = "gs.totalSessions"
        static let tripleStarStageKeys = "gs.tripleStarStageKeysData"
        static let stageBestsData = "gs.stageBestsData"
        static let dailyCompletedDay = "gs.dailyCompletedDay"
    }

    private let defaults: UserDefaults

    @Published var hasSeenOnboarding: Bool
    @Published private(set) var starsByStageKey: [String: Int]
    @Published private(set) var totalSessions: Int
    @Published private(set) var tripleStarStageKeys: Set<String>
    @Published private(set) var stageBests: [String: StageBests]
    @Published private(set) var dailyCompletedCalendarDay: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        if let data = defaults.data(forKey: Keys.starsMapData),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            starsByStageKey = decoded
        } else {
            starsByStageKey = [:]
        }
        totalSessions = defaults.integer(forKey: Keys.totalSessions)
        if let data = defaults.data(forKey: Keys.tripleStarStageKeys),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            tripleStarStageKeys = Set(decoded)
        } else {
            tripleStarStageKeys = []
        }
        if let data = defaults.data(forKey: Keys.stageBestsData),
           let decoded = try? JSONDecoder().decode([String: StageBests].self, from: data) {
            stageBests = decoded
        } else {
            stageBests = [:]
        }
        dailyCompletedCalendarDay = defaults.string(forKey: Keys.dailyCompletedDay)
    }

    func stageKey(activity: ActivityRoute, level: Int) -> String {
        "\(activity.rawValue).\(level)"
    }

    func stars(activity: ActivityRoute, level: Int) -> Int {
        starsByStageKey[stageKey(activity: activity, level: level), default: 0]
    }

    func isStageUnlocked(activity: ActivityRoute, level: Int) -> Bool {
        guard level >= 1, level <= ActivityRoute.levelsPerActivity else { return false }
        if level == 1 { return true }
        return stars(activity: activity, level: level - 1) >= 1
    }

    func totalStarsCollected() -> Int {
        starsByStageKey.values.reduce(0, +)
    }

    func stagesClearedCount() -> Int {
        starsByStageKey.values.filter { $0 >= 1 }.count
    }

    func hasAnyThreeStar() -> Bool {
        starsByStageKey.values.contains(3)
    }

    func allStagesCleared() -> Bool {
        let keys = ActivityRoute.allCases.flatMap { activity in
            (1 ... ActivityRoute.levelsPerActivity).map { stageKey(activity: activity, level: $0) }
        }
        return keys.allSatisfy { key in (starsByStageKey[key] ?? 0) >= 1 }
    }

    func unlockedAchievementIDs() -> Set<String> {
        var set = Set<String>()
        for item in AchievementItem.catalog where isUnlocked(achievement: item) {
            set.insert(item.id)
        }
        return set
    }

    func isUnlocked(achievement item: AchievementItem) -> Bool {
        switch item.id {
        case "first_clear":
            return stagesClearedCount() >= 1
        case "star_trail":
            return totalStarsCollected() >= 20
        case "clean_alignment":
            return hasAnyThreeStar()
        case "steady_visitor":
            return totalSessions >= 10
        case "full_circuit":
            return allStagesCleared()
        case "triple_showcase":
            return tripleStarStageKeys.count >= 10
        default:
            return false
        }
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: Keys.hasSeenOnboarding)
        objectWillChange.send()
    }

    func registerSessionFinished() {
        totalSessions += 1
        defaults.set(totalSessions, forKey: Keys.totalSessions)
        objectWillChange.send()
    }

    func applyStageResult(activity: ActivityRoute, level: Int, earnedStars: Int) {
        let key = stageKey(activity: activity, level: level)
        let clamped = min(3, max(0, earnedStars))
        let previous = starsByStageKey[key, default: 0]
        if clamped > previous {
            starsByStageKey[key] = clamped
        }
        if clamped == 3 {
            tripleStarStageKeys.insert(key)
        }
        persistStars()
        objectWillChange.send()
    }

    func cappedStars(raw: Int, hintUsed: Bool) -> Int {
        guard raw > 0 else { return 0 }
        if hintUsed {
            return max(1, raw - 1)
        }
        return raw
    }

    func bestCaption(activity: ActivityRoute, level: Int) -> String? {
        let key = stageKey(activity: activity, level: level)
        guard let b = stageBests[key] else { return nil }
        switch activity {
        case .ringTwirl:
            guard let s = b.ringClearSeconds else { return nil }
            return String(format: "Best %.1fs", s)
        case .flickCatch:
            guard let c = b.flickCatches else { return nil }
            return "Best \(c) catches"
        case .glowFlow:
            guard let e = b.glowElapsedSeconds else { return nil }
            let slips = b.glowMistakes ?? 0
            return String(format: "Best %.0fs · %d slips", e, slips)
        }
    }

    func recordRingBest(activity: ActivityRoute, level: Int, clearSeconds: TimeInterval) {
        let key = stageKey(activity: activity, level: level)
        var b = stageBests[key] ?? StageBests()
        if let old = b.ringClearSeconds {
            if clearSeconds < old {
                b.ringClearSeconds = clearSeconds
            }
        } else {
            b.ringClearSeconds = clearSeconds
        }
        stageBests[key] = b
        persistBests()
        objectWillChange.send()
    }

    func recordFlickBest(activity: ActivityRoute, level: Int, catches: Int) {
        let key = stageKey(activity: activity, level: level)
        var b = stageBests[key] ?? StageBests()
        if let old = b.flickCatches {
            if catches > old {
                b.flickCatches = catches
            }
        } else {
            b.flickCatches = catches
        }
        stageBests[key] = b
        persistBests()
        objectWillChange.send()
    }

    func recordGlowBest(activity: ActivityRoute, level: Int, elapsed: TimeInterval, mistakes: Int) {
        let key = stageKey(activity: activity, level: level)
        var b = stageBests[key] ?? StageBests()
        if let oldM = b.glowMistakes, let oldE = b.glowElapsedSeconds {
            if mistakes < oldM || (mistakes == oldM && elapsed < oldE) {
                b.glowMistakes = mistakes
                b.glowElapsedSeconds = elapsed
            }
        } else {
            b.glowMistakes = mistakes
            b.glowElapsedSeconds = elapsed
        }
        stageBests[key] = b
        persistBests()
        objectWillChange.send()
    }

    func todayCalendarKeyUTC() -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let y = components.year ?? 0
        let m = components.month ?? 0
        let d = components.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// Hash-of-the-day pick (activity + desired tier). Not always playable for new players.
    private func dailySpotlightRaw() -> (activity: ActivityRoute, level: Int) {
        let dayKey = todayCalendarKeyUTC()
        var hash = 0
        for scalar in dayKey.unicodeScalars {
            hash = hash &* 31 &+ Int(scalar.value)
        }
        let activities = ActivityRoute.allCases
        let spotlightLevelCap = min(6, ActivityRoute.levelsPerActivity)
        let span = activities.count * spotlightLevelCap
        let flat = span > 0 ? abs(hash) % span : 0
        let activity = activities[flat % activities.count]
        let level = 1 + (flat / activities.count) % spotlightLevelCap
        return (activity, level)
    }

    /// Highest stage index in `activity` the player is allowed to start (sequential unlock).
    private func highestUnlockedStage(for activity: ActivityRoute) -> Int {
        var top = 1
        for level in 1 ... ActivityRoute.levelsPerActivity {
            if isStageUnlocked(activity: activity, level: level) {
                top = level
            } else {
                break
            }
        }
        return top
    }

    /// Today’s spotlight: same daily variety as `dailySpotlightRaw`, but **always** a stage you can play.
    func dailySpotlight() -> (activity: ActivityRoute, level: Int) {
        let raw = dailySpotlightRaw()
        let cap = highestUnlockedStage(for: raw.activity)
        let level = min(raw.level, cap)
        return (raw.activity, level)
    }

    func isDailySpotlightCompleteToday() -> Bool {
        dailyCompletedCalendarDay == todayCalendarKeyUTC()
    }

    func registerDailySpotlightIfNeeded(activity: ActivityRoute, level: Int, success: Bool) {
        guard success else { return }
        let spot = dailySpotlight()
        guard spot.activity == activity, spot.level == level else { return }
        let today = todayCalendarKeyUTC()
        dailyCompletedCalendarDay = today
        defaults.set(today, forKey: Keys.dailyCompletedDay)
        objectWillChange.send()
    }

    func resetAllProgress() {
        hasSeenOnboarding = false
        starsByStageKey = [:]
        totalSessions = 0
        tripleStarStageKeys = []
        stageBests = [:]
        dailyCompletedCalendarDay = nil
        defaults.removeObject(forKey: Keys.hasSeenOnboarding)
        defaults.removeObject(forKey: Keys.starsMapData)
        defaults.removeObject(forKey: Keys.totalSessions)
        defaults.removeObject(forKey: Keys.tripleStarStageKeys)
        defaults.removeObject(forKey: Keys.stageBestsData)
        defaults.removeObject(forKey: Keys.dailyCompletedDay)
        NotificationCenter.default.post(name: .gameStateDidReset, object: nil)
        objectWillChange.send()
    }

    private func persistStars() {
        if let data = try? JSONEncoder().encode(starsByStageKey) {
            defaults.set(data, forKey: Keys.starsMapData)
        }
        let tripleArray = Array(tripleStarStageKeys)
        if let data = try? JSONEncoder().encode(tripleArray) {
            defaults.set(data, forKey: Keys.tripleStarStageKeys)
        }
    }

    private func persistBests() {
        if let data = try? JSONEncoder().encode(stageBests) {
            defaults.set(data, forKey: Keys.stageBestsData)
        }
    }
}
