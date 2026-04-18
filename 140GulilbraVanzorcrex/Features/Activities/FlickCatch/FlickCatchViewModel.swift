import Combine
import CoreGraphics
import Foundation

@MainActor
final class FlickCatchViewModel: ObservableObject {
    struct Orb: Identifiable, Equatable {
        let id: UUID
        var position: CGPoint
        var velocity: CGVector
        var isActive: Bool
    }

    @Published private(set) var orbs: [Orb] = []
    @Published private(set) var catches: Int = 0
    @Published private(set) var lives: Int
    @Published private(set) var timeRemaining: TimeInterval
    @Published private(set) var fieldSize: CGSize = .zero
    /// Basket center X in playfield coordinates (user-controlled).
    @Published private(set) var basketCenterX: CGFloat = 0
    @Published private(set) var sessionFinished: Bool = false
    @Published private(set) var sessionVictory: Bool = false
    @Published private(set) var isPaused = false
    @Published private(set) var hintUsed = false

    let level: Int
    let difficulty: PlayDifficulty
    let targetCatches: Int

    private let spawnInterval: TimeInterval
    private var spawnAccumulator: TimeInterval = 0
    private var tickCancellable: AnyCancellable?
    private var lastTickDate: Date?
    private var sessionStart = Date()
    private var hintSlowUntil: Date?

    init(level: Int, difficulty: PlayDifficulty) {
        self.level = level
        self.difficulty = difficulty
        lives = 3
        let lv = min(level, 12)
        targetCatches = min(18, 4 + lv)
        spawnInterval = max(0.48, (1.55 - Double(lv) * 0.06) * difficulty.flickSpawnIntervalMultiplier)
        timeRemaining = max(20, 50 - Double(lv) * 1.9)
    }

