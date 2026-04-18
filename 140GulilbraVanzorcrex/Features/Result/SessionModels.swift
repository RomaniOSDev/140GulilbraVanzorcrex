import Foundation

enum SessionResultAction: Hashable {
    case retry
    case next
    case home
}

struct SessionResultPayload: Hashable {
    let activity: ActivityRoute
    let level: Int
    let difficulty: PlayDifficulty
    let stars: Int
    let headline: String
    let details: [String]
    let sessionSucceeded: Bool
    let newlyUnlockedAchievementIDs: [String]
    let hintUsed: Bool
}
