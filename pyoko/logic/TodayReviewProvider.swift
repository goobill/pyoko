//
//  TodayReviewProvider.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

import Foundation
import SwiftData

struct ReviewVocabulary: Identifiable {

    let id: UUID

    let sourceText: String

    let targetText: String

    let targetReading: String?

    let deckID: UUID?

    let tagIDs: Set<UUID>
}

@MainActor
final class TodayReviewProvider {

    private let modelContext:
        ModelContext

    private let clock: () -> Date

    init(
        modelContext: ModelContext,
        clock: @escaping () -> Date = { .now }
    ) {

        self.clock = clock
        self.modelContext =
            modelContext
    }

    // MARK: - Vocabulary

    /// Returns distinct vocabulary actually completed today; pending and previous-day cards are excluded.
    func getVocabulary()
        throws -> [ReviewVocabulary] {

        let startOfToday =
            Calendar.current
                .startOfDay(
                    for: clock()
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

        let descriptor =
            FetchDescriptor<PyokoReviewCard>(
                predicate:
                    #Predicate<PyokoReviewCard> {
                        reviewCard in

                        reviewCard.reviewed
                        && reviewCard.reviewDate
                            >= startOfToday
                        && reviewCard.reviewDate
                            < startOfTomorrow
                    },
                sortBy: [
                    SortDescriptor(
                        \PyokoReviewCard.reviewDate,
                        order: .forward
                    )
                ]
            )

        let reviewCards =
            try modelContext.fetch(
                descriptor
            )

        return deduplicate(
            reviewCards
        )
    }

    func hasVocabulary()
        throws -> Bool {

        try !getVocabulary()
            .isEmpty
    }

    func vocabularyCount()
        throws -> Int {

        try getVocabulary()
            .count
    }

    // MARK: - Deduplicate

    private func deduplicate(
        _ reviewCards:
            [PyokoReviewCard]
    ) -> [ReviewVocabulary] {

        var values:
            [ReviewVocabulary] = []

        var indexByKey:
            [String: Int] = [:]

        for reviewCard
            in reviewCards {

            guard let card =
                reviewCard.card
            else {
                continue
            }

            let key =
                vocabularyKey(
                    source:
                        card.sourceText,
                    target:
                        card.targetText
                )

            let tagIDs =
                Set(
                    (card.tags ?? [])
                        .map(
                            \.id
                        )
                )

            if let index =
                indexByKey[key] {

                let existing =
                    values[index]

                values[index] =
                    ReviewVocabulary(
                        id:
                            existing.id,
                        sourceText:
                            existing.sourceText,
                        targetText:
                            existing.targetText,
                        targetReading:
                            existing.targetReading
                            ?? card.targetReading,
                        deckID:
                            existing.deckID
                            ?? card.deck?.id,
                        tagIDs:
                            existing.tagIDs
                                .union(
                                    tagIDs
                                )
                    )

            } else {

                indexByKey[key] =
                    values.count

                values.append(
                    ReviewVocabulary(
                        id:
                            card.id,
                        sourceText:
                            card.sourceText,
                        targetText:
                            card.targetText,
                        targetReading:
                            card.targetReading,
                        deckID:
                            card.deck?.id,
                        tagIDs:
                            tagIDs
                    )
                )
            }
        }

        return values
    }

    private func vocabularyKey(
        source: String,
        target: String
    ) -> String {

        source
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .lowercased()
        + "\u{001F}"
        + target
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .lowercased()
    }
}
