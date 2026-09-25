import SwiftUI

/// Ratings stay in one horizontal row beneath the study card on both platforms.
struct RatingButtonsLayout<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        HStack(spacing: 8) { content }
    }
}

struct RatingButtonLabel: View {
    let title: String
    let interval: String

    var body: some View {
        #if os(macOS)
        VStack(spacing: 6) {
            Text(title).font(.headline)
            Text(interval).font(.subheadline)
        }.frame(maxWidth: .infinity, minHeight: 64)
        #else
        Text(interval).font(.subheadline).fontWeight(.semibold)
            .frame(maxWidth: .infinity).frame(height: 48)
        #endif
    }
}
