import SwiftUI

struct GlowFlowView: View {
    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: GlowFlowViewModel
    @State private var didEmitOutcome = false
    @State private var flickerOpacity: Double = 1
    @State private var hintConfirm = false
    let onFinished: (SessionResultPayload) -> Void

    init(level: Int, difficulty: PlayDifficulty, onFinished: @escaping (SessionResultPayload) -> Void) {
        _model = StateObject(wrappedValue: GlowFlowViewModel(level: level, difficulty: difficulty))
        self.onFinished = onFinished
    }

    var body: some View {
        ZStack {
            SkyAtmosphereBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
                    flowBoard
                    footer
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.appSurface.opacity(0.75))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color.appTextSecondary.opacity(0.18), lineWidth: 1)
                                )
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(CarnivalLayout.padding)
            }
            .frame(maxWidth: .infinity)

            if model.isPaused, model.sessionFinished == false {
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
                if model.sessionFinished == false {
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
            Text("A hint widens the tap window briefly but lowers your best possible star rating by one if you clear the stage.")
        }
        .onAppear {
            didEmitOutcome = false
            model.startSession()
        }
        .onDisappear { model.stopSession() }
        .onChange(of: model.sessionFinished) { finished in
            guard finished, didEmitOutcome == false else { return }
            didEmitOutcome = true
            emitOutcome(success: model.sessionVictory)
        }
        .onChange(of: model.flickerToken) { _ in
            withAnimation(.easeInOut(duration: 0.12).repeatCount(5, autoreverses: true)) {
                flickerOpacity = 0.35
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                flickerOpacity = 1
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Glow Flow")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text("Tap the pulsing node only while the traveling highlight overlaps it.")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
            HStack {
                Text("Synced taps \(model.successes)/\(model.tapsNeeded)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                Spacer()
                Text("Slips \(model.mistakes)/6")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            Text("Time left: \(Int(ceil(model.timeRemaining)))s")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    private var flowBoard: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let centers = nodeCenters(count: model.nodeCount, in: size)
            ZStack {
                Path { path in
                    guard let first = centers.first else { return }
                    path.move(to: first)
                    for point in centers.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(
                    Color.appAccent.opacity(0.35 + Double(model.successes) * 0.02),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )

                ForEach(Array(centers.enumerated()), id: \.offset) { index, center in
                    let active = model.activeNodeIndex() == index
                    let windowOpen = model.windowContainsClock()
                    let highlight = active && windowOpen
                    Circle()
                        .fill(highlight ? Color.appPrimary : Color.appSurface.opacity(0.9))
                        .frame(width: highlight ? 54 : 46, height: highlight ? 54 : 46)
                        .overlay(
                            Circle()
                                .stroke(Color.appAccent.opacity(highlight ? 0.95 : 0.35), lineWidth: highlight ? 3 : 1)
                        )
                        .position(center)
                        .opacity(flickerOpacity)
                        .onTapGesture {
                            guard model.isPaused == false else { return }
                            model.handleTap(on: index)
                        }
                        .accessibilityAddTraits(.isButton)
                }
            }
            .frame(width: size.width, height: size.height)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.appSurface.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.appAccent.opacity(0.22), lineWidth: 1)
                    )
            )
        }
        .frame(height: 360)
    }

    private var footer: some View {
        Text("If the glow feels off-beat, pause a beat—the path rewards calm timing.")
            .font(.footnote)
            .foregroundStyle(Color.appTextSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func nodeCenters(count: Int, in size: CGSize) -> [CGPoint] {
        guard count > 0 else { return [] }
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * 0.32
        return (0 ..< count).map { index in
            let t = (Double(index) / Double(count)) * (2 * Double.pi) - Double.pi / 2
            let x = center.x + CGFloat(cos(t)) * radius
            let y = center.y + CGFloat(sin(t)) * radius
            return CGPoint(x: x, y: y)
        }
    }

    private func emitOutcome(success: Bool) {
        let before = gameState.unlockedAchievementIDs()
        let rawStars = model.computeStarsRaw(success: success)
        let stars = gameState.cappedStars(raw: rawStars, hintUsed: model.hintUsed)
        if success {
            gameState.recordGlowBest(
                activity: .glowFlow,
                level: model.level,
                elapsed: model.sessionElapsed(),
                mistakes: model.mistakes
            )
            gameState.registerDailySpotlightIfNeeded(activity: .glowFlow, level: model.level, success: true)
            gameState.applyStageResult(activity: .glowFlow, level: model.level, earnedStars: stars)
        }
        gameState.registerSessionFinished()
        let after = gameState.unlockedAchievementIDs()
        let fresh = Array(after.subtracting(before))

        let headline = success ? "Flow Complete" : "Flow Interrupted"
        var details: [String] = [
            "Stage \(model.level) • \(model.difficulty.title) pace",
            success
                ? "Finished in \(String(format: "%.1fs", model.sessionElapsed())) with \(model.mistakes) slips."
                : "Too many slips or the timer ran out."
        ]
        if success, model.hintUsed {
            details.append("Hint used — star ceiling reduced by one.")
        }

        let payload = SessionResultPayload(
            activity: .glowFlow,
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
