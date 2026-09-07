import Foundation

struct PyokoQuickCard: Identifiable {

    let id: UUID

    let type: CardType

    let sourceText: String

    let targetText: String

    let targetReading: String?

    init(
        id: UUID = UUID(),
        type: CardType,
        sourceText: String,
        targetText: String,
        targetReading: String?
    ) {

        self.id =
            id

        self.type =
            type

        self.sourceText =
            sourceText

        self.targetText =
            targetText

        self.targetReading =
            targetReading
    }
}

// MARK: - Progress

struct QuickProgress {

    /// Number completed in the current round.
    let completed: Int

    /// Number of cards in the current round.
    let total: Int

    /// Number of cards in the original session.
    let sessionTotal: Int

    /// Current overall result for the original session.
    let correct: Int

    /// Current overall result for the original session.
    let incorrect: Int

    var remaining: Int {

        max(
            total - completed,
            0
        )
    }

    var reviewed: Int {

        correct
        + incorrect
    }
}
