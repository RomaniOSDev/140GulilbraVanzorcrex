import SwiftUI

struct RingTwirlView: View {
    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: RingTwirlViewModel
    @State private var shake = false
    @State private var didEmitOutcome = false
    @State private var dragLastAngle: Double?
    @State private var dragActiveRing: Int?
    @State private var hintConfirm = false
    let onFinished: (SessionResultPayload) -> Void

    init(level: Int, difficulty: PlayDifficulty, onFinished: @escaping (SessionResultPayload) -> Void) {
        _model = StateObject(wrappedValue: RingTwirlViewModel(level: level, difficulty: difficulty))
        self.onFinished = onFinished
    }

    var body: some View {
        ZStack {
            SkyAtmosphereBackground()
            VStack(spacing: 16) {
                header
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.appSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.appTextSecondary.opacity(0.2), lineWidth: 1)
                            )
                    )
                ringStage
                Spacer(minLength: 0)
                footerHints
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(CarnivalLayout.padding)

            if model.isPaused, model.phase == .playing {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                Text("Paused")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.appSurface.opacity(0.75))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.appAccent.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.32), radius: 12, y: 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
                    .foregroundStyle(Color.appAccent)
                    .frame(minHeight: CarnivalLayout.minimumTap)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                if model.phase == .playing {
                    Button(model.isPaused ? "Resume" : "Pause") {
                        model.setPaused(model.isPaused == false)
                    }
                    .foregroundStyle(Color.appAccent)
                    .frame(minHeight: CarnivalLayout.minimumTap)

                    Button("Hint") {
                        hintConfirm = true
                    }
                    .foregroundStyle(model.hintUsed ? Color.appTextSecondary : Color.appAccent)
                    .disabled(model.hintUsed)
                    .frame(minHeight: CarnivalLayout.minimumTap)
                }
            }
        }
        .alert("Use a hint?", isPresented: $hintConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Use hint") {
                model.activateHint()
            }
        } message: {
            Text("A hint lowers your best possible star rating by one on this attempt if you clear the stage.")
        }
        .onAppear {
            didEmitOutcome = false
            model.startSession()
        }
        .onDisappear { model.stopSession() }
        .onChange(of: model.phase) { newValue in
            switch newValue {
            case .successPulse:
                emitOutcome(success: true)
            case .failedShake:
                withAnimation(.easeInOut(duration: 0.08).repeatCount(6, autoreverses: true)) {
                    shake = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    shake = false
                    emitOutcome(success: false)
                }
            default:
                break
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ring Twirl")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text("Drag in a circle on a ring to spin it. Line the bright bands with the top marker.")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
            ProgressView(value: min(1, model.elapsed / max(model.sessionTimeLimit, 1)))
                .tint(Color.appAccent)
            Text("Hold steady for a short beat once everything lines up.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    private var ringStage: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                ForEach(0 ..< 3, id: \.self) { index in
                    TwirlRingVisual(index: index, angle: model.ringAngles[index])
                }

                if model.showHintGuide {
                    HintUpstroke(center: center)
                }

                VStack(spacing: 6) {
                    Capsule()
                        .fill(Color.appTextPrimary)
                        .frame(width: 6, height: 22)
                    Text("Top")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .offset(y: -150)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(ringDragGesture(center: center))
        }
        .frame(height: 320)
        .scaleEffect(model.phase == .successPulse ? 1.04 : 1.0)
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: model.phase)
        .offset(x: shake ? 10 : 0)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.appSurface.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.22), lineWidth: 1)
                )
        )
    }

    private func ringDragGesture(center: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard model.phase == .playing, model.isPaused == false else { return }
                let point = value.location
                let dx = point.x - center.x
                let dy = point.y - center.y
                let distance = hypot(dx, dy)
                guard distance > 16 else { return }

                let angle = atan2(Double(dy), Double(dx))
                let ring = ringIndex(forDistance: distance)

                if dragActiveRing == nil {
                    dragActiveRing = ring
                }
                guard let activeRing = dragActiveRing else { return }

                if let previous = dragLastAngle {
                    let delta = shortestAngleDelta(from: previous, to: angle)
                    model.addRotation(ring: activeRing, delta: delta)
                }
                dragLastAngle = angle
            }
            .onEnded { _ in
                dragLastAngle = nil
                dragActiveRing = nil
            }
    }

    private func ringIndex(forDistance distance: CGFloat) -> Int {
        if distance > 116.5 {
            return 0
        }
        if distance > 89.5 {
            return 1
        }
        return 2
    }

    @ViewBuilder
    private var footerHints: some View {
        if model.phase == .playing {
            Text("Alignment: \(Int(model.alignedHoldProgress * 100))%")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.appSurface.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.appTextSecondary.opacity(0.18), lineWidth: 1)
                        )
                )
        }
    }

    private func emitOutcome(success: Bool) {
        guard didEmitOutcome == false else { return }
        didEmitOutcome = true

        let before = gameState.unlockedAchievementIDs()
        let rawStars = model.computeStarsRaw(success: success)
        let stars = gameState.cappedStars(raw: rawStars, hintUsed: model.hintUsed)
        if success {
            gameState.recordRingBest(activity: .ringTwirl, level: model.level, clearSeconds: model.elapsed)
            gameState.registerDailySpotlightIfNeeded(activity: .ringTwirl, level: model.level, success: true)
            gameState.applyStageResult(activity: .ringTwirl, level: model.level, earnedStars: stars)
        }
        gameState.registerSessionFinished()
        let after = gameState.unlockedAchievementIDs()
        let fresh = Array(after.subtracting(before))

        let headline = success ? "Stage Cleared" : "Keep Twisting"
        var details: [String] = [
            "Stage \(model.level) • \(model.difficulty.title) pace",
            success
                ? "Elapsed: \(String(format: "%.1fs", model.elapsed))"
                : "The timer ended before the bands settled."
        ]
        if success, model.hintUsed {
            details.append("Hint used — star ceiling reduced by one.")
        }

        let payload = SessionResultPayload(
            activity: .ringTwirl,
            level: model.level,
            difficulty: model.difficulty,
            stars: stars,
            headline: headline,
            details: details,
            sessionSucceeded: success,
            newlyUnlockedAchievementIDs: fresh,
            hintUsed: model.hintUsed
        )
        onFinished(payload)
    }
}

