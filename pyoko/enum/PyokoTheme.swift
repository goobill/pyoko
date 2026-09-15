import SwiftUI

/// Stable preference keys; themes change presentation without touching study data.
enum PyokoTheme: String, CaseIterable, Identifiable {
    case classic, ruby, sunset, forest, ocean, indigo, plum, rose, slate, mono
    var id: String { rawValue }
    var title: String {
        switch self {
        case .classic: return "Classic"
        case .ruby: return "Ruby"
        case .sunset: return "Sunset"
        case .forest: return "Forest"
        case .ocean: return "Ocean"
        case .indigo: return "Indigo"
        case .plum: return "Plum"
        case .rose: return "Rose"
        case .slate: return "Slate"
        case .mono: return "Mono"
        }
    }
    var accent: PyokoTint {
        switch self {
        case .classic: return .blue
        case .ruby: return .red
        case .sunset: return .orange
        case .forest: return .green
        case .ocean: return .teal
        case .indigo: return .indigo
        case .plum: return .purple
        case .rose: return .pink
        case .slate: return .grey
        case .mono: return .black
        }
    }
    func background(for scheme: ColorScheme) -> Color {
        let rgb = accent.rgb
        // A subtle palette wash; dark surfaces stay dark enough for semantic text.
        let base = scheme == .dark ? 0.075 : 0.96
        let amount = scheme == .dark ? 0.065 : 0.025
        return Color(red: base + rgb.0 * amount, green: base + rgb.1 * amount, blue: base + rgb.2 * amount)
    }
}

enum PyokoTint: String, CaseIterable, Identifiable {
    case blue, red, orange, green, teal, indigo, purple, pink, grey, black
    var id: String { rawValue }
    var title: String { rawValue == "black" ? "Charcoal" : rawValue.capitalized }
    var rgb: (Double, Double, Double) {
        switch self {
        case .blue: return (0.05, 0.34, 0.78)
        case .red: return (0.72, 0.12, 0.16)
        case .orange: return (0.68, 0.28, 0.02)
        case .green: return (0.12, 0.43, 0.23)
        case .teal: return (0.02, 0.42, 0.46)
        case .indigo: return (0.31, 0.27, 0.69)
        case .purple: return (0.52, 0.23, 0.66)
        case .pink: return (0.69, 0.19, 0.40)
        case .grey: return (0.38, 0.41, 0.45)
        case .black: return (0.10, 0.10, 0.11)
        }
    }
    func color(for scheme: ColorScheme) -> Color {
        let rgb = rgb
        let lift = scheme == .dark ? 0.40 : 0.0
        return Color(red: rgb.0 + (1 - rgb.0) * lift,
                     green: rgb.1 + (1 - rgb.1) * lift,
                     blue: rgb.2 + (1 - rgb.2) * lift)
    }
}
