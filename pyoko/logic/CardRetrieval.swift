import Foundation
import SwiftData
import FSRS

@MainActor
final class CardRetrieval {

    private let modelContext: ModelContext

    private let clock: () -> Date
    private let randomize: ([PyokoCard]) -> [PyokoCard]

    init(
        modelContext: ModelContext,
        clock: @escaping () -> Date = { .now },
        randomize: @escaping ([PyokoCard]) -> [PyokoCard] = { $0.shuffled() }
    ) {

        self.clock = clock
        self.randomize = randomize
        self.modelContext =
            modelContext
    }

    // MARK: - Initial Daily Review

    /// Selects due cards from enabled decks and directions, reserving the configured minimum new cards.
    func getCardsForReview()
        throws -> [PyokoCard] {

        let config =
            try getConfig()

        let eligibleCards =
            try fetchEligibleCards(
                config: config,
                dueThrough: clock()
            )

        return selectInitialCards(
            from: randomize(eligibleCards),
            config: config
        )
    }

    // MARK: - Review Extension

    /// Returns cards that are genuinely due now.
    ///
    /// Unlike the initial daily session, this does not
    /// reserve places for new cards. Once the learner
    /// explicitly extends their review we simply take
    /// a random selection of cards currently due according to FSRS.
    func getCardsForExtension(
        limit: Int,
        excludingCardIDs: Set<UUID> = []
    ) throws -> [PyokoCard] {

        let config =
            try getConfig()

        let eligibleCards =
            try fetchEligibleCards(
                config: config,
                dueThrough: clock()
            )
            .filter {
                !excludingCardIDs.contains(
                    $0.id
                )
            }

        return Array(
            randomize(eligibleCards).prefix(
                max(limit, 0)
            )
        )
    }

    /// Counts eligible due cards, excluding any IDs already represented by the caller.
    func getDueCardCount(
        excludingCardIDs: Set<UUID> = []
    ) throws -> Int {

        let config =
            try getConfig()

        return try fetchEligibleCards(
            config: config,
            dueThrough: clock()
        )
        .filter {
            !excludingCardIDs.contains(
                $0.id
            )
        }
        .count
    }

    // MARK: - Later Today

    /// Cards that are not due yet, but will become
    /// due before tomorrow.
    ///
    /// These are intentionally NOT placed into an
    /// extension early.
    func getLaterTodayCardCount(
        excludingCardIDs: Set<UUID> = []
    ) throws -> Int {

        try getLaterTodayCards(
            excludingCardIDs:
                excludingCardIDs
        )
        .count
    }

    func getNextDueDateToday(
        excludingCardIDs: Set<UUID> = []
    ) throws -> Date? {

        try getLaterTodayCards(
            excludingCardIDs:
                excludingCardIDs
        )
        .first?
        .due
    }

    // MARK: - Daily Limit

    func getDailyLimit()
        throws -> Int {

        let config =
            try getConfig()

        return config.dailyCardLimit
    }

    // MARK: - Initial Selection

    private func selectInitialCards(
        from cards: [PyokoCard],
        config: ReviewConfig
    ) -> [PyokoCard] {

        let limit =
            config.dailyCardLimit

        guard limit > 0 else {
            return []
        }

        let newCards =
            cards.filter {
                $0.state == .new
            }

        let reviewCards =
            cards.filter {
                $0.state != .new
            }

        let requestedNew =
            min(
                config.minimumNewCards,
                limit
            )

        let reservedNewCards =
            Array(
                newCards.prefix(
                    requestedNew
                )
            )

        var selected =
            reservedNewCards

        let reviewCapacity =
            limit
            - selected.count

        selected.append(
            contentsOf:
                reviewCards.prefix(
                    reviewCapacity
                )
        )

        let remainingCapacity =
            limit
            - selected.count

        if remainingCapacity > 0 {

            let extraNewCards =
                newCards.dropFirst(
                    reservedNewCards.count
                )

            selected.append(
                contentsOf:
                    extraNewCards.prefix(
                        remainingCapacity
                    )
            )
        }

        // Mix the reserved new cards and review cards before the queue is persisted.
        return randomize(selected)
    }

