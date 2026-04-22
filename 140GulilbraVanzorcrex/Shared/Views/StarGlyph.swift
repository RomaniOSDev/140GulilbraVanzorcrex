import SwiftUI

struct StarGlyph: View {
    let filled: Bool
    let diameter: CGFloat

    init(filled: Bool, diameter: CGFloat = 18) {
        self.filled = filled
        self.diameter = diameter
    }

    var body: some View {
        StarFiveShape()
            .fill(fillColor)
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
    }

    private var fillColor: Color {
        filled ? Color.appAccent : Color.appTextSecondary.opacity(0.35)
    }
}

private struct StarFiveShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let inner = radius * 0.42
        let step = CGFloat.pi / 5
        var path = Path()
        let firstAngle = -CGFloat.pi / 2
        let firstR = radius
        let firstX = center.x + cos(firstAngle) * firstR
        let firstY = center.y + sin(firstAngle) * firstR
        path.move(to: CGPoint(x: firstX, y: firstY))
        for index in 1 ..< 10 {
            let angle = -CGFloat.pi / 2 + CGFloat(index) * step
            let r = index.isMultiple(of: 2) ? radius : inner
            let x = center.x + cos(angle) * r
            let y = center.y + sin(angle) * r
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.closeSubpath()
        return path
    }
}

struct StarRow: View {
    let earned: Int
    let spacing: CGFloat

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0 ..< 3, id: \.self) { index in
                StarGlyph(filled: index < earned)
            }
        }
    }
}


struct GulibraVanzorcrexLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Image("AppIconImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.8)
                    .padding(.top, 30)
            }
        }
    }
}
