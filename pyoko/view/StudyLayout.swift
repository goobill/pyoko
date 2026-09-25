import SwiftUI

/// Shared screens supply content and actions; platform files own sizing and placement.
struct StudyLayout<Header: View, Card: View, Actions: View>: View {
    let header: Header
    let card: Card
    let actions: Actions

    init(@ViewBuilder header: () -> Header, @ViewBuilder card: () -> Card,
         @ViewBuilder actions: () -> Actions) {
        self.header = header(); self.card = card(); self.actions = actions()
    }

    var body: some View {
        #if os(macOS)
        MacStudyLayout(header: header, card: card, actions: actions)
        #else
        PhoneStudyLayout(header: header, card: card, actions: actions)
        #endif
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
