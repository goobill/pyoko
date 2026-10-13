import SwiftUI

/// Shared screens supply content and actions; platform files own sizing and placement.
struct StudyLayout<Header: View, Card: View, Actions: View>: View {
    let header: Header
    let card: Card
    let actions: Actions
    let phoneWriting: Bool

    init(phoneWriting: Bool = false, @ViewBuilder header: () -> Header, @ViewBuilder card: () -> Card,
         @ViewBuilder actions: () -> Actions) {
        self.phoneWriting = phoneWriting
        self.header = header(); self.card = card(); self.actions = actions()
    }

    var body: some View {
        #if os(macOS)
        MacStudyLayout(header: header, card: card, actions: actions)
        #else
        PhoneStudyLayout(header: header, card: card, actions: actions, writing: phoneWriting)
        #endif
    }
}

private struct PhoneWritingCardHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
    var phoneWritingCardHeight: CGFloat? {
        get { self[PhoneWritingCardHeightKey.self] }
        set { self[PhoneWritingCardHeightKey.self] = newValue }
    }
}

extension View {
    @ViewBuilder func pyokoPageContent() -> some View {
        #if os(macOS)
        modifier(MacPageContent())
        #else
        modifier(PhonePageContent())
        #endif
    }

    @ViewBuilder func pyokoListPage() -> some View {
        #if os(macOS)
        frame(maxWidth: 900).padding(.horizontal, 24).padding(.vertical, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        #else
        self
        #endif
    }
}
