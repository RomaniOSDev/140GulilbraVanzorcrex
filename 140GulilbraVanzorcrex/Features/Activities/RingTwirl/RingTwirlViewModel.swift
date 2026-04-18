import Combine
import Foundation

@MainActor
final class RingTwirlViewModel: ObservableObject {
    enum Phase: Equatable {
        case playing
        case successPulse
        case failedShake
        case idle
    }

    @Published private(set) var ringAngles: [Double]
    @Published private(set) var phase: Phase = .playing
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var alignedHoldProgress: Double = 0
    @Published private(set) var isPaused = false
    @Published private(set) var hintUsed = false
    @Published private(set) var showHintGuide = false

    let level: Int
    let difficulty: PlayDifficulty
    let sessionTimeLimit: TimeInterval

    private let targetAngle = -Double.pi / 2
    private let tolerance: Double
    private var alignedSince: Date?
    private var startDate = Date()
    private var timerCancellable: AnyCancellable?

    init(level: Int, difficulty: PlayDifficulty) {
        self.level = level
        self.difficulty = difficulty
        let lv = Double(min(level, 12))
        sessionTimeLimit = max(22, 52 - lv * 2.2)
        let baseTolerance = (0.38 - lv * 0.02) * difficulty.ringToleranceMultiplier
        tolerance = max(0.11, baseTolerance)
        ringAngles = (0 ..< 3).map { _ in Double.random(in: 0 ..< (2 * .pi)) }
    }

    func startSession() {
        phase = .playing
        isPaused = false
        hintUsed = false
        showHintGuide = false
        startDate = Date()
        alignedSince = nil
        alignedHoldProgress = 0
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stopSession() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func setPaused(_ value: Bool) {
        isPaused = value
    }

    func activateHint() {
        guard hintUsed == false, phase == .playing else { return }
        hintUsed = true
        showHintGuide = true
    }

    func addRotation(ring index: Int, delta: Double) {
        guard phase == .playing, isPaused == false else { return }
        guard index >= 0, index < ringAngles.count else { return }
        var next = ringAngles
        next[index] = Self.normalize(radians: next[index] + delta)
        ringAngles = next
    }

    func computeStarsRaw(success: Bool) -> Int {
        guard success else { return 0 }
        let duration = Date().timeIntervalSince(startDate)
        let crisp = ringAngles.allSatisfy { Self.shortestDelta($0, target: targetAngle) < tolerance * 0.55 }
        if duration < max(6, 22 - Double(level) * 1.1), crisp {
            return 3
        }
        if duration < max(10, 30 - Double(level) * 1.0) {
            return 2
        }
        return 1
    }

    private func tick() {
        guard phase == .playing, isPaused == false else { return }
        elapsed = Date().timeIntervalSince(startDate)

        if elapsed > sessionTimeLimit {
            fail()
            return
        }

        let aligned = ringAngles.allSatisfy { Self.shortestDelta($0, target: targetAngle) < tolerance }
        let now = Date()
        if aligned {
            if alignedSince == nil {
                alignedSince = now
            }
            if let start = alignedSince {
                let hold = now.timeIntervalSince(start)
                alignedHoldProgress = min(1, hold / 0.32)
                if hold >= 0.32 {
                    succeed()
                }
            }
        } else {
            alignedSince = nil
            alignedHoldProgress = 0
        }
    }

    private func succeed() {
        guard phase == .playing else { return }
        phase = .successPulse
        stopSession()
    }

    private func fail() {
        guard phase == .playing else { return }
        phase = .failedShake
        stopSession()
    }

    private static func normalize(radians value: Double) -> Double {
        var v = value.truncatingRemainder(dividingBy: 2 * .pi)
        if v < 0 { v += 2 * .pi }
        return v
    }

    private static func shortestDelta(_ value: Double, target: Double) -> Double {
        var delta = value - target
        delta = delta.truncatingRemainder(dividingBy: 2 * .pi)
        if delta > .pi {
            delta -= 2 * .pi
        }
        if delta < -.pi {
            delta += 2 * .pi
        }
        return abs(delta)
    }
}
