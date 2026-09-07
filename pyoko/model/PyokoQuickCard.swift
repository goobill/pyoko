//
//  PyokoQuickCard.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

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

        self.id = id
        self.type = type
        self.sourceText = sourceText
        self.targetText = targetText
        self.targetReading = targetReading
    }

    func repeatedCopy() -> PyokoQuickCard {

        PyokoQuickCard(
            type: type,
            sourceText: sourceText,
            targetText: targetText,
            targetReading: targetReading
        )
    }
}

struct QuickProgress {

    let completed: Int

    let total: Int

    var remaining: Int {

        max(
            total - completed,
            0
        )
    }
}
