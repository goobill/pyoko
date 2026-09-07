import Foundation
import SwiftData

@Model
final class PyokoReviewCard {

    var id: UUID =
        UUID()

    var reviewDate: Date =
        Date.now

    var reviewed: Bool =
        false

    var card:
        PyokoCard?

    init(
        id: UUID = UUID(),
        reviewDate: Date = .now,
        reviewed: Bool = false,
        card: PyokoCard? = nil
    ) {

        self.id =
            id

        self.reviewDate =
            reviewDate

        self.reviewed =
            reviewed

        self.card =
            card
    }
}
