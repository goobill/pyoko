//
//  SentenceSelector.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

import Foundation
import SwiftData

@MainActor
final class SentenceSelector {

    private let modelContext: ModelContext

    init(
        modelContext: ModelContext
    ) {
        self.modelContext = modelContext
    }

    func vocabulary(
        for configuration: PyokoSentenceConfiguration
    ) throws -> [SentenceVocabulary] {

        let cards: [PyokoCard]

        switch configuration.source {

        case .random:
            cards = try randomCards()

        case .decks:
            cards = try cardsFromSelectedDecks(
                configuration
            )

        case .tags:
            cards = try cardsFromSelectedTags(
                configuration
            )

        case .todaysReview:
            cards = try cardsFromTodaysReview()
        }

        return deduplicate(
            cards
        )
        .shuffled()
    }

    // MARK: - Random

    private func randomCards() throws -> [PyokoCard] {

        let reviewConfigurations =
            try modelContext.fetch(
                FetchDescriptor<PyokoConfiguration>()
            )

        let allCards =
            try modelContext.fetch(
                FetchDescriptor<PyokoCard>()
            )

        guard let reviewConfiguration =
            reviewConfigurations.first
        else {
            return allCards
        }

        let enabledDeckIDs =
            Set(
                (reviewConfiguration.selectedDecks ?? [])
                    .map(\.id)
            )

        guard !enabledDeckIDs.isEmpty else {
            return []
        }

        return allCards.filter { card in

            guard let deckID =
                card.deck?.id
            else {
                return false
            }

            return enabledDeckIDs.contains(
                deckID
            )
        }
    }

    // MARK: - Decks

    private func cardsFromSelectedDecks(
        _ configuration: PyokoSentenceConfiguration
    ) throws -> [PyokoCard] {

        let selectedDeckIDs =
            Set(
                (configuration.selectedDecks ?? [])
                    .map(\.id)
            )

        guard !selectedDeckIDs.isEmpty else {
            return []
        }

        let cards =
            try modelContext.fetch(
                FetchDescriptor<PyokoCard>()
            )

        return cards.filter { card in

            guard let deckID =
                card.deck?.id
            else {
                return false
            }

            return selectedDeckIDs.contains(
                deckID
            )
        }
    }

    // MARK: - Tags

    private func cardsFromSelectedTags(
        _ configuration: PyokoSentenceConfiguration
    ) throws -> [PyokoCard] {

        let selectedTagIDs =
            Set(
                (configuration.selectedTags ?? [])
                    .map(\.id)
            )

        guard !selectedTagIDs.isEmpty else {
            return []
        }

        let cards =
            try modelContext.fetch(
                FetchDescriptor<PyokoCard>()
            )

        return cards.filter { card in

            let cardTags =
                card.tags ?? []

            return cardTags.contains { tag in
                selectedTagIDs.contains(
                    tag.id
                )
            }
        }
    }

    // MARK: - Today's Review

    private func cardsFromTodaysReview() throws -> [PyokoCard] {

        let calendar =
            Calendar.current

        let start =
            calendar.startOfDay(
                for: .now
            )

        guard let end =
            calendar.date(
                byAdding: .day,
                value: 1,
                to: start
            )
        else {
            return []
        }

        let reviewCards =
            try modelContext.fetch(
                FetchDescriptor<PyokoReviewCard>()
            )

        return reviewCards.compactMap { reviewCard in

            guard
                reviewCard.reviewDate >= start,
                reviewCard.reviewDate < end
            else {
                return nil
            }

            return reviewCard.card
        }
    }

    // MARK: - Deduplication

    private func deduplicate(
        _ cards: [PyokoCard]
    ) -> [SentenceVocabulary] {

        var vocabularyByKey:
            [String: SentenceVocabulary] = [:]

        for card in cards {

            let source =
                card.sourceText
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            let target =
                card.targetText
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            guard
                !source.isEmpty,
                !target.isEmpty
            else {
                continue
            }

            let reading =
                cleanedReading(
                    card.targetReading
                )

            let key =
                vocabularyKey(
                    source: source,
                    target: target,
                    reading: reading
                )

            vocabularyByKey[key] =
                SentenceVocabulary(
                    sourceText: source,
                    targetText: target,
                    targetReading: reading
                )
        }

        return Array(
            vocabularyByKey.values
        )
    }

    private func cleanedReading(
        _ reading: String?
    ) -> String? {

        guard let reading else {
            return nil
        }

        let cleaned =
            reading.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return cleaned.isEmpty
            ? nil
            : cleaned
    }

    private func vocabularyKey(
        source: String,
        target: String,
        reading: String?
    ) -> String {

        [
            source.lowercased(),
            target,
            reading ?? ""
        ]
        .joined(
            separator: "\u{1F}"
        )
    }
}
