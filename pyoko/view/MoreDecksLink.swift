import SwiftUI

/// Opens the deck website without changing installed decks or review progress.
struct MoreDecksLink: View {
    var body: some View {
        Link(destination: URL(string: "https://pyoko.goobill.com")!) {
            Label("Get more decks", systemImage: "arrow.up.right.square")
        }
        .accessibilityIdentifier("decks.more")
        .accessibilityHint("Opens pyoko.goobill.com in your browser")
    }
}
