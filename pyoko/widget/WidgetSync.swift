import Foundation
import SwiftData
import WidgetKit

@MainActor
enum WidgetSync {

    static func refresh(
        modelContext:
            ModelContext
    ) {

        do {

            let configs =
                try modelContext.fetch(
                    FetchDescriptor<PyokoConfig>(sortBy: [SortDescriptor(\PyokoConfig.createdAt)])
                )

            guard
                let config =
                    configs.first
            else {

                publish(
                    .empty
                )

                return
            }

            let cards =
                try modelContext.fetch(
                    FetchDescriptor<
                        PyokoCard
                    >()
                )

            let preferences = PyokoWidgetConfig.decode(UserDefaults.standard.data(forKey: PyokoWidgetConfig.preferenceKey) ?? Data())
            let reviews = try modelContext.fetch(FetchDescriptor<PyokoReviewCard>())
            let snapshot = makeSnapshot(config: config, cards: cards, now: .now,
                                        preferences: preferences, reviews: reviews)

            publish(
                snapshot
            )

        } catch {

            print(
                "Failed to refresh Pyoko widget: \(error)"
            )
        }
    }

    // MARK: - Snapshot

    static func makeSnapshot(
        config:
            PyokoConfig,
        cards:
            [PyokoCard],
        now: Date,
        preferences suppliedPreferences: PyokoWidgetConfig? = nil,
        reviews: [PyokoReviewCard] = [],
        calendar: Calendar = .current
    ) -> PyokoWidgetSnapshot {
        // Default arguments are evaluated at the call site. Constructing this here keeps
        // it within WidgetSync's main-actor isolation under Swift 6.
        let preferences = suppliedPreferences ?? PyokoWidgetConfig()
        let enabled = Set((config.selectedDecks ?? []).map(\.id))
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
        let reviewedIDs = Set(reviews.filter {
            $0.reviewed && $0.reviewDate >= start && $0.reviewDate < end
        }.compactMap { $0.card?.id })
        let eligible = cards.filter { card in
            guard let id = card.deck?.id, enabled.contains(id) else { return false }
            if preferences.source == .decks { return (preferences.deckIDs ?? []).contains(id) }
            if preferences.source == .tags {
                return !(Set((card.tags ?? []).map(\.id)).isDisjoint(with: preferences.tagIDs))
            }
            if preferences.source == .today { return reviewedIDs.contains(card.id) }
            if preferences.source == .filtered && !preferences.tagIDs.isEmpty {
                return !(Set((card.tags ?? []).map(\.id)).isDisjoint(with: preferences.tagIDs))
            }
            return true
        }
        var words = makeWords(from: eligible)
        if preferences.source == .filtered && preferences.chooseCards {
            words = words.filter { preferences.wordIDs.contains($0.id) }
        }
        return PyokoWidgetSnapshot(
            publishedAt: now, words: words,
            includeRecognition: preferences.recognition || !preferences.recall,
            includeRecall: preferences.recall, readingOnlyAnswer: preferences.readingOnly,
            theme: preferences.theme, expiresAt: preferences.source == .today ? end : nil,
            before: preferences.before, after: preferences.after
        )
    }

    // MARK: - Words

    private static func makeWords(
        from cards:
            [PyokoCard]
    ) -> [PyokoWidgetWord] {

        var seen =
            Set<
                VocabularyKey
            >()

        var words:
            [PyokoWidgetWord] =
                []

        let sortedCards =
            cards.sorted {

                $0.id.uuidString
                <
                $1.id.uuidString
            }

        for card in sortedCards {

            let source =
                card.sourceText
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            let target =
                card.targetText
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            guard
                !source.isEmpty,
                !target.isEmpty
            else {

                continue
            }

            let reading =
                card.targetReading?
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            let normalizedReading:
                String?

            if let reading,
               !reading.isEmpty {

                normalizedReading =
                    reading

            } else {

                normalizedReading =
                    nil
            }

            let key =
                VocabularyKey(
                    deckID: card.deck?.id,
                    source:
                        source,
                    target:
                        target,
                    reading:
                        normalizedReading
                )

            guard
                seen.insert(
                    key
                )
                .inserted
            else {

                continue
            }

            words.append(
                PyokoWidgetWord(
                    id:
                        [card.deck?.id.uuidString ?? "", source, target, normalizedReading ?? ""].joined(separator: "\u{001F}"),
                    source:
                        source,
                    target:
                        target,
                    reading:
                        normalizedReading,
                    deckName: card.deck?.name
                )
            )
        }

        return words
    }

    // MARK: - Publish

    private static func publish(
        _ snapshot:
            PyokoWidgetSnapshot
    ) {

        guard
            PyokoWidgetStore
                .saveSnapshot(
                    snapshot
                )
        else {

            print(
                """
                Pyoko widget snapshot could not be saved.
                Check the App Group identifier.
                """
            )

            return
        }

        WidgetCenter.shared
            .reloadTimelines(
                ofKind:
                    PyokoWidgetConstants
                        .wordWidgetKind
            )
    }
}

private struct VocabularyKey:
    Hashable {

    let deckID: UUID?

    let source:
        String

    let target:
        String

    let reading:
        String?
}
