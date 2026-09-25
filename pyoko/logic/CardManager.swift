import Foundation
import SwiftData
import FSRS

// MARK: - Errors

enum CardManagerError: LocalizedError {

    case cardNotFound

    case reviewCardNotFound

    case reviewSessionNotComplete

    var errorDescription:
        String? {

        switch self {

        case .cardNotFound:

            return
                "The card could not be found."

        case .reviewCardNotFound:

            return
                "The review card could not be found."

        case .reviewSessionNotComplete:

            return
                "The current review session is not complete."
        }
    }
}

// MARK: - Progress

struct ReviewProgress {

    let completed: Int

    let total: Int

    var remaining: Int {

        max(
            total - completed,
            0
        )
    }
}

// MARK: - Card Manager

@MainActor
final class CardManager {

    // MARK: Extension Status

    struct ExtensionStatus {

        let dueNow: Int

        let nextBatchCount: Int

        let laterToday: Int

        let nextDueToday: Date?

        var canExtend: Bool {

            dueNow > 0
        }

        static let empty =
            ExtensionStatus(
                dueNow: 0,
                nextBatchCount: 0,
                laterToday: 0,
                nextDueToday: nil
            )
    }

    // MARK: - Interval Preview

    struct IntervalPreview {

        let generatedAt: Date

        let again: Date

        let hard: Date

        let good: Date

        let easy: Date

        func dueDate(
            for rating: Rating
        ) -> Date {

            switch rating {

            case .again:
                return again

            case .hard:
                return hard

            case .good:
                return good

            case .easy:
                return easy

            case .manual:

                assertionFailure(
                    "Manual FSRS ratings are not supported by Pyoko."
                )

                return good
            }
        }
    }

    // MARK: Properties

    private let modelContext:
        ModelContext

    private let scheduler:
        FSRS

    private let retrieval:
        CardRetrieval

    // MARK: Initializer

    private let clock: () -> Date

    init(
        modelContext: ModelContext,
        clock: @escaping () -> Date = { .now },
        randomize: @escaping ([PyokoCard]) -> [PyokoCard] = { $0.shuffled() }
    ) {

        self.clock = clock
        self.modelContext =
            modelContext

        self.scheduler =
            FSRS(
                parameters: .init()
            )

        self.retrieval =
            CardRetrieval(
                modelContext: modelContext,
                clock: clock,
                randomize: randomize
            )
    }

    // MARK: - Start Review

    /// Resumes today’s saved queue, or replaces an older queue with today’s eligible cards.
    func startReviewIfNeeded() {

        do {

            let reviewCards =
                try fetchReviewCards()

            if reviewCards.isEmpty {

                try generateReviewCards()

                return
            }

            if isNewDay(
                reviewCards
            ) {

                try generateReviewCards()

                return
            }

            // Today's existing queue is
            // deliberately left unchanged.

        } catch {

            print(
                "Failed to start review: \(error)"
            )
        }
    }

    // MARK: - Next Card

    func getNextCard()
        -> PyokoCard? {

        do {

            return try fetchReviewCards()
                .first {
                    !$0.reviewed
                    && $0.card != nil
                }?
                .card

        } catch {

            print(
                "Failed to get next card: \(error)"
            )

            return nil
        }
    }

    // MARK: - Progress

    func getProgress()
        -> ReviewProgress {

        do {

            let reviewCards =
                try fetchReviewCards()

            let validCards =
                reviewCards.filter {
                    $0.card != nil
                }

            let completed =
                validCards.filter {
                    $0.reviewed
                }
                .count

            return ReviewProgress(
                completed: completed,
                total: validCards.count
            )

        } catch {

            print(
                "Failed to get review progress: \(error)"
            )

            return ReviewProgress(
                completed: 0,
                total: 0
            )
        }
    }

    // MARK: - Review Card

    /// Applies one FSRS rating to an unreviewed queue item and saves the schedule and completion together.
    func reviewCard(
        id: UUID,
        rating: Rating
    ) throws {

        guard let card =
            getCard(
                id: id
            )
        else {
            throw CardManagerError
                .cardNotFound
        }

        guard let reviewCard =
            try getReviewCard(
                cardID: id
            )
        else {
            throw CardManagerError
                .reviewCardNotFound
        }

        let fsrsCard =
            makeFSRSCard(
                from: card
            )

        let result =
            try scheduler.next(
                card: fsrsCard,
                now: clock(),
                grade: rating
            )

        update(
            card: card,
            with: result.card
        )

        reviewCard.reviewed =
            true

        try modelContext.save()
    }

    // MARK: - Interval Preview

    /// Calculates the four possible due dates without changing the card or review queue.
    func getIntervalPreview(
        id: UUID
    ) throws -> IntervalPreview {

        guard let card =
            getCard(
                id: id
            )
        else {
            throw CardManagerError
                .cardNotFound
        }

        let now =
            clock()

        let fsrsCard =
            makeFSRSCard(
                from: card
            )

        let again =
            try scheduler.next(
                card: fsrsCard,
                now: now,
                grade: .again
            )
            .card
            .due

        let hard =
            try scheduler.next(
                card: fsrsCard,
                now: now,
                grade: .hard
            )
            .card
            .due

        let good =
            try scheduler.next(
                card: fsrsCard,
                now: now,
                grade: .good
            )
            .card
            .due

        let easy =
            try scheduler.next(
                card: fsrsCard,
                now: now,
                grade: .easy
            )
            .card
            .due

        return IntervalPreview(
            generatedAt: now,
            again: again,
            hard: hard,
            good: good,
            easy: easy
        )
    }

    // MARK: - Extension

