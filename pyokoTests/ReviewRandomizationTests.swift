import Foundation
import SwiftData
import Testing
@testable import pyoko

@MainActor
struct ReviewRandomizationTests {
    @Test func samplesAcrossDecksAndPreservesSavedOrderOnResume() throws {
        let s = try TestStore()
        let firstDeck = s.deck("First import")
        let lastDeck = s.deck("Last import")
        _ = s.card(firstDeck, kanji: "一", offset: -100)
        _ = s.card(firstDeck, kanji: "二", offset: -90)
        let a = s.card(lastDeck, kanji: "三", offset: -80)
        let b = s.card(lastDeck, kanji: "四", offset: -70)
        _ = s.config([firstDeck, lastDeck], limit: 2)
        try s.context.save()
        var calls = 0
        let manager = CardManager(modelContext: s.context, clock: { s.now }, randomize: {
            calls += 1
            return Array($0.reversed())
        })
        manager.startReviewIfNeeded()
        let descriptor = FetchDescriptor<PyokoReviewCard>(sortBy: [SortDescriptor(\.reviewDate)])
        let queue = try s.context.fetch(descriptor)
        #expect(Set(queue.compactMap { $0.card?.id }) == Set([a.id, b.id]))
        #expect(calls == 2)
        let ids = queue.map(\.id)
        manager.startReviewIfNeeded()
        #expect(try s.context.fetch(descriptor).map(\.id) == ids)
        #expect(calls == 2, "Resuming must not reshuffle a persisted queue")
    }

    @Test func extensionRandomizesBeforeApplyingLimit() throws {
        let s = try TestStore(); let deck = s.deck()
        _ = s.card(deck, kanji: "一", offset: -100)
        let last = s.card(deck, kanji: "二", offset: -50)
        _ = s.config([deck])
        try s.context.save()
        let retrieval = CardRetrieval(modelContext: s.context, clock: { s.now },
                                      randomize: { Array($0.reversed()) })
        #expect(try retrieval.getCardsForExtension(limit: 1).map(\.id) == [last.id])
        #expect(try retrieval.getCardsForExtension(limit: 1, excludingCardIDs: [last.id]).count == 1)
    }
}
