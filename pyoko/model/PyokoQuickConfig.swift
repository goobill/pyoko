import Foundation
import SwiftData

@Model
final class PyokoQuickConfig {

    var id: UUID = UUID()

    var cardCount: Int = 20

    var source: QuickSource =
        QuickSource.random

    var writingEnabled: Bool = false

    var includeRecognition: Bool = true

    var includeRecall: Bool = true

    var beforeAnswerDisplayMode:
        TargetDisplayMode =
            TargetDisplayMode.target

    var afterAnswerDisplayMode:
        TargetDisplayMode =
            TargetDisplayMode.reading

    var readingHintEnabled: Bool = true

    @Relationship(
        deleteRule: .nullify,
        inverse: \PyokoDeck.quickConfigs
    )
    var selectedDecks:
        [PyokoDeck]? = []

    @Relationship(
        deleteRule: .nullify,
        inverse: \PyokoTag.quickConfigs
    )
    var selectedTags:
        [PyokoTag]? = []

    init(
        id: UUID = UUID(),
        cardCount: Int = 20,
        source: QuickSource = .random,
        writingEnabled: Bool = false,
        includeRecognition: Bool = true,
        includeRecall: Bool = true,
        beforeAnswerDisplayMode:
            TargetDisplayMode = .target,
        afterAnswerDisplayMode:
            TargetDisplayMode = .reading,
        readingHintEnabled: Bool = true,
        selectedDecks: [PyokoDeck]? = [],
        selectedTags: [PyokoTag]? = []
    ) {

        self.id =
            id

        self.cardCount =
            cardCount

        self.source =
            source

        self.writingEnabled =
            writingEnabled

        self.includeRecognition =
            includeRecognition

        self.includeRecall =
            includeRecall

        self.beforeAnswerDisplayMode =
            beforeAnswerDisplayMode

        self.afterAnswerDisplayMode =
            afterAnswerDisplayMode

        self.readingHintEnabled =
            readingHintEnabled

        self.selectedDecks =
            selectedDecks

        self.selectedTags =
            selectedTags
    }

    var hasDirection: Bool {

        includeRecognition
        || includeRecall
    }
}
