import SwiftUI

/// Level tile for the Carnival grid: activity tint, stars, best line, locked state.
struct StageLevelPickerCell: View {
    let activity: ActivityRoute
    let level: Int
    let unlocked: Bool
    let stars: Int
    let bestCaption: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: activity.pickerGlyph)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [activity.pickerAccent, activity.pickerAccent.opacity(0.65)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(Color.appSurface.opacity(unlocked ? 0.55 : 0.35))
                                    .overlay(
                                        Circle()
                                            .strokeBorder(activity.pickerAccent.opacity(unlocked ? 0.45 : 0.15), lineWidth: 1)
                                    )
                            )
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Stage \(level)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.appTextSecondary)
                                .textCase(.uppercase)
                                .tracking(0.4)
                            Text("\(level)")
                                .font(.title2.weight(.heavy))
                                .foregroundStyle(Color.appTextPrimary)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: 4) {
                        ForEach(0 ..< 3, id: \.self) { index in
                            StarGlyph(filled: index < stars, diameter: 16)
                                .shadow(color: Color.appAccent.opacity(index < stars ? 0.35 : 0), radius: 4, y: 0)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    if let bestCaption {
                        Text(bestCaption)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("—")
                            .font(.caption2)
                            .foregroundStyle(Color.appTextSecondary.opacity(0.45))
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)

                if unlocked == false {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.75))
                        .padding(8)
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appSurface.opacity(unlocked ? 0.98 : 0.55),
                                Color.appSurface.opacity(unlocked ? 0.72 : 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: rimColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: unlocked ? 1.25 : 1
                            )
                    }
                    .shadow(color: activity.pickerAccent.opacity(unlocked ? 0.22 : 0), radius: unlocked ? 10 : 0, y: unlocked ? 4 : 0)
                    .shadow(color: Color.black.opacity(unlocked ? 0.28 : 0.12), radius: 8, y: 4)
            }
            .opacity(unlocked ? 1 : 0.52)
        }
        .buttonStyle(StageLevelCellPressStyle())
        .disabled(unlocked == false)
    }

    private var rimColors: [Color] {
        if unlocked {
            return [
                activity.pickerAccent.opacity(0.55),
                Color.appAccent.opacity(0.35),
                Color.white.opacity(0.12)
            ]
        }
        return [
            Color.appTextSecondary.opacity(0.22),
            Color.appTextSecondary.opacity(0.12)
        ]
    }
}

private struct StageLevelCellPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private extension ActivityRoute {
    var pickerGlyph: String {
        switch self {
        case .ringTwirl:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .flickCatch:
            return "hand.draw.fill"
        case .glowFlow:
            return "sparkles"
        }
    }

    var pickerAccent: Color {
        switch self {
        case .ringTwirl:
            return Color.appPrimary
        case .flickCatch, .glowFlow:
            return Color.appAccent
        }
    }
}
