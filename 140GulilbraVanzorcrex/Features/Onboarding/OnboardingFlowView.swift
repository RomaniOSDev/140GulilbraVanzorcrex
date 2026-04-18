import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var pageIndex = 0
    @State private var heroScale: CGFloat = 0.94
    @State private var heroOpacity: Double = 0.7

    private let pages = OnboardingPageModel.pages

    var body: some View {
        VStack(spacing: 0) {
            topChrome

            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    onboardingPageContent(page: page, pageIndex: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity)
           // .frame(maxHeight: 440)
            .padding(.horizontal, 6)
            .padding(.top, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.appSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.appTextSecondary.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, CarnivalLayout.padding)

            CarnivalPageControl(pageCount: pages.count, currentPage: pageIndex)
                .padding(.top, 12)

            bottomActions
                .padding(.horizontal, CarnivalLayout.padding)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: pageIndex) { _ in
            heroScale = 0.94
            heroOpacity = 0.7
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                heroScale = 1
                heroOpacity = 1
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                heroScale = 1
                heroOpacity = 1
            }
        }
    }

    private var topChrome: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Text("Quick tour")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 8)
            Button("Skip", action: finish)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.appSurface.opacity(0.55))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.appAccent.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 8, y: 4)
        }
        .padding(.horizontal, CarnivalLayout.padding)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private func onboardingPageContent(page: OnboardingPageModel, pageIndex index: Int) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                stepStrip(selected: index)
                    .padding(.top, 4)

                illustrationStage(for: index)
                    .frame(height: 220)
                    .scaleEffect(heroScale)
                    .opacity(heroOpacity)
                    .animation(.spring(response: 0.5, dampingFraction: 0.78), value: pageIndex)

                VStack(spacing: 12) {
                    Image(systemName: page.headerIcon)
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appPrimary.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.appAccent.opacity(0.35), radius: 12, y: 4)

                    Text(page.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)

                    Text(page.message)
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 6)
                        
                }
                .padding(.bottom, 8)
            }
            .padding(.vertical, 10)
        }
    }

    private func stepStrip(selected: Int) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    Button {
                        withAnimation(CarnivalSpring.interactive) {
                            pageIndex = index
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: page.tabIcon)
                                .font(.caption.weight(.bold))
                            Text(page.shortTab)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(selected == index ? Color.appBackground : Color.appTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            Group {
                                if selected == index {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.appPrimary, Color.appAccent.opacity(0.92)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                } else {
                                    Capsule()
                                        .fill(Color.appSurface.opacity(0.45))
                                }
                            }
                        }
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    Color.appAccent.opacity(selected == index ? 0.5 : 0.18),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(selected == index ? 0.22 : 0.08), radius: selected == index ? 6 : 3, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func illustrationStage(for index: Int) -> some View {
        switch index {
        case 0:
            OnboardingRingIllustration()
        case 1:
            OnboardingStarIllustration()
        default:
            OnboardingTriadIllustration()
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 12) {
            if pageIndex > 0 {
                Button(action: goBack) {
                    Text("Back")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(minHeight: CarnivalLayout.minimumTap)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.appSurface.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.appAccent.opacity(0.35), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
            }

            Button(action: pageIndex < pages.count - 1 ? advance : finish) {
                Text(pageIndex < pages.count - 1 ? "Next" : "Get started")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(Color.appBackground)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(minHeight: CarnivalLayout.minimumTap)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.appPrimary, Color.appAccent.opacity(0.88)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                    )
                    .shadow(color: Color.appPrimary.opacity(0.45), radius: 18, y: 10)
                    .shadow(color: Color.appAccent.opacity(0.2), radius: 24, y: 8)
            }
            .buttonStyle(.plain)
        }
    }

    private func goBack() {
        withAnimation(CarnivalSpring.interactive) {
            pageIndex = max(0, pageIndex - 1)
        }
    }

    private func advance() {
        withAnimation(CarnivalSpring.interactive) {
            pageIndex = min(pageIndex + 1, pages.count - 1)
        }
    }

    private func finish() {
        withAnimation(CarnivalSpring.interactive) {
            gameState.completeOnboarding()
        }
    }
}

// MARK: - Page model

private struct OnboardingPageModel {
    let shortTab: String
    let tabIcon: String
    let headerIcon: String
    let title: String
    let message: String

