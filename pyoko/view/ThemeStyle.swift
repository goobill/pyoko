import SwiftUI

/// Applies the selected palette and optional tint override to each app window.
private struct ThemeStyle: ViewModifier {
    @AppStorage("themePreference") private var themeValue = "classic"
    @AppStorage("tintPreference") private var tintValue = "automatic"
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        let theme = PyokoTheme(rawValue: themeValue) ?? .classic
        let tint = PyokoTint(rawValue: tintValue) ?? theme.accent
        content.tint(tint.color(for: scheme))
    }
}

private struct ThemeSurface: ViewModifier {
    @AppStorage("themePreference") private var themeValue = "classic"
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        let theme = PyokoTheme(rawValue: themeValue) ?? .classic
        content.scrollContentBackground(.hidden)
            .background(theme.background(for: scheme).ignoresSafeArea())
    }
}

extension View {
    func pyokoTheme() -> some View { modifier(ThemeStyle()) }
    func pyokoSurface() -> some View { modifier(ThemeSurface()) }
}
