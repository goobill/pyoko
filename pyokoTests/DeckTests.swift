import SwiftData
import Testing
@testable import pyoko

@MainActor
struct DeckTests {
    @Test func enablementIsIdempotentAndClearsUnavailableTags() throws {
        let s = try TestStore(); let deck = s.deck(); let card = s.card(deck)
        let tag = PyokoTag(name: "Verb"); s.context.insert(tag); card.tags = [tag]
        let config = s.config([deck]); config.selectedTags = [tag]; try s.context.save()
        let manager = DeckManager(modelContext: s.context)
        try manager.setEnabledForReview(deck, enabled: true)
        try manager.setEnabledForReview(deck, enabled: true)
        #expect(config.selectedDecks?.count == 1)
        try manager.setEnabledForReview(deck, enabled: false)
        #expect(config.selectedDecks?.isEmpty == true && config.selectedTags?.isEmpty == true)
        #expect(card.reps == 0)
        #expect(try s.context.fetchCount(FetchDescriptor<PyokoCard>()) == 1)
    }

    @Test func deleteCascadesCardsAndQueueButKeepsOtherDeck() throws {
        let s = try TestStore(); let removed = s.deck(), retained = s.deck("N4")
        let card = s.card(removed); _ = s.card(retained); let config = s.config([removed, retained])
        s.context.insert(PyokoReviewCard(card: card)); try s.context.save()
        try DeckManager(modelContext: s.context).delete(removed)
        #expect(try s.context.fetchCount(FetchDescriptor<PyokoDeck>()) == 1)
        #expect(try s.context.fetchCount(FetchDescriptor<PyokoCard>()) == 1)
        #expect(try s.context.fetchCount(FetchDescriptor<PyokoReviewCard>()) == 0)
        #expect(config.selectedDecks?.map(\.id) == [retained.id])
    }

    @Test func creatingConfigSelectsExistingDecksOnlyOnce() throws {
        let s = try TestStore(); let deck = s.deck(); try s.context.save()
        let manager = DeckManager(modelContext: s.context)
        let first = try manager.ensureReviewConfigExists()
        let second = try manager.ensureReviewConfigExists()
        #expect(first.id == second.id)
        #expect(first.selectedDecks?.map(\.id) == [deck.id])
    }
}