    static let pages: [OnboardingPageModel] = [
        OnboardingPageModel(
            shortTab: "Intro",
            tabIcon: "sparkles",
            headerIcon: "party.popper.fill",
            title: "Coordination Carnival",
            message: "Swipe the cards for a quick tour, then jump into bite-sized challenges made for short breaks."
        ),
        OnboardingPageModel(
            shortTab: "Stars",
            tabIcon: "star.fill",
            headerIcon: "star.circle.fill",
            title: "Stars, not stuff",
            message: "Up to three stars per stage unlock what comes next—no extra wallets or currencies."
        ),
        OnboardingPageModel(
            shortTab: "Modes",
            tabIcon: "square.grid.3x3.fill",
            headerIcon: "bolt.horizontal.fill",
            title: "Three playful modes",
            message: "Twirl rings, flick orbs, and sync glowing paths. Each mode respects the pace you pick in play."
        )
    ]
}

// MARK: - Illustrations

private struct OnboardingRingIllustration: View {
    @State private var spin = false

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color.appAccent.opacity(0.35), Color.appPrimary.opacity(0.12), Color.clear],
                center: .center,
                startRadius: 8,
                endRadius: 140
            )
            .allowsHitTesting(false)

            ForEach(0 ..< 3, id: \.self) { index in
                RingStroke(radius: CGFloat(102 - index * 26))
                    .stroke(
                        AngularGradient(
                            colors: [Color.appAccent, Color.appPrimary, Color.appAccent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 9 - CGFloat(index), lineCap: .round)
                    )
                    .rotationEffect(.degrees(spin ? Double(index + 1) * 16 : 0))
                    .shadow(color: Color.appAccent.opacity(0.25), radius: 12, y: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.appSurface.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                spin.toggle()
            }
        }
    }
}

private struct RingStroke: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: .degrees(-10), endAngle: .degrees(320), clockwise: false)
        return path
    }
}

private struct OnboardingStarIllustration: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color.appAccent.opacity(0.4), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 130
            )

            HStack(spacing: 20) {
                ForEach(0 ..< 3, id: \.self) { index in
                    StarGlyph(filled: true, diameter: 46)
                        .shadow(color: Color.appAccent.opacity(0.55), radius: pulse ? 14 : 6)
                        .scaleEffect(pulse ? 1.06 + CGFloat(index) * 0.02 : 0.9)
                        .animation(
                            .easeInOut(duration: 1.05).repeatForever(autoreverses: true).delay(Double(index) * 0.1),
                            value: pulse
                        )
                }
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.appSurface.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear { pulse = true }
    }
}

private struct OnboardingTriadIllustration: View {
    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.appSurface.opacity(0.25))
                    .padding(12)

                Path { path in
                    path.move(to: CGPoint(x: center.x - geo.size.width * 0.28, y: center.y + 36))
                    path.addQuadCurve(
                        to: CGPoint(x: center.x + geo.size.width * 0.28, y: center.y + 36),
                        control: CGPoint(x: center.x, y: center.y - geo.size.height * 0.28)
                    )
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.85), Color.appAccent.opacity(0.75)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .shadow(color: Color.appPrimary.opacity(0.35), radius: 8, y: 0)

                HStack(spacing: geo.size.width * 0.18) {
                    modeOrb(symbol: "circle.dotted", active: drift)
                    modeOrb(symbol: "arrow.up.forward.circle.fill", active: drift == false)
                    modeOrb(symbol: "point.3.connected.trianglepath.dotted", active: drift)
                }
                .offset(y: drift ? -5 : 7)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.appSurface.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.65).repeatForever(autoreverses: true)) {
                drift.toggle()
            }
        }
    }

    private func modeOrb(symbol: String, active: Bool) -> some View {
        Image(systemName: symbol)
            .font(.title2.weight(.semibold))
            .foregroundStyle(
                LinearGradient(
                    colors: active
                        ? [Color.appAccent, Color.appPrimary]
                        : [Color.appTextSecondary.opacity(0.65), Color.appTextSecondary.opacity(0.45)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 52, height: 52)
            .background(
                Circle()
                    .fill(Color.appSurface.opacity(active ? 0.65 : 0.4))
            )
            .overlay(
                Circle()
                    .strokeBorder(Color.appAccent.opacity(active ? 0.55 : 0.2), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(active ? 0.35 : 0.15), radius: active ? 10 : 4, y: 4)
    }
}
