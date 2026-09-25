import SwiftUI

/// Keep writing actions in one desktop row, while retaining the phone's touch layout.
struct WritingButtonsLayout<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        #if os(macOS)
        HStack(spacing: 16) { content }
        #else
        VStack(spacing: 12) { content }
        #endif
    }
}
