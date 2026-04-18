import SwiftUI

struct CarnivalPageControl: View {
    let pageCount: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< pageCount, id: \.self) { index in
                let selected = index == currentPage
                Circle()
                    .fill(selected ? Color.appAccent : Color.appTextSecondary.opacity(0.35))
                    .frame(width: selected ? 9 : 7, height: selected ? 9 : 7)
            }
        }
        .animation(.easeOut(duration: 0.2), value: currentPage)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(currentPage + 1) of \(pageCount)")
    }
}
