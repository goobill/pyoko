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

    // MARK: - Review Incorrect

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
