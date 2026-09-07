//
//  SentenceManager.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class SentenceManager {

    private let modelContext:
        ModelContext

    private let selector:
        SentenceSelector

    private let generator:
        SentenceGenerator

    private var configuration:
        PyokoSentenceConfiguration?

    private var vocabularyGroups:
        [[SentenceVocabulary]] = []

    private var directions:
        [CardType] = []

    var currentSentence:
        PyokoSentence?

    var currentDirection:
        CardType = .recognition

    var currentIndex:
        Int = 0

    var total:
        Int = 0

    var isLoading:
        Bool = false

    var isComplete:
        Bool = false

    var errorMessage:
        String?

    var ratings:
        [SentenceRating] = []

    init(
        modelContext: ModelContext
    ) {

        self.modelContext =
            modelContext

        self.selector =
            SentenceSelector(
                modelContext:
                    modelContext
            )

        self.generator =
            SentenceGenerator()
    }

    // MARK: - Configuration

    @discardableResult
    func ensureConfigurationExists()
        throws
        -> PyokoSentenceConfiguration {

        let existing =
            try modelContext.fetch(
                FetchDescriptor<
                    PyokoSentenceConfiguration
                >()
            )

        if let configuration =
            existing.first {

            return configuration
        }

        let configuration =
            PyokoSentenceConfiguration()

        let reviewConfigurations =
            try modelContext.fetch(
                FetchDescriptor<
                    PyokoConfiguration
                >()
            )

        if let reviewConfiguration =
            reviewConfigurations.first {

            configuration.selectedDecks =
                reviewConfiguration
                    .selectedDecks
                ?? []

        } else {

            configuration.selectedDecks =
                try modelContext.fetch(
                    FetchDescriptor<
                        PyokoDeck
                    >()
                )
        }

        modelContext.insert(
            configuration
        )

        try modelContext.save()

        return configuration
    }

    // MARK: - Session

    func start(
        configuration:
            PyokoSentenceConfiguration
    ) async {

        guard !isLoading else {
            return
        }

        self.configuration =
            configuration

        currentSentence =
            nil

        currentIndex =
            0

        total =
            0

        ratings =
            []

        isComplete =
            false

        errorMessage =
            nil

        do {

            let vocabulary =
                try selector.vocabulary(
                    for: configuration
                )

            guard !vocabulary.isEmpty else {

                throw SentenceManagerError
                    .noVocabulary
            }

            vocabularyGroups =
                makeVocabularyGroups(
                    vocabulary:
                        vocabulary,
                    count:
                        configuration
                            .sentenceCount,
                    density:
                        configuration
                            .density
                )

            directions =
                makeDirections(
                    count:
                        vocabularyGroups.count,
                    recognition:
                        configuration
                            .includeRecognition,
                    recall:
                        configuration
                            .includeRecall
                )

            total =
                vocabularyGroups.count

            guard total > 0 else {

                throw SentenceManagerError
                    .noVocabulary
            }

            await generateCurrentSentence()

        } catch {

            errorMessage =
                error.localizedDescription
        }
    }

    func retry() async {

        guard
            !isComplete,
            currentIndex <
                vocabularyGroups.count
        else {
            return
        }

        errorMessage =
            nil

        await generateCurrentSentence()
    }

    func rate(
        _ rating:
            SentenceRating
    ) async {

        guard !isLoading else {
            return
        }

        ratings.append(
            rating
        )

        let nextIndex =
            currentIndex + 1

        guard
            nextIndex <
                vocabularyGroups.count
        else {

            currentSentence =
                nil

            currentIndex =
                total

            isComplete =
                true

            return
        }

        currentIndex =
            nextIndex

        currentSentence =
            nil

        errorMessage =
            nil

        await generateCurrentSentence()
    }

    // MARK: - Generation

    private func generateCurrentSentence()
        async {

        guard
            let configuration,
            currentIndex <
                vocabularyGroups.count,
            currentIndex <
                directions.count
        else {
            return
        }

        isLoading =
            true

        defer {

            isLoading =
                false
        }

        do {

            currentDirection =
                directions[
                    currentIndex
                ]

            currentSentence =
                try await generator
                    .generate(
                        vocabulary:
                            vocabularyGroups[
                                currentIndex
                            ],
                        level:
                            configuration.level,
                        types:
                            configuration
                                .selectedSentenceTypes
                    )

        } catch {

            currentSentence =
                nil

            errorMessage =
                error.localizedDescription
        }
    }

    // MARK: - Vocabulary Groups

    private func makeVocabularyGroups(
        vocabulary:
            [SentenceVocabulary],
        count:
            Int,
        density:
            SentenceDensity
    ) -> [[SentenceVocabulary]] {

        guard
            !vocabulary.isEmpty,
            count > 0
        else {
            return []
        }

        var shuffled =
            vocabulary.shuffled()

        var cursor =
            0

        var groups:
            [[SentenceVocabulary]] = []

        for _ in 0..<count {

            let requestedCount =
                Int.random(
                    in: density.range
                )

            let groupCount =
                min(
                    requestedCount,
                    vocabulary.count
                )

            if cursor + groupCount >
                shuffled.count {

                shuffled =
                    vocabulary.shuffled()

                cursor =
                    0
            }

            let end =
                min(
                    cursor + groupCount,
                    shuffled.count
                )

            let group =
                Array(
                    shuffled[
                        cursor..<end
                    ]
                )

            if !group.isEmpty {

                groups.append(
                    group
                )
            }

            cursor =
                end
        }

        return groups
    }

    // MARK: - Directions

    private func makeDirections(
        count: Int,
        recognition: Bool,
        recall: Bool
    ) -> [CardType] {

        guard count > 0 else {
            return []
        }

        if recognition && recall {

            let recognitionFirst =
                Bool.random()

            return (0..<count)
                .map { index in

                    let even =
                        index.isMultiple(
                            of: 2
                        )

                    if recognitionFirst {

                        return even
                            ? .recognition
                            : .recall

                    } else {

                        return even
                            ? .recall
                            : .recognition
                    }
                }
        }

        if recognition {

            return Array(
                repeating:
                    CardType.recognition,
                count:
                    count
            )
        }

        if recall {

            return Array(
                repeating:
                    CardType.recall,
                count:
                    count
            )
        }

        return []
    }
}


private enum SentenceManagerError:
    LocalizedError {

    case noVocabulary

    var errorDescription: String? {

        switch self {

        case .noVocabulary:
            return """
            No vocabulary is available for these settings. Try another deck, tag, or vocabulary source.
            """
        }
    }
}
