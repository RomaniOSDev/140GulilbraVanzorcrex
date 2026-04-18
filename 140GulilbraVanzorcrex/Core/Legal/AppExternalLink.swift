import Foundation

/// Central place for outbound web URLs (privacy, terms, etc.).
enum AppExternalLink: String {
    case privacyPolicy = "https://gulilbravanzorcrex140.site/privacy/112"
    case termsOfUse = "https://gulilbravanzorcrex140.site/terms/112"

    var url: URL? {
        URL(string: rawValue)
    }
}
