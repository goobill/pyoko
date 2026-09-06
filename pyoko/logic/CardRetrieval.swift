import Foundation
import SwiftData
import FSRS

@MainActor
final class CardRetrieval {

    private let modelContext: ModelContext

    init(
        modelContext: ModelContext
    ) {
        self.modelContext = modelContext
    }

    // MARK: - Public

    func getCardsForReview() throws -> [PyokoCard] {

        let configuration =
            try getReviewConfiguration()

        let eligibleCards =
            try fetchEligibleCards(
                configuration: configuration
            )

        return selectCards(
            from: eligibleCards,
            configuration: configuration
        )
    }

    // MARK: - Selection

    private func selectCards(
        from eligibleCards: [PyokoCard],
        configuration: ReviewConfiguration
    ) -> [PyokoCard] {

        let dailyLimit =
            max(
                configuration.dailyCardLimit,
                1
            )

        let requestedNewCards =
            min(
                max(
                    configuration.minimumNewCards,
                    0
                ),
                dailyLimit
            )

        let newCards =
            eligibleCards.filter {
                $0.state == CardState.new
            }

        let reviewCards =
            eligibleCards.filter {
                $0.state != CardState.new
            }

        /*
         Reserve the requested number of slots
         for new cards.
        */

        let selectedNewCards =
            Array(
                newCards.prefix(
                    requestedNewCards
                )
            )

        /*
         Reviews fill the remaining capacity.
        */

        let reviewCapacity =
            max(
                dailyLimit -
                    selectedNewCards.count,
                0
            )

        let selectedReviewCards =
            Array(
                reviewCards.prefix(
                    reviewCapacity
                )
            )

        var selectedCards =
            selectedReviewCards +
            selectedNewCards

        /*
         If there were not enough reviews to
         fill the daily limit, use additional
         new cards.

         minimumNewCards is therefore a minimum,
         not a maximum.
        */

        let remainingCapacity =
            dailyLimit -
                selectedCards.count

        if remainingCapacity > 0 {

            let additionalNewCards =
                newCards
                    .dropFirst(
                        selectedNewCards.count
                    )
                    .prefix(
                        remainingCapacity
                    )

            selectedCards.append(
                contentsOf:
                    additionalNewCards
            )
        }

        return selectedCards
    }

    // MARK: - Configuration

    private func getReviewConfiguration()
        throws -> ReviewConfiguration {

        let descriptor =
            FetchDescriptor<PyokoConfiguration>()

        if let configuration =
            try modelContext
                .fetch(
                    descriptor
                )
                .first {

            let dailyLimit =
                max(
                    configuration.dailyCardLimit,
                    1
                )

            let minimumNewCards =
                min(
                    max(
                        configuration.minimumNewCards,
                        0
                    ),
                    dailyLimit
                )

            return ReviewConfiguration(
                dailyCardLimit:
                    dailyLimit,
                minimumNewCards:
                    minimumNewCards,
                selectedDeckIDs:
                    Set(
                        (
                            configuration.selectedDecks ??
                            []
                        )
                        .map(
                            \.id
                        )
                    ),
                selectedTagIDs:
                    Set(
                        (
                            configuration.selectedTags ??
                            []
                        )
                        .map(
                            \.id
                        )
                    ),
                showRecognitionCards:
                    configuration
                        .showRecognitionCards,
                showRecallCards:
                    configuration
                        .showRecallCards
            )
        }

        /*
         Default configuration if none
         exists yet:

         - 20 cards
         - 0 guaranteed new cards
         - all decks
         - no tag filter
         - Recognition enabled
         - Recall enabled
        */

        let deckDescriptor =
            FetchDescriptor<PyokoDeck>()

        let decks =
            try modelContext.fetch(
                deckDescriptor
            )

        return ReviewConfiguration(
            dailyCardLimit: 20,
            minimumNewCards: 0,
            selectedDeckIDs:
                Set(
                    decks.map(
                        \.id
                    )
                ),
            selectedTagIDs: [],
            showRecognitionCards: true,
            showRecallCards: true
        )
    }

    // MARK: - Eligible Cards

    private func fetchEligibleCards(
        configuration: ReviewConfiguration
    ) throws -> [PyokoCard] {

        guard
            !configuration
                .selectedDeckIDs
                .isEmpty
        else {
            return []
        }

        let now =
            Date.now

        let descriptor =
            FetchDescriptor<PyokoCard>(
                predicate:
                    #Predicate<PyokoCard> {
                        card in

                        card.due <= now
                    },
                sortBy: [
                    SortDescriptor(
                        \PyokoCard.due,
                        order: .forward
                    )
                ]
            )

        let dueCards =
            try modelContext.fetch(
                descriptor
            )

        return dueCards.filter {
            card in

            // Deck filter

            guard
                let deckID =
                    card.deck?.id,
                configuration
                    .selectedDeckIDs
                    .contains(
                        deckID
                    )
            else {
                return false
            }

            // Card-type filter

            switch card.type {

            case .recognition:

                guard
                    configuration
                        .showRecognitionCards
                else {
                    return false
                }

            case .recall:

                guard
                    configuration
                        .showRecallCards
                else {
                    return false
                }
            }

            // No selected tags means
            // no tag filtering.

            guard
                !configuration
                    .selectedTagIDs
                    .isEmpty
            else {
                return true
            }

            let cardTagIDs =
                Set(
                    (
                        card.tags ??
                        []
                    )
                    .map(
                        \.id
                    )
                )

            return !cardTagIDs
                .isDisjoint(
                    with:
                        configuration
                            .selectedTagIDs
                )
        }
    }
}

// MARK: - Review Configuration

private struct ReviewConfiguration {

    let dailyCardLimit:
        Int

    let minimumNewCards:
        Int

    let selectedDeckIDs:
        Set<UUID>

    /// Empty means no tag filter.
    let selectedTagIDs:
        Set<UUID>

    let showRecognitionCards:
        Bool

    let showRecallCards:
        Bool
}
