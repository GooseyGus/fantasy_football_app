import SwiftUI
import UIKit

// The Metronome app's Navy palette: navy #0A2947, brown #8B5E3C, sage #D3D4C0 and cream #F3E4C9.
// There's one look for now, dark; a light version can come later.
extension Color {
    /// Behind everything.
    static let paper = Color(hex: 0x0A2947)
    /// Behind each card and the text field: the navy lifted slightly towards the cream.
    static let card = Color(hex: 0x1B3A58)
    /// Text.
    static let ink = Color(hex: 0xF3E4C9)
    /// Links, small buttons, the vice-captain's badge, and anything that needs attention.
    static let soft = Color(hex: 0xD3D4C0)
    /// The main action and the captain's badge, like the Metronome's Start button.
    static let highlight = Color(hex: 0x8B5E3C)

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// The Metronome app's font. It comes with iOS and only has a bold weight.
extension Font {
    static let dinName = "DINAlternate-Bold"
    /// How much bigger than the system text sizes the app's text is.
    static let dinScale: CGFloat = 1.2

    /// DIN a little bigger than a system text style, growing with the reader's text size setting.
    static func din(_ style: Font.TextStyle) -> Font {
        .custom(dinName, size: UIFont.preferredFont(forTextStyle: style.uiKit).pointSize * dinScale, relativeTo: style)
    }
}

extension UIFont {
    static func din(_ style: UIFont.TextStyle) -> UIFont {
        UIFont(name: Font.dinName, size: UIFont.preferredFont(forTextStyle: style).pointSize * Font.dinScale)
            ?? .preferredFont(forTextStyle: style)
    }
}

private extension Font.TextStyle {
    var uiKit: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }
}

/// A full-width rounded button. The primary one is dim until it can be pressed, then snaps to the highlight colour.
struct BigButtonStyle: ButtonStyle {
    var isPrimary = true
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.din(.headline))
            .tracking(1.5)
            .foregroundStyle(isEnabled ? Color.ink : Color.ink.opacity(0.4))
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isPrimary && isEnabled ? Color.highlight : Color.card.opacity(isPrimary ? 0.5 : 1))
            )
            .overlay {
                if !isPrimary {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.ink.opacity(0.2), lineWidth: 1.5)
                }
            }
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    /// Puts a list or form on the app's background instead of the system grey.
    func themedList() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.paper)
    }
}
