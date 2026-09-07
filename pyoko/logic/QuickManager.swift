//
//  QuickManager.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

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

    // MARK: - Current Card

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

    // MARK: - Rating

    func rateCurrent(
        _ rating: QuickRating
    ) {

        guard currentIndex
            < cards.count
        else {
            return
        }

        let card =
            cards[
                currentIndex
            ]

        if rating.repeatsCard {

            cards.append(
                card.repeatedCopy()
            )
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

        currentIndex >= cards.count
    }
}
