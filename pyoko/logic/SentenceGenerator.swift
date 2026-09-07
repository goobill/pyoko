//
//  SentenceGenerator.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum SentenceGeneratorError:
    LocalizedError {

    case noVocabulary
    case unavailable(String)
    case invalidResponse

    var errorDescription: String? {

        switch self {

        case .noVocabulary:
            return """
            No vocabulary is available for sentence generation.
            """

        case .unavailable(let message):
            return message

        case .invalidResponse:
            return """
            The model returned an incomplete sentence. Please try again.
            """
        }
    }
}


@MainActor
final class SentenceGenerator {

    var availability:
        SentenceModelAvailability {

        #if canImport(FoundationModels)

        if #available(
            iOS 26.0,
            macOS 26.0,
            *
        ) {

            switch SystemLanguageModel
                .default
                .availability {

            case .available:
                return .available

            case .unavailable(
                .deviceNotEligible
            ):
                return .deviceNotEligible

            case .unavailable(
                .appleIntelligenceNotEnabled
            ):
                return .appleIntelligenceDisabled

            case .unavailable(
                .modelNotReady
            ):
                return .modelNotReady

            case .unavailable:
                return .unavailable

            @unknown default:
                return .unavailable
            }
        }

        #endif

        return .unsupportedSystem
    }

    func generate(
        vocabulary: [SentenceVocabulary],
        level: SentenceLevel,
        types: [SentenceType]
    ) async throws -> PyokoSentence {

        guard !vocabulary.isEmpty else {
            throw SentenceGeneratorError
                .noVocabulary
        }

        guard availability.isAvailable else {
            throw SentenceGeneratorError
                .unavailable(
                    availability.message
                )
        }

        #if canImport(FoundationModels)

        if #available(
            iOS 26.0,
            macOS 26.0,
            *
        ) {

            return try await
                generateUsingFoundationModels(
                    vocabulary: vocabulary,
                    level: level,
                    types: types
                )
        }

        #endif

        throw SentenceGeneratorError
            .unavailable(
                availability.message
            )
    }
}


#if canImport(FoundationModels)

@available(
    iOS 26.0,
    macOS 26.0,
    *
)
@Generable
private struct GeneratedJapaneseAlternative {

    var japanese: String
    var hiragana: String
}


@available(
    iOS 26.0,
    macOS 26.0,
    *
)
@Generable
private struct GeneratedSentenceResponse {

    var english: String

    var japanese: String
    var hiragana: String

    var alternativeEnglish: [String]

    var alternativeJapanese:
        [GeneratedJapaneseAlternative]

    var usedVocabulary: [String]
}


@available(
    iOS 26.0,
    macOS 26.0,
    *
)
private extension SentenceGenerator {

    func generateUsingFoundationModels(
        vocabulary: [SentenceVocabulary],
        level: SentenceLevel,
        types: [SentenceType]
    ) async throws -> PyokoSentence {

        let model =
            SystemLanguageModel.default

        guard model.isAvailable else {
            throw SentenceGeneratorError
                .unavailable(
                    availability.message
                )
        }

        let session =
            LanguageModelSession(
                instructions: """
                You create natural Japanese language-learning exercises.

                Create exactly one natural Japanese sentence using the supplied target vocabulary where possible.

                Return a faithful English translation and a full hiragana reading.

                Also provide approximately two natural alternative English translations and approximately two natural alternative Japanese answers.

                Alternative Japanese answers must preserve the original meaning and include their own hiragana readings.

                Never force vocabulary into an unnatural sentence. Natural Japanese is more important than mechanically including every item.

                Keep the response concise.
                """
            )

        let vocabularyText =
            vocabulary
                .map { item in

                    let reading =
                        item.targetReading
                        ?? item.targetText

                    return """
                    - English: \(item.sourceText)
                      Japanese: \(item.targetText)
                      Reading: \(reading)
                    """
                }
                .joined(
                    separator: "\n"
                )

        let typeText: String

        if types.isEmpty {

            typeText =
                "Use any natural sentence type."

        } else {

            typeText =
                types
                    .map {
                        "- \($0.promptInstruction)"
                    }
                    .joined(
                        separator: "\n"
                    )
        }

        let promptText =
            """
            Create one Japanese practice sentence.

            Vocabulary:
            \(vocabularyText)

            Difficulty:
            \(level.promptInstruction)

            Allowed sentence styles:
            \(typeText)

            Requirements:
            - Prefer using all supplied vocabulary naturally.
            - Do not change the intended meaning of vocabulary just to fit the sentence.
            - Japanese should use normal Japanese orthography.
            - Hiragana must represent the full Japanese sentence in hiragana.
            - English must accurately translate the Japanese.
            - Alternative answers must preserve the same meaning.
            - Return only the requested structured result.
            """

        let prompt =
            Prompt(
                promptText
            )

        let response =
            try await session.respond(
                to: prompt,
                generating:
                    GeneratedSentenceResponse.self
            )

        let generated =
            response.content

        let english =
            generated.english
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let japanese =
            generated.japanese
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let hiragana =
            generated.hiragana
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard
            !english.isEmpty,
            !japanese.isEmpty,
            !hiragana.isEmpty
        else {
            throw SentenceGeneratorError
                .invalidResponse
        }

        let englishAlternatives =
            generated.alternativeEnglish
                .map {
                    $0.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                }
                .filter {
                    !$0.isEmpty
                }
                .prefix(2)

        let japaneseAlternatives =
            generated.alternativeJapanese
                .map {
                    PyokoSentenceAlternative(
                        japanese:
                            $0.japanese
                                .trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                ),
                        hiragana:
                            $0.hiragana
                                .trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                )
                    )
                }
                .filter {
                    !$0.japanese.isEmpty
                    && !$0.hiragana.isEmpty
                }
                .prefix(2)

        return PyokoSentence(
            english: english,
            japanese: japanese,
            hiragana: hiragana,
            alternativeEnglish:
                Array(
                    englishAlternatives
                ),
            alternativeJapanese:
                Array(
                    japaneseAlternatives
                ),
            usedVocabulary:
                generated.usedVocabulary
        )
    }
}

#endif