private struct HintUpstroke: View {
    let center: CGPoint

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: center.x, y: center.y - 12))
            path.addLine(to: CGPoint(x: center.x, y: center.y - 140))
        }
        .stroke(Color.appAccent.opacity(0.85), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [7, 5]))
        .allowsHitTesting(false)
    }
}

private func shortestAngleDelta(from previous: Double, to current: Double) -> Double {
    var delta = current - previous
    if delta > .pi {
        delta -= 2 * .pi
    }
    if delta < -.pi {
        delta += 2 * .pi
    }
    return delta
}

private struct TwirlRingVisual: View {
    let index: Int
    let angle: Double

    var body: some View {
        RingArcShape(segmentCount: 10, activeRange: 3 ... 7)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [Color.appAccent, Color.appPrimary]),
                    center: .center
                ),
                style: StrokeStyle(lineWidth: CGFloat(14 - index * 3), lineCap: .round)
            )
            .frame(width: CGFloat(260 - index * 54), height: CGFloat(260 - index * 54))
            .rotationEffect(.radians(angle))
            .allowsHitTesting(false)
    }
}

private struct RingArcShape: Shape {
    let segmentCount: Int
    let activeRange: ClosedRange<Int>

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let slice = (2 * Double.pi) / Double(segmentCount)
        for index in activeRange {
            let start = Double(index) * slice - Double.pi / 2
            let end = Double(index + 1) * slice - Double.pi / 2
            path.addArc(center: center, radius: radius, startAngle: .radians(start), endAngle: .radians(end), clockwise: false)
        }
        return path
    }
}
