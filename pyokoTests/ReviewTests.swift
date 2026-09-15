import Foundation
import SwiftData
import Testing
import FSRS
@testable import pyoko

@MainActor
struct ReviewTests {
    @Test func respectsDeckDirectionTagsAndDueDate() throws {
        let s = try TestStore()
        let enabled = s.deck(), disabled = s.deck("N4")
        let match = s.card(enabled)
        let tag = PyokoTag(name: "Verb"); s.context.insert(tag); match.tags = [tag]
        _ = s.card(disabled)
        _ = s.card(enabled, type: .recall)
        _ = s.card(enabled, kanji: "明日", offset: 60)
        _ = s.card(enabled, kanji: "本")
        let config = s.config([enabled]); config.showRecallCards = false; config.selectedTags = [tag]
        try s.context.save()
        let retrieval = CardRetrieval(modelContext: s.context, clock: { s.now })
        #expect(try retrieval.getCardsForReview().map(\.id) == [match.id])
        #expect(try retrieval.getDueCardCount(excludingCardIDs: [match.id]) == 0)
        config.selectedDecks = []
        #expect(try retrieval.getCardsForReview().isEmpty)
    }

    @Test func reservesNewCardsAndHonoursLimit() throws {
        let s = try TestStore(); let deck = s.deck()
        let new = s.card(deck, kanji: "新", offset: -10)
        for i in 0..<4 { let card = s.card(deck, kanji: "review\(i)", offset: -1000 - Double(i)); card.state = .review }
        _ = s.config([deck], limit: 3, minimumNew: 1)
        try s.context.save()
        let cards = try CardRetrieval(modelContext: s.context, clock: { s.now }).getCardsForReview()
        #expect(cards.count == 3)
        #expect(cards.contains { $0.id == new.id })
        #expect(cards.filter { $0.state == .review }.count == 2)
        #expect(cards.map(\.due) == cards.map(\.due).sorted())
    }

    @Test func separatesLaterTodayFromTomorrowAndExclusions() throws {
        let s = try TestStore(); let deck = s.deck(); _ = s.config([deck])
        let later = s.card(deck, offset: 3600)
        _ = s.card(deck, kanji: "tomorrow", offset: 86400)
        try s.context.save()
        let r = CardRetrieval(modelContext: s.context, clock: { s.now })
        #expect(try r.getDueCardCount() == 0)
        #expect(try r.getLaterTodayCardCount() == 1)
        #expect(try r.getNextDueDateToday() == later.due)
        #expect(try r.getLaterTodayCardCount(excludingCardIDs: [later.id]) == 0)
        #expect(try r.getCardsForExtension(limit: 0).isEmpty)
    }

    @Test func resumesQueueAndPreviewDoesNotWriteScheduling() throws {
        let s = try TestStore(); let deck = s.deck(); let card = s.card(deck); _ = s.config([deck])
        try s.context.save()
        let manager = CardManager(modelContext: s.context, clock: { s.now })
        manager.startReviewIfNeeded(); manager.startReviewIfNeeded()
        #expect(try s.context.fetchCount(FetchDescriptor<PyokoReviewCard>()) == 1)
        let before = card.due
        let preview = try manager.getIntervalPreview(id: card.id)
        #expect(preview.generatedAt == s.now)
        #expect(card.due == before && card.reps == 0 && card.lastReview == nil)
        #expect(manager.getProgress().completed == 0)
        try manager.reviewCard(id: card.id, rating: .good)
        #expect(card.reps == 1 && card.lastReview == s.now)
        #expect(card.due > s.now)
        #expect(manager.getProgress().completed == 1)
        #expect(manager.getNextCard() == nil)
        #expect(throws: (any Error).self) { try manager.reviewCard(id: card.id, rating: .good) }
        #expect(card.reps == 1)
    }

    @Test func extensionRequiresCompletionAndAddsNextBatch() throws {
        let s = try TestStore(); let deck = s.deck()
        _ = s.card(deck, offset: -100); _ = s.card(deck, kanji: "本", offset: -10)
        _ = s.config([deck], limit: 1); try s.context.save()
        let m = CardManager(modelContext: s.context, clock: { s.now })
        m.startReviewIfNeeded()
        #expect(throws: (any Error).self) { try m.extendReviewSession() }
        let first = try #require(m.getNextCard()); try m.reviewCard(id: first.id, rating: .easy)
        #expect(try m.extendReviewSession() == 1)
        #expect(m.getProgress().total == 2)
        #expect(m.getNextCard()?.id != first.id)
    }

    @Test func newDayReplacesQueueAndInvalidIDsFail() throws {
        let s = try TestStore(); let deck = s.deck(); let card = s.card(deck); _ = s.config([deck])
        s.context.insert(PyokoReviewCard(reviewDate: s.now.addingTimeInterval(-86400), reviewed: true, card: card))
        try s.context.save()
        let m = CardManager(modelContext: s.context, clock: { s.now }); m.startReviewIfNeeded()
        #expect(m.getProgress().remaining == 1)
        #expect(try s.context.fetchCount(FetchDescriptor<PyokoReviewCard>()) == 1)
        #expect(throws: (any Error).self) { try m.reviewCard(id: UUID(), rating: .good) }
        #expect(throws: (any Error).self) { try m.getIntervalPreview(id: UUID()) }
        m.resetReviewCards()
        #expect(try s.context.fetchCount(FetchDescriptor<PyokoReviewCard>()) == 0)
        #expect(try s.context.fetchCount(FetchDescriptor<PyokoCard>()) == 1)
    }
}
