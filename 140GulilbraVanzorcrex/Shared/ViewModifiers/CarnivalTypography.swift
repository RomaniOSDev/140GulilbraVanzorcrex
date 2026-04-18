import SwiftUI

extension View {
    func carnivalSingleLineTitle() -> some View {
        lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

struct CarnivalSpring {
    static let interactive = Animation.spring(response: 0.4, dampingFraction: 0.7)
}

enum CarnivalLayout {
    static let padding: CGFloat = 16
    static let minimumTap: CGFloat = 44
}
