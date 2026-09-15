import Foundation
import SwiftData
import Testing
@testable import pyoko

@MainActor
struct QuickTests {
    @Test func singleFamilyTagSurvivesSavingAndStartingAQuickSession() throws {
        let s = try TestStore()
        try s.importCSV("source,target,reading,tags\nfamily,家族,かぞく,Family\ncat,猫,ねこ,Animals\n", name: "Tagged")
        let family = try #require(s.context.fetch(FetchDescriptor<PyokoTag>()).first { $0.name == "Family" })
        let orphanTag = PyokoTag(name: "Old Family")
        s.context.insert(orphanTag)
        let config = PyokoQuickConfig(source: .tags, includeRecall: false, selectedTags: [family])
        s.context.insert(config); try s.context.save()
        let fresh = ModelContext(s.container)
        let saved = try #require(fresh.fetch(FetchDescriptor<PyokoQuickConfig>()).first)
        let manager = QuickManager(modelContext: fresh)
        try manager.start(config: saved)
        #expect(manager.currentCard()?.targetText == "家族")
        #expect(manager.getProgress().total == 1)
        let old = try #require(fresh.fetch(FetchDescriptor<PyokoTag>()).first { $0.name == "Old Family" })
        saved.selectedTags = [old]; try fresh.save()
        try manager.start(config: saved)
        #expect(manager.currentCard() == nil)
    }

    @Test(arguments: [CardType.recognition, .recall])
    func previouslyReviewedUsesLifetimeGradesFromEnabledDecks(_ direction: CardType) throws {
        let s = try TestStore(); let enabled = s.deck(); let disabled = s.deck("Disabled")
        let learned = s.card(enabled)
        learned.reps = 1
        learned.lastReview = s.now.addingTimeInterval(-90 * 86400)
        learned.due = s.now.addingTimeInterval(30 * 86400)
        // The unreviewed opposite direction must not create duplicate vocabulary.
        _ = s.card(enabled, type: .recall)
        let unseen = s.card(enabled, kanji: "新しい")
        // Merely entering today's queue does not count as having reviewed a card.
        s.context.insert(PyokoReviewCard(reviewDate: s.now, card: unseen))
        let excluded = s.card(disabled, kanji: "別"); excluded.reps = 3
        let orphan = PyokoCard(type: .recognition, sourceText: "orphan", targetText: "孤", deck: nil, reps: 2)
        s.context.insert(orphan)
        let reviewConfig = s.config([enabled])
        let config = PyokoQuickConfig(cardCount: 100, source: .reviewed,
            includeRecognition: direction == .recognition, includeRecall: direction == .recall)
        s.context.insert(config); try s.context.save()
        let selector = QuickSelector(modelContext: s.context)
        let before = ScheduleState(learned)
        let cards = try selector.getCards(config: config)
        #expect(cards.count == 1)
        #expect(cards.first?.targetText == "食べる" && cards.first?.type == direction)
        let manager = QuickManager(modelContext: s.context)
        try manager.start(config: config); manager.markCurrent(.correct)
        #expect(ScheduleState(learned) == before && unseen.reps == 0)
        let fresh = ModelContext(s.container)
        #expect(try fresh.fetch(FetchDescriptor<PyokoQuickConfig>()).first?.source == .reviewed)
        config.includeRecognition = true; config.includeRecall = true; config.cardCount = 1
        #expect(try selector.getCards(config: config).count == 1)
        reviewConfig.selectedDecks = []; try s.context.save()
        #expect(try selector.getCards(config: config).isEmpty)
    }

