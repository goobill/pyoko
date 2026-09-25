import Foundation
import Testing
@testable import pyoko

@MainActor
struct LockScreenWidgetTests {
    private let word = PyokoWidgetWord(id: "eat", source: "to eat", target: "食べる",
                                      reading: "たべる", deckName: "N5 Vocab")
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test(arguments: [TargetDisplayMode.target, .reading, .targetAndReading], [false, true])
    func lockScreenAlwaysShowsMeaning(_ mode: TargetDisplayMode, _ readingOnly: Bool) {
        let snapshot = PyokoWidgetSnapshot(publishedAt: now, words: [word],
            includeRecognition: false, includeRecall: true, readingOnlyAnswer: readingOnly, before: mode)
        let content = LockScreenWordContent(word: word, snapshot: snapshot, date: now)
        #expect(content.meaning == "to eat" && !content.isEmpty)
        #expect(content.japanese == (mode == .reading ? "たべる" : "食べる"))
        #expect(content.reading == (mode == .targetAndReading ? "たべる" : nil))
        #expect(content.inlineText.contains("to eat"))
    }

    @Test func missingReadingFallsBackAndExpiryHidesOldVocabulary() {
        let noReading = PyokoWidgetWord(id: "eat", source: "to eat", target: "食べる", reading: "  ")
        var snapshot = PyokoWidgetSnapshot(publishedAt: now, words: [noReading],
            includeRecognition: true, includeRecall: true, readingOnlyAnswer: false,
            expiresAt: now.addingTimeInterval(60), before: .reading)
        #expect(LockScreenWordContent(word: noReading, snapshot: snapshot, date: now).japanese == "食べる")
        let expired = LockScreenWordContent(word: noReading, snapshot: snapshot, date: now.addingTimeInterval(60))
        #expect(expired.isEmpty && !expired.inlineText.contains("to eat"))
        snapshot.expiresAt = nil
        #expect(LockScreenWordContent(word: nil, snapshot: snapshot, date: now).isEmpty)
    }
}
