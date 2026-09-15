import SwiftUI
import SwiftData

extension View {

    func pyokoWidgetSync()
        -> some View {

        background {

            WidgetSyncObserverView()
        }
    }
}

private struct WidgetSyncObserverView:
    View {

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.scenePhase)
    private var scenePhase

    @Query(sort: \PyokoConfig.createdAt)
    private var configs:
        [PyokoConfig]

    @Query
    private var cards:
        [PyokoCard]

    @AppStorage(PyokoWidgetConfig.preferenceKey) private var preferences = Data()
    @Query private var reviews: [PyokoReviewCard]

    @Query private var decks: [PyokoDeck]

    var body: some View {

        Color.clear
            .frame(
                width:
                    0,
                height:
                    0
            )
            .accessibilityHidden(
                true
            )
            .task(
                id:
                    fingerprint
            ) {

                WidgetSync.refresh(
                    modelContext:
                        modelContext
                )
            }
            .onChange(
                of:
                    scenePhase
            ) {
                _,
                newPhase in

                guard
                    newPhase ==
                        .active
                else {

                    return
                }

                WidgetSync.refresh(
                    modelContext:
                        modelContext
                )
            }
    }

    private var fingerprint:
        Int {

        var hasher =
            Hasher()

        hasher.combine(preferences)
        for review in reviews {
            hasher.combine(review.id)
            hasher.combine(review.reviewed)
            hasher.combine(review.reviewDate)
            hasher.combine(review.card?.id)
        }
        // Republishes the snapshot when a deck is renamed, including via sync.
        for deck in decks.sorted(by: { $0.id.uuidString < $1.id.uuidString }) {
            hasher.combine(deck.id)
            hasher.combine(deck.name)
        }

        for config in configs {

            hasher.combine(
                config.id
            )

            hasher.combine(
                config.showRecognitionCards
            )

            hasher.combine(
                config.showRecallCards
            )

            hasher.combine(
                config.readingOnlyAnswer
            )

            let deckIDs =
                (config.selectedDecks ?? [])
                    .map {
                        $0.id
                            .uuidString
                    }
                    .sorted()

            for id in deckIDs {

                hasher.combine(
                    id
                )
            }

            let tagIDs =
                (config.selectedTags ?? [])
                    .map {
                        $0.id
                            .uuidString
                    }
                    .sorted()

            for id in tagIDs {

                hasher.combine(
                    id
                )
            }
        }

        for card in cards {

            hasher.combine(
                card.id
            )

            hasher.combine(
                card.sourceText
            )

            hasher.combine(
                card.targetText
            )

            hasher.combine(
                card.targetReading
            )

            hasher.combine(
                card.deck?
                    .id
            )

            let tagIDs =
                (card.tags ?? [])
                    .map {
                        $0.id
                            .uuidString
                    }
                    .sorted()

            for id in tagIDs {

                hasher.combine(
                    id
                )
            }
        }

        return hasher.finalize()
    }
}
