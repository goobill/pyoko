import SwiftUI

#if os(macOS)
struct MacStudyLayout<Header: View, Card: View, Actions: View>: View {
    let header: Header
    let card: Card
    let actions: Actions

    var body: some View {
        Group {
            VStack(spacing: 0) {
                header
                .frame(maxWidth: 1240)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                Divider()
                ScrollView {
                    VStack(spacing: 20) {
                        card.accessibilityIdentifier("study.card")
                        actions.frame(maxWidth: .infinity)
                            .accessibilityIdentifier("study.actions")
                    }
                    .frame(maxWidth: 1240)
                    .padding(32)
                    .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("study.scroll")
            }
        }
        .font(.system(size: 15))
        .controlSize(.large)
        .groupBoxStyle(MacPanelStyle())
        .accessibilityIdentifier("study.desktop")
    }


}

struct MacPageContent: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: 760, alignment: .leading)
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .top)
    }
}
#endif
