import SwiftUI

#if os(iOS)
struct PhoneStudyLayout<Header: View, Card: View, Actions: View>: View {
    let header: Header
    let card: Card
    let actions: Actions

    var body: some View {
        VStack(spacing: 0) {
            header.padding(.vertical, 8)
            ScrollView {
                VStack(spacing: 16) {
                    card
                    actions.frame(minHeight: 150)
                }
                .frame(maxWidth: 620)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("study.scroll")
        }
        .accessibilityIdentifier("study.phone")
    }
}

struct PhonePageContent: ViewModifier {
    func body(content: Content) -> some View {
        content.frame(maxWidth: 620)
            .padding(16)
            .frame(maxWidth: .infinity)
    }
}
#endif