    @Test func previouslyReviewedIsEmptyBeforeAnyScheduledGrade() throws {
        let s = try TestStore(); let deck = s.deck(); _ = s.card(deck)
        _ = s.config([deck]); try s.context.save()
        let manager = QuickManager(modelContext: s.context)
        try manager.start(config: PyokoQuickConfig(source: .random, includeRecall: false))
        manager.markCurrent(.correct)
        #expect(try QuickSelector(modelContext: s.context)
            .getCards(config: PyokoQuickConfig(source: .reviewed)).isEmpty)
    }

    @Test func skipAdvancesWithoutScoringAndKeepsRetryMistakes() throws {
        let s = try TestStore(); let deck = s.deck(); let card = s.card(deck)
        try s.context.save()
        let before = ScheduleState(card)
        let manager = QuickManager(modelContext: s.context)
        try manager.start(config: PyokoQuickConfig(source: .decks, includeRecall: false, selectedDecks: [deck]))
        manager.skipCurrent(); manager.skipCurrent()
        #expect(manager.isComplete && manager.currentCard() == nil)
        #expect(manager.getProgress().completed == 1)
        #expect(manager.getProgress().correct == 0 && manager.getProgress().incorrect == 0)
        #expect(!manager.canReviewIncorrect)
        manager.reset()
        #expect(manager.currentCard() != nil && manager.getProgress().completed == 0)
        manager.markCurrent(.incorrect); manager.reviewIncorrect(); manager.skipCurrent()
        #expect(manager.isComplete && manager.canReviewIncorrect)
        #expect(manager.getProgress().incorrect == 1 && manager.getProgress().correct == 0)
        #expect(ScheduleState(card) == before)
        #expect(try s.context.fetchCount(FetchDescriptor<PyokoReviewCard>()) == 0)
    }

    @Test func emptyStoreCannotGenerateSession() throws {
        let store = try TestStore()
        let cards = try QuickSelector(modelContext: store.context).getCards(config: PyokoQuickConfig())
        #expect(cards.isEmpty)
    }

    @Test func selectedDecksDeduplicateRecognitionRecallPairs() throws {
        let s = try TestStore(); let deck = s.deck()
        _ = s.card(deck); _ = s.card(deck, type: .recall)
        _ = s.card(s.deck("Other"), kanji: "別"); try s.context.save()
        let config = PyokoQuickConfig(source: .decks, selectedDecks: [deck])
        let cards = try QuickSelector(modelContext: s.context).getCards(config: config)
        #expect(cards.count == 2)
        #expect(Set(cards.map(\.type)) == [.recognition, .recall])
        #expect(Set(cards.map(\.id)).count == 2)
        #expect(cards.allSatisfy { $0.targetText == "食べる" })
    }

    @Test func randomUsesEnabledDecksAndRespectsLimits() throws {
        let s = try TestStore(); let deck = s.deck(); _ = s.card(deck)
        _ = s.card(s.deck("Disabled"), kanji: "別"); _ = s.config([deck]); try s.context.save()
        let selector = QuickSelector(modelContext: s.context)
        let config = PyokoQuickConfig(cardCount: 1, includeRecognition: false)
        let cards = try selector.getCards(config: config)
        #expect(cards.count == 1 && cards.first?.type == .recall && cards.first?.targetText == "食べる")
        config.cardCount = 0; #expect(try selector.getCards(config: config).isEmpty)
        config.cardCount = 20; config.includeRecall = false
        #expect(try selector.getCards(config: config).isEmpty)
    }

    @Test func tagSourceUsesMatchingVocabulary() throws {
        let s = try TestStore(); let deck = s.deck(); let tagged = s.card(deck)
        _ = s.card(deck, kanji: "別")
        let tag = PyokoTag(name: "Verb"); s.context.insert(tag); tagged.tags = [tag]; try s.context.save()
        let config = PyokoQuickConfig(source: .tags, includeRecall: false, selectedTags: [tag])
        #expect(try QuickSelector(modelContext: s.context).getCards(config: config).map(\.targetText) == ["食べる"])
        config.selectedTags = []
        #expect(try QuickSelector(modelContext: s.context).getCards(config: config).isEmpty)
    }

    @Test func retryReplacesMistakeAndResetPreservesFSRS() throws {
        let s = try TestStore(); let deck = s.deck(); let stored = s.card(deck); try s.context.save()
        let originalDue = stored.due
        let config = PyokoQuickConfig(source: .decks, includeRecall: false, selectedDecks: [deck])
        let manager = QuickManager(modelContext: s.context); try manager.start(config: config)
        manager.markCurrent(.incorrect)
        #expect(manager.isComplete && manager.canReviewIncorrect)
        #expect(manager.getProgress().incorrect == 1)
        manager.reviewIncorrect(); #expect(manager.getProgress().total == 1)
        manager.markCurrent(.correct); manager.markCurrent(.incorrect)
        #expect(manager.getProgress().correct == 1 && manager.getProgress().incorrect == 0)
        #expect(!manager.canReviewIncorrect)
        manager.reset()
        #expect(manager.getProgress().reviewed == 0 && manager.currentCard() != nil)
        #expect(stored.due == originalDue && stored.reps == 0 && stored.lastReview == nil)
        #expect(try s.context.fetchCount(FetchDescriptor<PyokoReviewCard>()) == 0)
    }

    @Test func todayIncludesCompletedOnlyAndUnionsTags() throws {
        let s = try TestStore(); let deck = s.deck(); let a = s.card(deck), b = s.card(deck, type: .recall)
        let tagA = PyokoTag(name: "A"), tagB = PyokoTag(name: "B")
        s.context.insert(tagA); s.context.insert(tagB); a.tags = [tagA]; b.tags = [tagB]
        for card in [a,b] { s.context.insert(PyokoReviewCard(reviewDate: s.now, reviewed: true, card: card)) }
        let pending = s.card(deck, kanji: "pending")
        s.context.insert(PyokoReviewCard(reviewDate: s.now, card: pending))
        let old = s.card(deck, kanji: "old")
        s.context.insert(PyokoReviewCard(reviewDate: s.now.addingTimeInterval(-86400), reviewed: true, card: old))
        s.context.insert(PyokoReviewCard(reviewDate: s.now, reviewed: true, card: nil))
        try s.context.save()
        let provider = TodayReviewProvider(modelContext: s.context, clock: { s.now })
        let words = try provider.getVocabulary()
        #expect(words.count == 1 && words.first?.tagIDs == [tagA.id,tagB.id])
        #expect(try provider.hasVocabulary())
        #expect(try provider.vocabularyCount() == 1)
    }
}