    // MARK: - Eligibility

    private func fetchEligibleCards(
        config: ReviewConfig,
        dueThrough date: Date
    ) throws -> [PyokoCard] {

        guard !config
            .selectedDeckIDs
            .isEmpty
        else {
            return []
        }

        let dueDate =
            date

        let descriptor =
            FetchDescriptor<PyokoCard>(
                predicate:
                    #Predicate<PyokoCard> {
                        card in

                        card.due <= dueDate
                    },
                sortBy: [
                    SortDescriptor(
                        \PyokoCard.due,
                        order: .forward
                    )
                ]
            )

        let cards =
            try modelContext.fetch(
                descriptor
            )

        return cards.filter { card in

            // Deck

            guard let deckID =
                card.deck?.id
            else {
                return false
            }

            guard config
                .selectedDeckIDs
                .contains(
                    deckID
                )
            else {
                return false
            }

            // Card type

            switch card.type {

            case .recognition:

                guard config
                    .showRecognitionCards
                else {
                    return false
                }

            case .recall:

                guard config
                    .showRecallCards
                else {
                    return false
                }
            }

            // Tags
            //
            // Empty selected tags means:
            // no tag filter.

            if config
                .selectedTagIDs
                .isEmpty {

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
                        config
                            .selectedTagIDs
                )
        }
    }

    // MARK: - Later Today

    private func getLaterTodayCards(
        excludingCardIDs: Set<UUID>
    ) throws -> [PyokoCard] {

        let config =
            try getConfig()

        let now =
            clock()

        let startOfToday =
            Calendar.current
                .startOfDay(
                    for: now
                )

        guard let startOfTomorrow =
            Calendar.current.date(
                byAdding: .day,
                value: 1,
                to: startOfToday
            )
        else {
            return []
        }

        let cards =
            try fetchEligibleCards(
                config: config,
                dueThrough:
                    startOfTomorrow
            )

        return cards.filter {

            $0.due > now
            && $0.due < startOfTomorrow
            && !excludingCardIDs
                .contains(
                    $0.id
                )
        }
    }

    // MARK: - Config

    private func getConfig()
        throws -> ReviewConfig {

        let descriptor =
            FetchDescriptor<PyokoConfig>(sortBy: [SortDescriptor(\PyokoConfig.createdAt)])

        if let config =
            try modelContext
                .fetch(
                    descriptor
                )
                .first {

            let dailyLimit =
                max(
                    config.dailyCardLimit,
                    1
                )

            return ReviewConfig(
                dailyCardLimit:
                    dailyLimit,
                minimumNewCards:
                    min(
                        max(
                            config.minimumNewCards,
                            0
                        ),
                        dailyLimit
                    ),
                selectedDeckIDs:
                    Set(
                        (config.selectedDecks ?? [])
                            .map(
                                \.id
                            )
                    ),
                selectedTagIDs:
                    Set(
                        (config.selectedTags ?? [])
                            .map(
                                \.id
                            )
                    ),
                showRecognitionCards:
                    config
                        .showRecognitionCards,
                showRecallCards:
                    config
                        .showRecallCards
            )
        }

        // Fallback for a fresh installation where
        // the Config model has not been created yet.

        let deckDescriptor =
            FetchDescriptor<PyokoDeck>()

        let decks =
            try modelContext.fetch(
                deckDescriptor
            )

        return ReviewConfig(
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
}

// MARK: - Internal Config

private struct ReviewConfig {

    let dailyCardLimit: Int

    let minimumNewCards: Int

    let selectedDeckIDs:
        Set<UUID>

    let selectedTagIDs:
        Set<UUID>

    let showRecognitionCards:
        Bool

    let showRecallCards:
        Bool
}
