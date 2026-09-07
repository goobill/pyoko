import Foundation
import SwiftData

@MainActor
final class QuickManager {

    private let selector:
        QuickSelector

    private var cards:
        [PyokoQuickCard] = []

    private var currentIndex:
        Int = 0

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

        cards =
            try selector.getCards(
                config: config
            )

        currentIndex =
            0
    }

    // MARK: - Current

    func currentCard()
        -> PyokoQuickCard? {

        guard currentIndex
            < cards.count
        else {
            return nil
        }

        return cards[
            currentIndex
        ]
    }

    // MARK: - Next

    func next() {

        guard currentIndex
            < cards.count
        else {
            return
        }

        currentIndex += 1
    }

    // MARK: - Progress

    func getProgress()
        -> QuickProgress {

        QuickProgress(
            completed:
                min(
                    currentIndex,
                    cards.count
                ),
            total:
                cards.count
        )
    }

    var isComplete: Bool {

        currentIndex
        >= cards.count
    }
}
