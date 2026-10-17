import SwiftUI

/// iOS symbol + tint for every provider the shared taxonomy knows.
///
/// The macOS build uses AppKit-era glyphs (`cat.fill`, `fox`) that iOS does not ship, so the
/// symbol is chosen here rather than in the shared model. The brand colour is shared.
extension TokenProvider {
    var tint: Color { Color(hex: color) }

    var iosSymbol: String {
        switch self {
        case .openai: return "brain.head.profile"
        case .claude: return "sparkles"
        case .gemini: return "star.fill"
        case .deepseek: return "magnifyingglass.circle.fill"
        case .github: return "chevron.left.forwardslash.chevron.right"
        case .gitlab: return "chevron.left.forwardslash.chevron.right"
        case .aws: return "cloud.fill"
        case .azure: return "building.2.fill"
        case .google: return "g.circle.fill"
        case .cloudflare: return "globe.americas.fill"
        case .telegram: return "paperplane.fill"
        case .discord: return "message.fill"
        case .slack: return "number"
        case .stripe: return "creditcard.fill"
        case .tailscale: return "point.3.connected.trianglepath.dotted"
        case .apple: return "apple.logo"
        case .docker: return "shippingbox.fill"
        case .vercel: return "triangle.fill"
        case .supabase: return "cylinder.split.1x2.fill"
        case .huggingface: return "face.smiling.fill"
        case .custom: return "key.fill"
        }
    }
}

extension TokenEnvironment {
    var shortLabel: String {
        switch self {
        case .development: return "DEV"
        case .staging: return "STG"
        case .production: return "PROD"
        }
    }
}

extension TokenItem {
    /// A copy of the secret that is safe to draw: first four and last four characters.
    var maskedPreview: String {
        let value = decryptedValue()
        guard value.count > 10 else { return String(repeating: "•", count: 10) }
        return "\(value.prefix(4))••••••\(value.suffix(4))"
    }
}
