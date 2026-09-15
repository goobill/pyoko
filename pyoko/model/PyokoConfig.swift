import Foundation
import SwiftData

@Model
final class PyokoConfig {

    var id: UUID = UUID()

    // Existing configs migrate to the oldest date. New devices use that config
    // when it arrives instead of keeping an independently-created default.
    var createdAt: Date = Date(timeIntervalSince1970: 0)

    var dailyCardLimit: Int = 20

    var minimumNewCards: Int = 0

    var beforeAnswerDisplayMode:
        TargetDisplayMode =
            TargetDisplayMode.target

    var afterAnswerDisplayMode:
        TargetDisplayMode =
            TargetDisplayMode.reading

    var showRecognitionCards: Bool = true

    var showRecallCards: Bool = true

    var readingHintEnabled: Bool = true

    /// When enabled, Recognition cards that have
    /// a reading become:
    ///
    /// Target -> Reading
    ///
    /// Example:
    /// 食べる -> たべる
    ///
    /// Recall cards are unaffected.
    var readingOnlyAnswer: Bool = false

    @Relationship(
        deleteRule: .nullify,
        inverse: \PyokoDeck.configs
    )
    var selectedDecks:
        [PyokoDeck]? = []

    @Relationship(
        deleteRule: .nullify,
        inverse: \PyokoTag.configs
    )
    var selectedTags:
        [PyokoTag]? = []

    init(
        id: UUID = UUID(),
        dailyCardLimit: Int = 20,
        minimumNewCards: Int = 0,
        beforeAnswerDisplayMode:
            TargetDisplayMode = .target,
        afterAnswerDisplayMode:
            TargetDisplayMode = .reading,
        showRecognitionCards: Bool = true,
        showRecallCards: Bool = true,
        readingHintEnabled: Bool = true,
        readingOnlyAnswer: Bool = false,
        selectedDecks: [PyokoDeck]? = [],
        selectedTags: [PyokoTag]? = []
    ) {

        self.createdAt = .now

        self.id =
            id

        self.dailyCardLimit =
            dailyCardLimit

        self.minimumNewCards =
            minimumNewCards

        self.beforeAnswerDisplayMode =
            beforeAnswerDisplayMode

        self.afterAnswerDisplayMode =
            afterAnswerDisplayMode

        self.showRecognitionCards =
            showRecognitionCards

        self.showRecallCards =
            showRecallCards

        self.readingHintEnabled =
            readingHintEnabled

        self.readingOnlyAnswer =
            readingOnlyAnswer

        self.selectedDecks =
            selectedDecks

        self.selectedTags =
            selectedTags
    }
}
