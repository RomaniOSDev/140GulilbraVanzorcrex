import SwiftUI
import UIKit

struct FlickCatchView: View {
    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: FlickCatchViewModel
    @State private var didEmitOutcome = false
    @State private var sessionStarted = false
    @State private var hintConfirm = false
    @State private var lastCatchCount = 0
    @State private var catchVfxCenter = CGPoint.zero
    @State private var catchRingScale: CGFloat = 0.2
    @State private var catchRingOpacity: Double = 0
    @State private var catchBadgeScale: CGFloat = 0.2
    @State private var catchBadgeOpacity: Double = 0
    @State private var basketDragOriginX: CGFloat?
    let onFinished: (SessionResultPayload) -> Void

    init(level: Int, difficulty: PlayDifficulty, onFinished: @escaping (SessionResultPayload) -> Void) {
        _model = StateObject(wrappedValue: FlickCatchViewModel(level: level, difficulty: difficulty))
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
                    playfield
                    tips
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
            Text("A hint softens gravity briefly but lowers your best possible star rating by one if you clear the stage.")
        }
        .onAppear {
            didEmitOutcome = false
        }
        .onChange(of: model.sessionFinished) { finished in
            guard finished, didEmitOutcome == false else { return }
            didEmitOutcome = true
            emitOutcome(success: model.sessionVictory)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Flick n' Catch")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            HStack {
                Label("Lives \(model.lives)", systemImage: "heart.fill")
                    .foregroundStyle(Color.appAccent)
                Spacer()
                Label("Goal \(model.catches)/\(model.targetCatches)", systemImage: "target")
                    .foregroundStyle(Color.appPrimary)
            }
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            Text("Time left: \(Int(ceil(model.timeRemaining)))s")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    private var playfield: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let basketX = model.basketCenterX(in: size)
            let basketY = size.height - 64
            let basketCenterPointY = basketY + 1
            ZStack {
                if catchRingOpacity > 0.02 || catchBadgeOpacity > 0.02 {
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.appAccent, Color.appPrimary.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 46, height: 46)
                            .scaleEffect(catchRingScale)
                            .opacity(catchRingOpacity)
                        Circle()
                            .stroke(Color.appAccent.opacity(0.35), lineWidth: 2)
                            .frame(width: 46, height: 46)
                            .scaleEffect(catchRingScale * 0.78)
                            .opacity(catchRingOpacity * 0.85)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(Color.appAccent)
                            .scaleEffect(catchBadgeScale)
                            .opacity(catchBadgeOpacity)
                            .shadow(color: Color.appAccent.opacity(0.55), radius: 10, y: 0)
                    }
                    .position(catchVfxCenter)
                    .allowsHitTesting(false)
                }

                ZStack {
                    Color.clear
                        .frame(width: 168, height: 48)
                        .contentShape(Rectangle())
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.appPrimary.opacity(0.88))
                        .frame(width: 116, height: 26)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.appAccent.opacity(0.95), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.25), radius: 6, y: 3)
                }
                .position(x: basketX, y: basketCenterPointY)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard model.sessionFinished == false, model.isPaused == false else { return }
                            if basketDragOriginX == nil {
                                basketDragOriginX = model.basketCenterX(in: size)
                            }
                            model.setBasketCenterX(
                                (basketDragOriginX ?? basketX) + value.translation.width,
                                playfieldWidth: size.width
                            )
                        }
                        .onEnded { _ in
                            basketDragOriginX = nil
                        }
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Catch basket")
                .accessibilityHint("Drag horizontally to move under falling orbs.")

                ForEach(model.orbs) { orb in
                    Circle()
                        .fill(Color.appAccent)
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle()
                                .stroke(Color.appTextPrimary.opacity(0.35), lineWidth: 1)
                        )
                        .position(orb.position)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    model.flickOrb(id: orb.id, translation: value.translation)
                                }
                        )
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
            .onAppear {
                model.updateFieldSize(size)
                if sessionStarted == false {
                    sessionStarted = true
                    lastCatchCount = 0
                    model.startSession(in: size)
                }
            }
            .onChange(of: model.catches) { newValue in
                if newValue == 0 {
                    lastCatchCount = 0
                    return
                }
                guard newValue > lastCatchCount else { return }
                lastCatchCount = newValue
                catchVfxCenter = CGPoint(x: basketX, y: basketCenterPointY)
                playCatchCelebration()
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.prepare()
                impact.impactOccurred(intensity: 0.75)
            }
        }
        .frame(height: 420)
    }

    private func playCatchCelebration() {
        catchRingScale = 0.22
        catchRingOpacity = 1
        catchBadgeScale = 0.4
        catchBadgeOpacity = 1
        withAnimation(.easeOut(duration: 0.5)) {
            catchRingScale = 2.45
            catchRingOpacity = 0
        }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.58)) {
            catchBadgeScale = 1
        }
        withAnimation(.easeOut(duration: 0.28).delay(0.18)) {
            catchBadgeOpacity = 0
            catchBadgeScale = 1.12
        }
    }

    private var tips: some View {
        Text("Drag the basket side to side to catch orbs. Flick an orb upward to tweak its arc toward the basket.")
            .font(.footnote)
            .foregroundStyle(Color.appTextSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func emitOutcome(success: Bool) {
        let before = gameState.unlockedAchievementIDs()
        let rawStars = model.computeStarsRaw(success: success)
        let stars = gameState.cappedStars(raw: rawStars, hintUsed: model.hintUsed)
        if success {
            gameState.recordFlickBest(activity: .flickCatch, level: model.level, catches: model.catches)
            gameState.registerDailySpotlightIfNeeded(activity: .flickCatch, level: model.level, success: true)
            gameState.applyStageResult(activity: .flickCatch, level: model.level, earnedStars: stars)
        }
        gameState.registerSessionFinished()
        let after = gameState.unlockedAchievementIDs()
        let fresh = Array(after.subtracting(before))

        let headline = success ? "Nice Catches" : "Basket Still Hungry"
        var details: [String] = [
            "Stage \(model.level) • \(model.difficulty.title) pace",
            success
                ? "Caught \(model.catches) in \(String(format: "%.1fs", model.sessionElapsed()))"
                : "Lives depleted or timer ended before the goal."
        ]
        if success, model.hintUsed {
            details.append("Hint used — star ceiling reduced by one.")
        }

        let payload = SessionResultPayload(
            activity: .flickCatch,
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
