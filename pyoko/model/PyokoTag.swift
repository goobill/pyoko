import Foundation
import SwiftData

@Model
final class PyokoTag {

    var id: UUID = UUID()

    var name: String = ""

    var cards:
        [PyokoCard]? = []

    var configs:
        [PyokoConfig]? = []

    var sentenceConfigs:
        [PyokoSentenceConfig]? = []

    var quickConfigs:
        [PyokoQuickConfig]? = []

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