    func getReviewExtensionStatus()
        throws -> ExtensionStatus {

        let reviewCards =
            try fetchReviewCards()

        let unreviewedIDs =
            Set(
                reviewCards
                    .filter {
                        !$0.reviewed
                    }
                    .compactMap {
                        $0.card?.id
                    }
            )

        let dueNow =
            try retrieval
                .getDueCardCount(
                    excludingCardIDs:
                        unreviewedIDs
                )

        let limit =
            try retrieval
                .getDailyLimit()

        let laterToday =
            try retrieval
                .getLaterTodayCardCount(
                    excludingCardIDs:
                        unreviewedIDs
                )

        let nextDueToday =
            try retrieval
                .getNextDueDateToday(
                    excludingCardIDs:
                        unreviewedIDs
                )

        return ExtensionStatus(
            dueNow: dueNow,
            nextBatchCount:
                min(
                    dueNow,
                    limit
                ),
            laterToday:
                laterToday,
            nextDueToday:
                nextDueToday
        )
    }

    /// Adds another batch onto today's existing
    /// queue without removing completed records.
    ///
    /// Returns the number of cards appended.
    @discardableResult
    /// Appends another due batch only after all current queue items are complete.
    func extendReviewSession()
        throws -> Int {

        let reviewCards =
            try fetchReviewCards()

        let hasRemainingCards =
            reviewCards.contains {

                !$0.reviewed
                && $0.card != nil
            }

        guard !hasRemainingCards
        else {
            throw CardManagerError
                .reviewSessionNotComplete
        }

        let batchSize =
            try retrieval
                .getDailyLimit()

        let cards =
            try retrieval
                .getCardsForExtension(
                    limit:
                        batchSize
                )

        guard !cards.isEmpty
        else {
            return 0
        }

        try appendReviewCards(
            cards
        )

        return cards.count
    }

    // MARK: - Reset

    func resetReviewCards() {

        do {

            let reviewCards =
                try fetchReviewCards()

            for reviewCard
                in reviewCards {

                modelContext.delete(
                    reviewCard
                )
            }

            try modelContext.save()

        } catch {

            print(
                "Failed to reset review cards: \(error)"
            )
        }
    }

    // MARK: - Card

    func getCard(
        id: UUID
    ) -> PyokoCard? {

        let cardID =
            id

        let descriptor =
            FetchDescriptor<PyokoCard>(
                predicate:
                    #Predicate<PyokoCard> {
                        card in

                        card.id == cardID
                    }
            )

        do {

            return try modelContext
                .fetch(
                    descriptor
                )
                .first

        } catch {

            print(
                "Failed to fetch card: \(error)"
            )

            return nil
        }
    }

    // MARK: - Review Queue

    private func fetchReviewCards()
        throws -> [PyokoReviewCard] {

        let descriptor =
            FetchDescriptor<PyokoReviewCard>(
                sortBy: [
                    SortDescriptor(
                        \PyokoReviewCard.reviewDate,
                        order: .forward
                    )
                ]
            )

        return try modelContext.fetch(
            descriptor
        )
    }

    private func getReviewCard(
        cardID: UUID
    ) throws -> PyokoReviewCard? {

        try fetchReviewCards()
            .first {

                $0.card?.id == cardID
                && !$0.reviewed
            }
    }

    // MARK: - Generate Initial Session

    private func generateReviewCards()
        throws {

        let existingReviewCards =
            try fetchReviewCards()

        for reviewCard
            in existingReviewCards {

            modelContext.delete(
                reviewCard
            )
        }

        let cards =
            try retrieval
                .getCardsForReview()

        try appendReviewCards(
            cards
        )
    }

    // MARK: - Append Queue

    private func appendReviewCards(
        _ cards: [PyokoCard]
    ) throws {

        guard !cards.isEmpty
        else {

            try modelContext.save()

            return
        }

        let baseDate =
            clock()

        for (
            index,
            card
        ) in cards.enumerated() {

            // Tiny offsets provide deterministic
            // queue ordering without requiring
            // another persisted model property.

            let reviewDate =
                baseDate.addingTimeInterval(
                    Double(index)
                    / 1_000
                )

            let reviewCard =
                PyokoReviewCard(
                    reviewDate:
                        reviewDate,
                    reviewed:
                        false,
                    card:
                        card
                )

            modelContext.insert(
                reviewCard
            )
        }

        try modelContext.save()
    }

    // MARK: - Day

    private func isNewDay(
        _ reviewCards:
            [PyokoReviewCard]
    ) -> Bool {

        guard let reviewDate =
            reviewCards
                .first?
                .reviewDate
        else {
            return true
        }

        return !Calendar.current
            .isDate(
                reviewDate,
                inSameDayAs:
                    clock()
            )
    }

    // MARK: - FSRS

    private func makeFSRSCard(
        from card: PyokoCard
    ) -> Card {

        Card(
            due:
                card.due,
            stability:
                card.stability,
            difficulty:
                card.difficulty,
            elapsedDays:
                card.elapsedDays,
            scheduledDays:
                card.scheduledDays,
            learningSteps:
                card.learningSteps,
            reps:
                card.reps,
            lapses:
                card.lapses,
            state:
                card.state,
            lastReview:
                card.lastReview
        )
    }

    private func update(
        card: PyokoCard,
        with fsrsCard: Card
    ) {

        card.due =
            fsrsCard.due

        card.stability =
            fsrsCard.stability

        card.difficulty =
            fsrsCard.difficulty

        card.elapsedDays =
            fsrsCard.elapsedDays

        card.scheduledDays =
            fsrsCard.scheduledDays

        card.learningSteps =
            fsrsCard.learningSteps

        card.reps =
            fsrsCard.reps

        card.lapses =
            fsrsCard.lapses

        card.state =
            fsrsCard.state

        card.lastReview =
            fsrsCard.lastReview
    }
}
