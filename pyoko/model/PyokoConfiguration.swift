import Foundation
import SwiftData

@Model
final class PyokoConfiguration {

    var id: UUID = UUID()

    var dailyCardLimit: Int = 20

    /// Minimum number of new cards to include
    /// in a newly generated daily review session,
    /// when enough eligible new cards are available.
    ///
    /// 0 means no new cards are guaranteed.
    var minimumNewCards: Int = 0

    var beforeAnswerDisplayMode: TargetDisplayMode =
        TargetDisplayMode.target

    var afterAnswerDisplayMode: TargetDisplayMode =
        TargetDisplayMode.reading

    var showRecognitionCards: Bool = true

    var showRecallCards: Bool = true

    var readingHintEnabled: Bool = true

    @Relationship(
        deleteRule: .nullify,
        inverse: \PyokoDeck.configurations
    )
    var selectedDecks: [PyokoDeck]? = []

    @Relationship(
        deleteRule: .nullify,
        inverse: \PyokoTag.configurations
    )
    var selectedTags: [PyokoTag]? = []

    init(
        id: UUID = UUID(),
        dailyCardLimit: Int = 20,
        minimumNewCards: Int = 0,
        beforeAnswerDisplayMode: TargetDisplayMode = TargetDisplayMode.target,
        afterAnswerDisplayMode: TargetDisplayMode = TargetDisplayMode.reading,
        showRecognitionCards: Bool = true,
        showRecallCards: Bool = true,
        readingHintEnabled: Bool = true,
        selectedDecks: [PyokoDeck]? = [],
        selectedTags: [PyokoTag]? = []
    ) {
        self.id = id
        self.dailyCardLimit = dailyCardLimit
        self.minimumNewCards = minimumNewCards
        self.beforeAnswerDisplayMode = beforeAnswerDisplayMode
        self.afterAnswerDisplayMode = afterAnswerDisplayMode
        self.showRecognitionCards = showRecognitionCards
        self.showRecallCards = showRecallCards
        self.readingHintEnabled = readingHintEnabled
        self.selectedDecks = selectedDecks
        self.selectedTags = selectedTags
    }
}
