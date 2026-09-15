import SwiftUI

extension View {
    /// Adds an unmodified study shortcut on Mac; iPhone retains its touch controls.
    @ViewBuilder
    func macReviewShortcut(_ key: KeyEquivalent) -> some View {
        #if os(macOS)
        keyboardShortcut(key, modifiers: [])
        #else
        self
        #endif
    }
}
