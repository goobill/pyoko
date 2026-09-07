import Foundation
import SwiftData

@Model
final class PyokoTag {

    var id: UUID = UUID()

    var name: String = ""

    var cards:
        [PyokoCard]? = []

    var configurations:
        [PyokoConfiguration]? = []

    var sentenceConfigurations:
        [PyokoSentenceConfiguration]? = []

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        name: String = ""
    ) {

        self.id =
            id

        self.name =
            name
    }
}
