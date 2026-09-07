import Foundation
import SwiftData

@Model
final class PyokoDeck {

    var id: UUID = UUID()

    var catalogKey: String?

    var name: String = ""

    var origin: DeckOrigin =
        DeckOrigin.file

    var originName: String?

    var originURLString: String?

    var originIdentifier: String?

    var vocabularyCount: Int = 0

    var recognitionCount: Int = 0

    var recallCount: Int = 0

    var importedAt: Date =
        Date.now

    @Relationship(
        deleteRule: .cascade,
        inverse: \PyokoCard.deck
    )
    var cards:
        [PyokoCard]? = []

    var configurations:
        [PyokoConfiguration]? = []

    var sentenceConfigurations:
        [PyokoSentenceConfiguration]? = []

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        catalogKey: String? = nil,
        name: String = "",
        origin: DeckOrigin = .file,
        originName: String? = nil,
        originURLString: String? = nil,
        originIdentifier: String? = nil,
        vocabularyCount: Int = 0,
        recognitionCount: Int = 0,
        recallCount: Int = 0,
        importedAt: Date = .now
    ) {

        self.id =
            id

        self.catalogKey =
            catalogKey

        self.name =
            name

        self.origin =
            origin

        self.originName =
            originName

        self.originURLString =
            originURLString

        self.originIdentifier =
            originIdentifier

        self.vocabularyCount =
            vocabularyCount

        self.recognitionCount =
            recognitionCount

        self.recallCount =
            recallCount

        self.importedAt =
            importedAt
    }

    // MARK: - Counts

    var totalCardCount: Int {

        recognitionCount
        + recallCount
    }

    // MARK: - Origin

    var originDetail: String? {

        guard let originName else {
            return nil
        }

        let trimmed =
            originName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }
}
