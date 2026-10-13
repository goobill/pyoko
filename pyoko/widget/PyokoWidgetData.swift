import Foundation

enum PyokoWidgetMode: String, Codable, CaseIterable {
    case review, random
}

enum PyokoWidgetPair: String, Codable, CaseIterable {
    case kanjiEnglish, hiraganaEnglish, kanjiHiragana

    var title: String {
        switch self {
        case .kanjiEnglish: return "Kanji + English"
        case .hiraganaEnglish: return "Hiragana + English"
        case .kanjiHiragana: return "Kanji + Hiragana"
        }
    }

    func text(for word: PyokoWidgetWord) -> (primary: String, secondary: String?) {
        switch self {
        case .kanjiEnglish: return (word.target, word.source)
        case .hiraganaEnglish: return (word.displayReading, word.source)
        case .kanjiHiragana:
            return (word.target, word.displayReading == word.target ? nil : word.displayReading)
        }
    }
}

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

    // Optional so snapshots created by older versions still decode.
    var deckName: String? = nil

    var displayDeckName: String {
        let name = deckName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Vocabulary" : name
    }


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

    // Optional fields preserve decoding of existing widget snapshots.
    var theme: String? = nil
    var expiresAt: Date? = nil
    var before: TargetDisplayMode? = nil
    var after: TargetDisplayMode? = nil
    var mode: PyokoWidgetMode? = nil
    var pair: PyokoWidgetPair? = nil

    var isRandom: Bool { mode == .random }

    func isExpired(at date: Date) -> Bool {
        expiresAt.map { date >= $0 } ?? false
    }

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
