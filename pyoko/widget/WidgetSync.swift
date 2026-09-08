import Foundation
import SwiftData
import WidgetKit

@MainActor
enum WidgetSync {

    static func refresh(
        modelContext:
            ModelContext
    ) {

        do {

            let configs =
                try modelContext.fetch(
                    FetchDescriptor<
                        PyokoConfig
                    >()
                )

            guard
                let config =
                    configs.first
            else {

                publish(
                    .empty
                )

                return
            }

            let cards =
                try modelContext.fetch(
                    FetchDescriptor<
                        PyokoCard
                    >()
                )

            let snapshot =
                makeSnapshot(
                    config:
                        config,
                    cards:
                        cards,
                    now:
                        .now
                )

            publish(
                snapshot
            )

        } catch {

            print(
                "Failed to refresh Pyoko widget: \(error)"
            )
        }
    }

    // MARK: - Snapshot

    private static func makeSnapshot(
        config:
            PyokoConfig,
        cards:
            [PyokoCard],
        now:
            Date
    ) -> PyokoWidgetSnapshot {

        let selectedDeckIDs =
            Set(
                (config.selectedDecks ?? [])
                    .map(
                        \.id
                    )
            )

        let selectedTagIDs =
            Set(
                (config.selectedTags ?? [])
                    .map(
                        \.id
                    )
            )

        let eligibleCards =
            cards.filter { card in

                guard
                    let deckID =
                        card.deck?
                            .id,
                    selectedDeckIDs
                        .contains(
                            deckID
                        )
                else {

                    return false
                }

                switch card.type {

                case .recognition:

                    guard
                        config
                            .showRecognitionCards
                    else {

                        return false
                    }

                case .recall:

                    guard
                        config
                            .showRecallCards
                    else {

                        return false
                    }
                }

                // Empty selectedTags means:
                // no tag filtering.

                guard
                    !selectedTagIDs
                        .isEmpty
                else {

                    return true
                }

                let cardTagIDs =
                    Set(
                        (card.tags ?? [])
                            .map(
                                \.id
                            )
                    )

                return !cardTagIDs
                    .isDisjoint(
                        with:
                            selectedTagIDs
                    )
            }

        let words =
            makeWords(
                from:
                    eligibleCards
            )

        return PyokoWidgetSnapshot(
            publishedAt:
                now,
            words:
                words,
            includeRecognition:
                config
                    .showRecognitionCards,
            includeRecall:
                config
                    .showRecallCards,
            readingOnlyAnswer:
                config
                    .readingOnlyAnswer
        )
    }

    // MARK: - Words

    private static func makeWords(
        from cards:
            [PyokoCard]
    ) -> [PyokoWidgetWord] {

        var seen =
            Set<
                VocabularyKey
            >()

        var words:
            [PyokoWidgetWord] =
                []

        let sortedCards =
            cards.sorted {

                $0.id.uuidString
                <
                $1.id.uuidString
            }

        for card in sortedCards {

            let source =
                card.sourceText
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            let target =
                card.targetText
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            guard
                !source.isEmpty,
                !target.isEmpty
            else {

                continue
            }

            let reading =
                card.targetReading?
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            let normalizedReading:
                String?

            if let reading,
               !reading.isEmpty {

                normalizedReading =
                    reading

            } else {

                normalizedReading =
                    nil
            }

            let key =
                VocabularyKey(
                    source:
                        source,
                    target:
                        target,
                    reading:
                        normalizedReading
                )

            guard
                seen.insert(
                    key
                )
                .inserted
            else {

                continue
            }

            words.append(
                PyokoWidgetWord(
                    id:
                        card.id
                            .uuidString,
                    source:
                        source,
                    target:
                        target,
                    reading:
                        normalizedReading
                )
            )
        }

        return words
    }

    // MARK: - Publish

    private static func publish(
        _ snapshot:
            PyokoWidgetSnapshot
    ) {

        guard
            PyokoWidgetStore
                .saveSnapshot(
                    snapshot
                )
        else {

            print(
                """
                Pyoko widget snapshot could not be saved.
                Check the App Group identifier.
                """
            )

            return
        }

        WidgetCenter.shared
            .reloadTimelines(
                ofKind:
                    PyokoWidgetConstants
                        .wordWidgetKind
            )
    }
}

private struct VocabularyKey:
    Hashable {

    let source:
        String

    let target:
        String

    let reading:
        String?
}
