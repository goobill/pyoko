import Foundation
import SwiftData

@Model
final class PyokoSentenceConfiguration {

    var id: UUID = UUID()

    var sentenceCount: Int = 10

    var source: SentenceSource =
        SentenceSource.random

    var density: SentenceDensity =
        SentenceDensity.normal

    var level: SentenceLevel =
        SentenceLevel.beginner

    var includePresent: Bool = true

    var includePast: Bool = true

    var includeFuture: Bool = false

    var includeConnecting: Bool = false

    var includeLonger: Bool = false

    var includeRecognition: Bool = true

    var includeRecall: Bool = true

    var display: SentenceDisplay =
        SentenceDisplay.both

    @Relationship(
        deleteRule: .nullify,
        inverse:
            \PyokoDeck.sentenceConfigurations
    )
    var selectedDecks:
        [PyokoDeck]? = []

    @Relationship(
        deleteRule: .nullify,
        inverse:
            \PyokoTag.sentenceConfigurations
    )
    var selectedTags:
        [PyokoTag]? = []

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        sentenceCount: Int = 10,
        source: SentenceSource = .random,
        density: SentenceDensity = .normal,
        level: SentenceLevel = .beginner,
        includePresent: Bool = true,
        includePast: Bool = true,
        includeFuture: Bool = false,
        includeConnecting: Bool = false,
        includeLonger: Bool = false,
        includeRecognition: Bool = true,
        includeRecall: Bool = true,
        display: SentenceDisplay = .both,
        selectedDecks: [PyokoDeck]? = [],
        selectedTags: [PyokoTag]? = []
    ) {

        self.id =
            id

        self.sentenceCount =
            sentenceCount

        self.source =
            source

        self.density =
            density

        self.level =
            level

        self.includePresent =
            includePresent

        self.includePast =
            includePast

        self.includeFuture =
            includeFuture

        self.includeConnecting =
            includeConnecting

        self.includeLonger =
            includeLonger

        self.includeRecognition =
            includeRecognition

        self.includeRecall =
            includeRecall

        self.display =
            display

        self.selectedDecks =
            selectedDecks

        self.selectedTags =
            selectedTags
    }

    // MARK: - Sentence Types

    var selectedSentenceTypes:
        [SentenceType] {

        var types:
            [SentenceType] = []

        if includePresent {

            types.append(
                .present
            )
        }

        if includePast {

            types.append(
                .past
            )
        }

        if includeFuture {

            types.append(
                .future
            )
        }

        if includeConnecting {

            types.append(
                .connecting
            )
        }

        if includeLonger {

            types.append(
                .longer
            )
        }

        return types
    }

    // MARK: - Validation

    var hasSentenceType: Bool {

        !selectedSentenceTypes.isEmpty
    }

    var hasDirection: Bool {

        includeRecognition
        || includeRecall
    }
}
