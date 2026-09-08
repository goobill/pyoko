import Foundation

enum PyokoWidgetDirection:
    String,
    Codable,
    CaseIterable {

    case recognition
    case recall
}

struct PyokoWidgetWord:
    Codable,
    Identifiable,
    Hashable {

    let id: String

    let source: String

    let target: String

    let reading: String?

    var displayReading: String {

        let trimmedReading =
            reading?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard
            let trimmedReading,
            !trimmedReading.isEmpty
        else {

            return target
        }

        return trimmedReading
    }
}

struct PyokoWidgetSnapshot:
    Codable {

    let publishedAt: Date

    let words:
        [PyokoWidgetWord]

    let includeRecognition: Bool

    let includeRecall: Bool

    let readingOnlyAnswer: Bool

    static let empty =
        PyokoWidgetSnapshot(
            publishedAt:
                .distantPast,
            words:
                [],
            includeRecognition:
                true,
            includeRecall:
                true,
            readingOnlyAnswer:
                false
        )

    func allows(
        _ direction:
            PyokoWidgetDirection
    ) -> Bool {

        switch direction {

        case .recognition:

            return includeRecognition

        case .recall:

            return includeRecall
        }
    }
}
