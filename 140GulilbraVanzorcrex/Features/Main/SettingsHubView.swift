import StoreKit
import SwiftUI
import UIKit

struct SettingsHubView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    settingsRow(
                        title: "Rate us",
                        subtitle: "Leave a quick rating if you enjoy the app.",
                        systemImage: "star.fill",
                        tint: Color.appAccent
                    ) {
                        rateApp()
                    }

                    settingsRow(
                        title: "Privacy Policy",
                        subtitle: "How we handle data when you play.",
                        systemImage: "hand.raised.fill",
                        tint: Color.appPrimary
                    ) {
                        openExternalLink(.privacyPolicy)
                    }

                    settingsRow(
                        title: "Terms of Use",
                        subtitle: "Rules for using the app.",
                        systemImage: "doc.text.fill",
                        tint: Color.appPrimary
                    ) {
                        openExternalLink(.termsOfUse)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(CarnivalLayout.padding)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SkyAtmosphereBackground())
        }
    }

    private func settingsRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: CarnivalLayout.minimumTap, height: CarnivalLayout.minimumTap)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.appSurface.opacity(0.55))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(tint.opacity(0.35), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.appTextSecondary.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func openExternalLink(_ link: AppExternalLink) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
