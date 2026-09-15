import Foundation
import SwiftData
import Testing
@testable import pyoko

@MainActor
struct PersistenceTests {
    @Test func configsPersistIndependentlyWithRelationships() throws {
        let s = try TestStore(); let deck = s.deck(); let tag = PyokoTag(name: "Verb")
        s.context.insert(tag)
        let review = s.config([deck], limit: 30); review.selectedTags = [tag]; review.readingOnlyAnswer = true
        let quick = PyokoQuickConfig(cardCount: 7, source: .tags, writingEnabled: true,
                                      beforeAnswerDisplayMode: .targetAndReading, selectedTags: [tag])
        s.context.insert(quick); try s.context.save()
        let fresh = ModelContext(s.container)
        let savedReview = try #require(fresh.fetch(FetchDescriptor<PyokoConfig>()).first)
        let savedQuick = try #require(fresh.fetch(FetchDescriptor<PyokoQuickConfig>()).first)
        #expect(savedReview.dailyCardLimit == 30 && savedQuick.cardCount == 7)
        #expect(savedReview.readingOnlyAnswer && !savedQuick.recognitionReadingOnlyEnabled)
        #expect(savedQuick.writingEnabled && savedQuick.source == .tags)
        #expect(savedQuick.beforeAnswerDisplayMode == .targetAndReading)
        #expect(savedReview.selectedDecks?.first?.id == deck.id)
        #expect(savedQuick.selectedTags?.first?.id == tag.id)
        #expect(savedReview.createdAt > .distantPast)
    }

    @Test func oldestConfigWins() throws {
        let s = try TestStore(); let deck = s.deck()
        let older = s.config([deck], limit: 5); older.createdAt = Date(timeIntervalSince1970: 0)
        let newer = s.config([], limit: 99); newer.createdAt = s.now
        try s.context.save()
        #expect(try CardRetrieval(modelContext: s.context).getDailyLimit() == 5)
    }
}
