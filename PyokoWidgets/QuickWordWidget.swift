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
                    "しっぱい"
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

        completion(
            Timeline(
                entries:
                    [
                        entry
                    ],
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

struct QuickWordWidgetView:
    View {

    @Environment(\.widgetFamily)
    private var family

    let entry:
        QuickWordEntry

    var body: some View {

        Group {

            if let word =
                entry.word {

                Button(
                    intent:
                        TapWidgetWordIntent()
                ) {

                    wordView(
                        word
                    )
                    .frame(
                        maxWidth:
                            .infinity,
                        maxHeight:
                            .infinity
                    )
                    .contentShape(
                        Rectangle()
                    )
                }
                .buttonStyle(
                    .plain
                )
                .accessibilityLabel(
                    accessibilityLabel(
                        word
                    )
                )

            } else {

                emptyView
            }
        }
        .containerBackground(
            for:
                .widget
        ) {

            Color.clear
        }
    }

    // MARK: - Word

    private func wordView(
        _ word:
            PyokoWidgetWord
    ) -> some View {

        VStack(
            spacing:
                8
        ) {

            header

            Spacer(
                minLength:
                    4
            )

            if entry.isRevealed {

                revealedView(
                    word
                )

            } else {

                questionView(
                    word
                )
            }

            Spacer(
                minLength:
                    4
            )
        }
        .frame(
            maxWidth:
                .infinity,
            maxHeight:
                .infinity
        )
    }

    // MARK: - Header

    private var header:
        some View {

        HStack {

            Image(
                systemName:
                    "hand.tap"
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
            .accessibilityHidden(
                true
            )

            Spacer()

            Text(
                directionTitle
            )
            .font(
                .caption2
            )
            .foregroundStyle(
                .secondary
            )
        }
    }

    // MARK: - Question

    private func questionView(
        _ word:
            PyokoWidgetWord
    ) -> some View {

        Text(
            questionText(
                word
            )
        )
        .font(
            family ==
                .systemSmall
            ? .title2
            : .title
        )
        .fontWeight(
            .semibold
        )
        .minimumScaleFactor(
            0.5
        )
        .lineLimit(
            4
        )
        .multilineTextAlignment(
            .center
        )
        .frame(
            maxWidth:
                .infinity
        )
    }

    // MARK: - Revealed

    private func revealedView(
        _ word:
            PyokoWidgetWord
    ) -> some View {

        VStack(
            spacing:
                10
        ) {

            Text(
                questionText(
                    word
                )
            )
            .font(
                family ==
                    .systemSmall
                ? .headline
                : .title3
            )
            .fontWeight(
                .semibold
            )
            .minimumScaleFactor(
                0.6
            )
            .lineLimit(
                2
            )
            .multilineTextAlignment(
                .center
            )

            answerView(
                word
            )
        }
        .frame(
            maxWidth:
                .infinity
        )
    }

    // MARK: - Answer

    @ViewBuilder
    private func answerView(
        _ word:
            PyokoWidgetWord
    ) -> some View {

        switch entry.direction {

        case .recognition:

            if entry.snapshot
                .readingOnlyAnswer {

                Text(
                    word.displayReading
                )
                .font(
                    family ==
                        .systemSmall
                    ? .title3
                    : .title2
                )
                .fontWeight(
                    .medium
                )
                .minimumScaleFactor(
                    0.6
                )
                .lineLimit(
                    2
                )
                .multilineTextAlignment(
                    .center
                )

            } else {

                VStack(
                    spacing:
                        4
                ) {

                    if word.displayReading
                        != word.target {

                        Text(
                            word.displayReading
                        )
                        .font(
                            .subheadline
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }

                    Text(
                        word.source
                    )
                    .font(
                        family ==
                            .systemSmall
                        ? .title3
                        : .title2
                    )
                    .fontWeight(
                        .medium
                    )
                    .minimumScaleFactor(
                        0.6
                    )
                    .lineLimit(
                        3
                    )
                    .multilineTextAlignment(
                        .center
                    )
                }
            }

        case .recall:

            VStack(
                spacing:
                    4
            ) {

                Text(
                    word.target
                )
                .font(
                    family ==
                        .systemSmall
                    ? .title2
                    : .title
                )
                .fontWeight(
                    .medium
                )
                .minimumScaleFactor(
                    0.6
                )
                .lineLimit(
                    2
                )
                .multilineTextAlignment(
                    .center
                )

                if word.displayReading
                    != word.target {

                    Text(
                        word.displayReading
                    )
                    .font(
                        .subheadline
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
        }
    }

    // MARK: - Empty

    private var emptyView:
        some View {

        VStack(
            spacing:
                8
        ) {

            HStack {

                Image(
                    systemName:
                        "hand.tap"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )

                Spacer()
            }

            Spacer()

            Image(
                systemName:
                    "rectangle.stack.badge.plus"
            )
            .font(
                .title2
            )
            .foregroundStyle(
                .secondary
            )

            Text(
                "No words available"
            )
            .font(
                .headline
            )

            Text(
                "Open Pyoko and enable a deck."
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
            .multilineTextAlignment(
                .center
            )

            Spacer()
        }
        .frame(
            maxWidth:
                .infinity,
            maxHeight:
                .infinity
        )
    }

    // MARK: - Direction

    private var directionTitle:
        String {

        switch entry.direction {

        case .recognition:

            if entry.snapshot
                .readingOnlyAnswer {

                return "Reading"
            }

            return "Recognition"

        case .recall:

            return "Recall"
        }
    }

    // MARK: - Question Text

    private func questionText(
        _ word:
            PyokoWidgetWord
    ) -> String {

        switch entry.direction {

        case .recognition:

            return word.target

        case .recall:

            return word.source
        }
    }

    // MARK: - Accessibility

    private func accessibilityLabel(
        _ word:
            PyokoWidgetWord
    ) -> String {

        if entry.isRevealed {

            return
                "Answer revealed. Tap for the next word."

        } else {

            return
                "\(questionText(word)). Tap to reveal the answer."
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
