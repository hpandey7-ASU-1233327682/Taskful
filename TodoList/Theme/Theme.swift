import SwiftUI

/// The app's colors in one place. This is the Sunset palette: orange to pink.
enum Theme {
    static let gradientStart = Color(red: 1.00, green: 0.54, blue: 0.00)
    static let gradientEnd = Color(red: 0.91, green: 0.12, blue: 0.39)

    /// Used for tags, selected chips and buttons.
    static let accent = gradientEnd

    static let high = Color(red: 0.90, green: 0.22, blue: 0.21)
    static let medium = Color(red: 1.00, green: 0.63, blue: 0.00)
    static let low = Color(red: 0.26, green: 0.63, blue: 0.28)

    static let headerGradient = LinearGradient(
        colors: [gradientStart, gradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Priority {
    var color: Color {
        switch self {
        case .low: return Theme.low
        case .medium: return Theme.medium
        case .high: return Theme.high
        }
    }
}
