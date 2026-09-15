import Foundation
import SwiftData

@MainActor
final class QuickManager {

    private let selector:
        QuickSelector

    /// Original cards generated when the
    /// Quick Review session starts.
    private var allCards:
        [PyokoQuickCard] = []

    /// Cards being reviewed in the current round.
    ///
    /// Initially this equals allCards.
    /// When "Review Incorrect" is selected,
    /// this contains only cards still incorrect.
    private var activeCards:
        [PyokoQuickCard] = []

    private var currentIndex:
        Int = 0

    /// Stores the learner's latest result
    /// for every original Quick Review card.
    ///
    /// Reviewing an incorrect card again
    /// updates its existing result.
    private var results:
        [UUID: QuickAnswerResult] = [:]

    init(
        modelContext: ModelContext
    ) {

        self.selector =
            QuickSelector(
                modelContext:
                    modelContext
            )
    }

    // MARK: - Start

    /// Creates a fresh practice round and clears prior answers without changing persisted cards.
    func start(
        config: PyokoQuickConfig
    ) throws {

        let selectedCards =
            try selector.getCards(
                config:
                    config
            )

        allCards =
            selectedCards

        activeCards =
            selectedCards

        currentIndex =
            0

        results =
            [:]
    }

    // MARK: - Current Card

    func currentCard()
        -> PyokoQuickCard? {

        guard currentIndex
            < activeCards.count
        else {
            return nil
        }

        return activeCards[
            currentIndex
        ]
    }

    // MARK: - Result

    /// Records the latest self-evaluation and advances; repeated calls after completion do nothing.
    func markCurrent(
        _ result:
            QuickAnswerResult
    ) {

        guard let card =
            currentCard()
        else {
            return
        }

        results[
            card.id
        ] = result

        currentIndex += 1
    }

    /// Advances without scoring or modifying FSRS. Skipping a retry retains its previous result.
    func skipCurrent() {
        guard currentCard() != nil else { return }
        currentIndex += 1
    }

    // MARK: - Review Incorrect

    /// Starts a retry round containing only mistakes while retaining the original session totals.
    func reviewIncorrect() {

        let incorrectCards =
            allCards.filter { card in

                results[
                    card.id
                ] == .incorrect
            }

        activeCards =
            incorrectCards

        currentIndex =
            0
    }

    var canReviewIncorrect: Bool {

        allCards.contains { card in

            results[
                card.id
            ] == .incorrect
        }
    }

    // MARK: - Reset

    /// Restarts the original Quick Review
    /// and clears all Correct / Incorrect results.
    func reset() {

        activeCards =
            allCards

        currentIndex =
            0

        results =
            [:]
    }

    // MARK: - Progress

    func getProgress()
        -> QuickProgress {

        let correct =
            results.values.filter {
                $0 == .correct
            }
            .count

        let incorrect =
            results.values.filter {
                $0 == .incorrect
            }
            .count

        return QuickProgress(
            completed:
                min(
                    currentIndex,
                    activeCards.count
                ),
            total:
                activeCards.count,
            sessionTotal:
                allCards.count,
            correct:
                correct,
            incorrect:
                incorrect
        )
    }

    // MARK: - State

    var isComplete: Bool {

        currentIndex
        >= activeCards.count
    }
}
