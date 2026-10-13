import SwiftUI

/// Keep both writing actions within reach above the keyboard.
struct WritingButtonsLayout<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        #if os(macOS)
        HStack(spacing: 16) { content }
        #else
        HStack(spacing: 12) { content }
        #endif
    }
}
