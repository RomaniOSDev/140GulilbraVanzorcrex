import Combine
import CoreGraphics
import Foundation

@MainActor
final class GlowFlowViewModel: ObservableObject {
    @Published private(set) var clock: Double = 0
    @Published private(set) var successes: Int = 0
    @Published private(set) var mistakes: Int = 0
    @Published private(set) var timeRemaining: TimeInterval
    @Published private(set) var flickerToken = UUID()
    @Published private(set) var sessionFinished: Bool = false
    @Published private(set) var sessionVictory: Bool = false
    @Published private(set) var isPaused = false
    @Published private(set) var hintUsed = false

    let level: Int
    let difficulty: PlayDifficulty
    let nodeCount: Int
    let tapsNeeded: Int

    private let period: TimeInterval
    private let windowWidth: Double
    private var tickCancellable: AnyCancellable?
    private var sessionStart = Date()
    private var hintWideUntil: Date?

    init(level: Int, difficulty: PlayDifficulty) {
        self.level = level
        self.difficulty = difficulty
        let lv = min(level, 12)
        nodeCount = min(9, 4 + lv)
        tapsNeeded = min(36, 6 + lv * 2)
        period = max(1.2, 2.55 - Double(lv) * 0.07) * difficulty.glowPhaseWindowMultiplier
        windowWidth = max(0.075, 0.21 - Double(lv) * 0.008) / difficulty.glowPhaseWindowMultiplier
        timeRemaining = max(24, 54 - Double(lv) * 2.2)
    }

    func startSession() {
        sessionFinished = false
        sessionVictory = false
        isPaused = false
        hintUsed = false
        hintWideUntil = nil
        clock = 0
        successes = 0
        mistakes = 0
        let lv = min(level, 12)
        timeRemaining = max(24, 54 - Double(lv) * 2.2)
        sessionStart = Date()
        tickCancellable = Timer.publish(every: 1 / 30, on: .main, in: .common)
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
        hintWideUntil = Date().addingTimeInterval(5)
    }

    func sessionElapsed() -> TimeInterval {
        Date().timeIntervalSince(sessionStart)
    }

    func activeNodeIndex() -> Int {
        let wrapped = phase01()
        let segment = 1.0 / Double(nodeCount)
        return min(nodeCount - 1, Int(wrapped / segment))
    }

    func effectiveWindowWidth() -> Double {
        if let until = hintWideUntil, Date() < until {
            return windowWidth * 1.85
        }
        return windowWidth
    }

    func windowContainsClock() -> Bool {
        let wrapped = phase01()
        let segment = 1.0 / Double(nodeCount)
        let index = activeNodeIndex()
        let center = segment * (Double(index) + 0.5)
        let delta = abs(wrapped - center)
        let shortest = min(delta, 1 - delta)
        return shortest <= effectiveWindowWidth()
    }

    func handleTap(on index: Int) {
        guard sessionFinished == false, isPaused == false else { return }
        let active = activeNodeIndex()
        let inWindow = windowContainsClock()
        if index == active, inWindow {
            successes += 1
            if successes >= tapsNeeded {
                endSession(victory: true)
            }
        } else {
            mistakes += 1
            flickerToken = UUID()
            if mistakes >= 6 {
                endSession(victory: false)
            }
        }
    }

    func computeStarsRaw(success: Bool) -> Int {
        guard success else { return 0 }
        let elapsed = sessionElapsed()
        let clean = mistakes == 0
        if clean, elapsed < max(10, 28 - Double(min(level, 12))) {
            return 3
        }
        if mistakes <= 1 {
            return 2
        }
        return 1
    }

    private func tick() {
        guard sessionFinished == false, isPaused == false else { return }
        clock += (1 / 30) / period
        timeRemaining -= 1 / 30
        if timeRemaining <= 0 {
            timeRemaining = 0
            endSession(victory: successes >= tapsNeeded)
        }
    }

    private func endSession(victory: Bool) {
        guard sessionFinished == false else { return }
        sessionFinished = true
        sessionVictory = victory
        stopSession()
    }

    private func phase01() -> Double {
        clock - floor(clock)
    }
}
