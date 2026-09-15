import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Entry

struct QuickWordEntry:
    TimelineEntry {

    let date:
        Date

    let snapshot:
        PyokoWidgetSnapshot

    let word:
        PyokoWidgetWord?

    let direction:
        PyokoWidgetDirection

    let isRevealed:
        Bool
}

// MARK: - Provider

struct QuickWordProvider:
    TimelineProvider {

    func placeholder(
        in context:
            Context
    ) -> QuickWordEntry {

        let word =
            PyokoWidgetWord(
                id:
                    "placeholder",
                source:
                    "failure",
                target:
                    "失敗",
                reading:
                    "しっぱい",
                deckName: "N5 Vocab"
            )

        return QuickWordEntry(
            date:
                .now,
            snapshot:
                .empty,
            word:
                word,
            direction:
                .recall,
            isRevealed:
                false
        )
    }

    func getSnapshot(
        in context:
            Context,
        completion:
            @escaping (
                QuickWordEntry
            ) -> Void
    ) {

        completion(
            makeEntry(
                date:
                    .now
            )
        )
    }

    func getTimeline(
        in context:
            Context,
        completion:
            @escaping (
                Timeline<
                    QuickWordEntry
                >
            ) -> Void
    ) {

        let now =
            Date.now

        let entry =
            makeEntry(
                date:
                    now
            )

        var entries = [entry]
        if let expiry = entry.snapshot.expiresAt, expiry > now {
            entries.append(makeEntry(date: expiry))
        }
        completion(
            Timeline(
                entries: entries,
                policy:
                    .after(
                        now.addingTimeInterval(
                            60 * 60 * 6
                        )
                    )
            )
        )
    }

    private func makeEntry(
        date:
            Date
    ) -> QuickWordEntry {

        let snapshot =
            PyokoWidgetStore
                .loadSnapshot()

        return QuickWordEntry(
            date:
                date,
            snapshot:
                snapshot,
            word:
                PyokoWidgetStore
                    .currentWord(
                        snapshot:
                            snapshot
                    ),
            direction:
                PyokoWidgetStore
                    .currentDirection(
                        snapshot:
                            snapshot
                    ),
            isRevealed:
                PyokoWidgetStore
                    .isWordRevealed
        )
    }
}

// MARK: - View

struct QuickWordWidgetView: View {
    @Environment(\.colorScheme) private var scheme
    let entry: QuickWordEntry

    var body: some View {
        Group {
            if let word = entry.word, !entry.snapshot.isExpired(at: entry.date) {
                Button(intent: TapWidgetWordIntent()) {
                    WidgetWordView(word: word, direction: entry.direction,
                                   revealed: entry.isRevealed, snapshot: entry.snapshot)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(entry.isRevealed ? "Answer revealed. Next word" : "Reveal answer")
            } else {
                VStack(spacing: 8) {
                    Text("No words available").font(.headline)
                    Text("Choose vocabulary in Widget Config.").font(.caption)
                }
            }
        }
        .containerBackground(for: .widget) {
            if let theme = PyokoTheme(rawValue: entry.snapshot.theme ?? "system") {
                theme.background(for: scheme)
            } else { Color.clear }
        }
    }
}

// MARK: - Widget

struct QuickWordWidget:
    Widget {

    var body:
        some WidgetConfiguration {

        StaticConfiguration(
            kind:
                PyokoWidgetConstants
                    .wordWidgetKind,
            provider:
                QuickWordProvider()
        ) { entry in

            QuickWordWidgetView(
                entry:
                    entry
            )
        }
        .configurationDisplayName(
            "Word Review"
        )
        .description(
            "Test yourself with random vocabulary from your Pyoko decks."
        )
        .supportedFamilies(
            [
                .systemSmall,
                .systemMedium
            ]
        )
    }
}
