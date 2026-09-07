//
//  QuickSelector.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

import Foundation
import SwiftData

@MainActor
final class QuickSelector {

    private let modelContext:
        ModelContext

    private let todayProvider:
        TodayReviewProvider

    init(
        modelContext: ModelContext
    ) {

        self.modelContext =
            modelContext

        self.todayProvider =
            TodayReviewProvider(
                modelContext:
                    modelContext
            )
    }

    // MARK: - Cards

    func getCards(
        config: PyokoQuickConfig
    ) throws -> [PyokoQuickCard] {

        guard config.hasDirection
        else {
            return []
        }

        let vocabulary =
            try getVocabulary(
                config: config
            )

        guard !vocabulary.isEmpty
        else {
            return []
        }

        var cards:
            [PyokoQuickCard] = []

        for word
            in vocabulary.shuffled() {

            if config
                .includeRecognition {

                cards.append(
                    PyokoQuickCard(
                        type:
                            .recognition,
                        sourceText:
                            word.sourceText,
                        targetText:
                            word.targetText,
                        targetReading:
                            word.targetReading
                    )
                )
            }

            if config
                .includeRecall {

                cards.append(
                    PyokoQuickCard(
                        type:
                            .recall,
                        sourceText:
                            word.sourceText,
                        targetText:
                            word.targetText,
                        targetReading:
                            word.targetReading
                    )
                )
            }
        }

        cards.shuffle()

        return Array(
            cards.prefix(
                max(
                    config.cardCount,
                    0
                )
            )
        )
    }

    // MARK: - Vocabulary

    private func getVocabulary(
        config: PyokoQuickConfig
    ) throws -> [ReviewVocabulary] {

        switch config.source {

        case .random:

            return try randomVocabulary()

        case .decks:

            return try deckVocabulary(
                config: config
            )

        case .tags:

            return try tagVocabulary(
                config: config
            )

        case .todaysReview:

            return try todayProvider
                .getVocabulary()
        }
    }

    // MARK: - Random

    private func randomVocabulary()
        throws -> [ReviewVocabulary] {

        let enabledDeckIDs =
            try getEnabledReviewDeckIDs()

        guard !enabledDeckIDs.isEmpty
        else {
            return []
        }

        let cards =
            try fetchAllCards()

        let filtered =
            cards.filter { card in

                guard let deckID =
                    card.deck?.id
                else {
                    return false
                }

                return enabledDeckIDs
                    .contains(
                        deckID
                    )
            }

        return deduplicate(
            filtered
        )
    }

    // MARK: - Decks

    private func deckVocabulary(
        config: PyokoQuickConfig
    ) throws -> [ReviewVocabulary] {

        let deckIDs =
            Set(
                (config.selectedDecks ?? [])
                    .map(
                        \.id
                    )
            )

        guard !deckIDs.isEmpty
        else {
            return []
        }

        let cards =
            try fetchAllCards()

        let filtered =
            cards.filter { card in

                guard let deckID =
                    card.deck?.id
                else {
                    return false
                }

                return deckIDs
                    .contains(
                        deckID
                    )
            }

        return deduplicate(
            filtered
        )
    }

    // MARK: - Tags

    private func tagVocabulary(
        config: PyokoQuickConfig
    ) throws -> [ReviewVocabulary] {

        let selectedTagIDs =
            Set(
                (config.selectedTags ?? [])
                    .map(
                        \.id
                    )
            )

        guard !selectedTagIDs.isEmpty
        else {
            return []
        }

        let cards =
            try fetchAllCards()

        let filtered =
            cards.filter { card in

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
                            selectedTagIDs
                    )
            }

        return deduplicate(
            filtered
        )
    }

    // MARK: - Review Decks

    private func getEnabledReviewDeckIDs()
        throws -> Set<UUID> {

        let descriptor =
            FetchDescriptor<PyokoConfig>()

        if let config =
            try modelContext
                .fetch(
                    descriptor
                )
                .first {

            return Set(
                (config.selectedDecks ?? [])
                    .map(
                        \.id
                    )
            )
        }

        let deckDescriptor =
            FetchDescriptor<PyokoDeck>()

        let decks =
            try modelContext.fetch(
                deckDescriptor
            )

        return Set(
            decks.map(
                \.id
            )
        )
    }

    // MARK: - Fetch

    private func fetchAllCards()
        throws -> [PyokoCard] {

        let descriptor =
            FetchDescriptor<PyokoCard>(
                sortBy: [
                    SortDescriptor(
                        \PyokoCard.sourceText,
                        order: .forward
                    ),
                    SortDescriptor(
                        \PyokoCard.targetText,
                        order: .forward
                    )
                ]
            )

        return try modelContext.fetch(
            descriptor
        )
    }

    // MARK: - Deduplicate

    private func deduplicate(
        _ cards: [PyokoCard]
    ) -> [ReviewVocabulary] {

        var values:
            [ReviewVocabulary] = []

        var indexByKey:
            [String: Int] = [:]

        for card
            in cards {

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