    func startSession(in size: CGSize) {
        fieldSize = size
        sessionFinished = false
        sessionVictory = false
        isPaused = false
        hintUsed = false
        hintSlowUntil = nil
        catches = 0
        lives = 3
        orbs = []
        basketCenterX = size.width / 2
        spawnAccumulator = spawnInterval
        lastTickDate = Date()
        let lv = min(level, 12)
        timeRemaining = max(20, 50 - Double(lv) * 1.9)
        sessionStart = Date()
        tickCancellable = Timer.publish(every: 1 / 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stopSession() {
        tickCancellable?.cancel()
        tickCancellable = nil
    }

    func setPaused(_ value: Bool) {
        isPaused = value
    }

    func activateHint() {
        guard hintUsed == false, sessionFinished == false else { return }
        hintUsed = true
        hintSlowUntil = Date().addingTimeInterval(6)
    }

    func updateFieldSize(_ size: CGSize) {
        fieldSize = size
        basketCenterX = clampedBasketCenterX(width: size.width, proposedX: basketCenterX)
    }

    func sessionElapsed() -> TimeInterval {
        Date().timeIntervalSince(sessionStart)
    }

    func basketCenterX(in size: CGSize) -> CGFloat {
        clampedBasketCenterX(width: size.width)
    }

    /// Move basket by horizontal drag; `width` should match current playfield width.
    func setBasketCenterX(_ x: CGFloat, playfieldWidth width: CGFloat) {
        basketCenterX = clampedBasketCenterX(width: width, proposedX: x)
    }

    private func clampedBasketCenterX(width: CGFloat, proposedX: CGFloat? = nil) -> CGFloat {
        guard width > 20 else { return width / 2 }
        let halfBasket: CGFloat = 58
        let inset: CGFloat = 8
        let minX = halfBasket + inset
        let maxX = width - halfBasket - inset
        let x = proposedX ?? basketCenterX
        return min(max(minX, x), maxX)
    }

    func flickOrb(id: UUID, translation: CGSize) {
        guard sessionFinished == false, isPaused == false else { return }
        guard let index = orbs.firstIndex(where: { $0.id == id }) else { return }
        let upward = max(0, -translation.height)
        let sideways = translation.width
        let power = hypot(sideways, upward)
        guard power > 8 else { return }
        let vx = sideways * 0.05
        let rawVertical = Double(translation.height) * 0.35
        let vy = min(-110, max(-360, rawVertical))
        orbs[index].velocity = CGVector(dx: vx, dy: vy)
    }

    func computeStarsRaw(success: Bool) -> Int {
        guard success else { return 0 }
        let elapsed = sessionElapsed()
        if catches >= targetCatches + 2, lives == 3 {
            return 3
        }
        if catches >= targetCatches, elapsed < Double(36 - min(level, 12) * 2) {
            return 2
        }
        return 1
    }

    /// Hint: slightly softer gravity so orbs are easier to line up with the manual basket.
    private func orbGravityMultiplier() -> Double {
        if let until = hintSlowUntil, Date() < until {
            return 0.72
        }
        return 1
    }

    private func tick() {
        guard sessionFinished == false, isPaused == false else { return }
        let now = Date()
        let dt = min(0.05, now.timeIntervalSince(lastTickDate ?? now))
        lastTickDate = now

        timeRemaining -= dt
        if timeRemaining < 0 {
            timeRemaining = 0
        }

        var updated = orbs
        for index in updated.indices where updated[index].isActive {
            var orb = updated[index]
            orb.velocity.dy += 520 * dt * orbGravityMultiplier()
            orb.position.x += CGFloat(orb.velocity.dx * dt)
            orb.position.y += CGFloat(orb.velocity.dy * dt)

            if let outcome = resolve(orb: &orb) {
                switch outcome {
                case .caught:
                    catches += 1
                    orb.isActive = false
                case .missed:
                    orb.isActive = false
                    lives -= 1
                }
            }

            updated[index] = orb
        }

        updated.removeAll { $0.isActive == false }
        orbs = updated

        spawnAccumulator += dt
        var spawnBudget = 0
        while spawnAccumulator >= spawnInterval, spawnBudget < 2, lives > 0, timeRemaining > 0 {
            spawnAccumulator -= spawnInterval
            spawnOrb()
            spawnBudget += 1
        }

        if catches >= targetCatches {
            endSession(victory: true)
            return
        }

        if lives <= 0 {
            endSession(victory: false)
            return
        }

        if timeRemaining <= 0 {
            endSession(victory: catches >= targetCatches)
        }
    }

    private enum OrbOutcome {
        case caught
        case missed
    }

    private func resolve(orb: inout Orb) -> OrbOutcome? {
        let size = fieldSize
        guard size.width > 10, size.height > 10 else { return nil }

        let basketY = size.height - 64
        let basketX = clampedBasketCenterX(width: size.width)
        let halfWidth: CGFloat = 52 + CGFloat(min(level, 12)) * 2

        if orb.position.y >= basketY - 12,
           orb.position.y <= basketY + 28,
           abs(orb.position.x - basketX) <= halfWidth,
           orb.velocity.dy > 0 {
            return .caught
        }

        if orb.position.y > size.height + 24 {
            return .missed
        }

        if orb.position.x < -50 || orb.position.x > size.width + 50 {
            return .missed
        }

        return nil
    }

    private func spawnOrb() {
        guard fieldSize.width > 10, fieldSize.height > 10 else { return }
        let margin: CGFloat = 36
        let xLow = margin
        let xHigh = max(margin, fieldSize.width - margin)
        let x = CGFloat.random(in: xLow ... xHigh)
        // SwiftUI: y grows downward — spawn in the upper band so orbs fall toward the basket.
        let topBandLow: CGFloat = 26
        let topBandHigh = min(fieldSize.height * 0.24, fieldSize.height - 100)
        let yHigh = max(topBandLow + 10, topBandHigh)
        let startY = CGFloat.random(in: topBandLow ... yHigh)
        let start = CGPoint(x: x, y: startY)
        let orb = Orb(id: UUID(), position: start, velocity: CGVector(dx: 0, dy: 90), isActive: true)
        orbs.append(orb)
    }

    private func endSession(victory: Bool) {
        guard sessionFinished == false else { return }
        sessionFinished = true
        sessionVictory = victory
        stopSession()
    }
}
