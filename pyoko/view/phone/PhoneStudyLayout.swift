import SwiftUI

#if os(iOS)
struct PhoneStudyLayout<Header: View, Card: View, Actions: View>: View {
    let header: Header
    let card: Card
    let actions: Actions
    var writing = false
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var actionsHeight: CGFloat = 108

    var body: some View {
        VStack(spacing: 0) {
            header.padding(.vertical, 8)
            if writing {
                GeometryReader { space in
                    ScrollView {
                        VStack(spacing: 12) {
                            card.environment(\.phoneWritingCardHeight,
                                max(textSize.isAccessibilitySize ? 240 : 140,
                                    min(220, space.size.height - actionsHeight - 36)))
                            actions
                                .background {
                                    GeometryReader { size in
                                        Color.clear.preference(key: WritingActionsHeightKey.self,
                                                               value: size.size.height)
                                    }
                                }
                        }
                        .frame(maxWidth: 620)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                    }
                    .scrollIndicators(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollDismissesKeyboard(.never)
                    .onPreferenceChange(WritingActionsHeightKey.self) { actionsHeight = $0 }
                    .accessibilityIdentifier("study.scroll")
                }
            } else {
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
        }
        .accessibilityIdentifier("study.phone")
    }
}

private struct WritingActionsHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 108
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct PhonePageContent: ViewModifier {
    func body(content: Content) -> some View {
        content.frame(maxWidth: 620)
            .padding(16)
            .frame(maxWidth: .infinity)
    }
}
#endif
