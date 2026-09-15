import Foundation
import SwiftData
import Testing
@testable import pyoko

@MainActor
struct DiskPersistenceTests {
    private func container(at url: URL) throws -> ModelContainer {
        let schema = Schema([PyokoDeck.self, PyokoTag.self, PyokoCard.self,
                             PyokoReviewCard.self, PyokoConfig.self, PyokoQuickConfig.self])
        return try ModelContainer(for: schema, configurations: [
            ModelConfiguration("PersistenceTest", schema: schema, url: url, cloudKitDatabase: .none)
        ])
    }

    @Test func reopenedDiskStoreRetainsScheduleConfigAndRelationshipGraph() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        let instant = Date(timeIntervalSince1970: 1_780_000_000)
        // Separate function scopes release all contexts and model references before reopening.
        let id = try seed(url: url, instant: instant)
        try verifyAndDeleteTag(url: url, id: id, instant: instant)
        try verifyTagDeletionAndDeleteDeck(url: url)
        let reopened = try container(at: url)
        let context = ModelContext(reopened)
        #expect(try context.fetchCount(FetchDescriptor<PyokoDeck>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<PyokoCard>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<PyokoReviewCard>()) == 0)
        let review = try #require(context.fetch(FetchDescriptor<PyokoConfig>()).first)
        let quick = try #require(context.fetch(FetchDescriptor<PyokoQuickConfig>()).first)
        #expect((review.selectedDecks ?? []).isEmpty && (quick.selectedDecks ?? []).isEmpty)
        #expect(review.dailyCardLimit == 31 && quick.cardCount == 7)
    }

    private func seed(url: URL, instant: Date) throws -> UUID {
        let database = try container(at: url); let context = ModelContext(database)
        let deck = PyokoDeck(name: "Round Trip", originName: "fixture.csv")
        let tag = PyokoTag(name: "Verb")
        context.insert(deck); context.insert(tag)
        let card = PyokoCard(type: .recall, sourceText: "to eat", targetText: "食べる",
            targetReading: "たべる", deck: deck, tags: [tag], due: instant,
            stability: 12.25, difficulty: 6.5, elapsedDays: 3, scheduledDays: 8,
            learningSteps: 1, reps: 17, lapses: 2, state: .relearning,
            lastReview: instant.addingTimeInterval(-86400))
        context.insert(card)
        context.insert(PyokoReviewCard(reviewDate: instant, reviewed: true, card: card))
        context.insert(PyokoConfig(dailyCardLimit: 31, readingOnlyAnswer: true,
                                   selectedDecks: [deck], selectedTags: [tag]))
        context.insert(PyokoQuickConfig(cardCount: 7, source: .tags, writingEnabled: true,
                                        selectedDecks: [deck], selectedTags: [tag]))
        try context.save()
        return card.id
    }

    private func verifyAndDeleteTag(url: URL, id: UUID, instant: Date) throws {
        let database = try container(at: url); let context = ModelContext(database)
        let card = try #require(context.fetch(FetchDescriptor<PyokoCard>()).first)
        let tag = try #require(context.fetch(FetchDescriptor<PyokoTag>()).first)
        let review = try #require(context.fetch(FetchDescriptor<PyokoConfig>()).first)
        let quick = try #require(context.fetch(FetchDescriptor<PyokoQuickConfig>()).first)
        #expect(card.id == id && card.type == .recall)
        #expect(card.sourceText == "to eat" && card.targetText == "食べる" && card.targetReading == "たべる")
        #expect(card.due == instant && card.lastReview == instant.addingTimeInterval(-86400))
        #expect(card.stability == 12.25 && card.difficulty == 6.5)
        #expect(card.elapsedDays == 3 && card.scheduledDays == 8 && card.learningSteps == 1)
        #expect(card.reps == 17 && card.lapses == 2 && card.state == .relearning)
        #expect(card.deck?.cards?.contains { $0.id == id } == true)
        #expect(tag.cards?.contains { $0.id == id } == true)
        #expect(card.reviewCards?.first?.reviewed == true)
        #expect(card.reviewCards?.first?.card?.id == id)
        #expect(review.selectedDecks?.first?.id == card.deck?.id)
        #expect(review.selectedTags?.first?.id == tag.id && quick.selectedTags?.first?.id == tag.id)
        #expect(review.readingOnlyAnswer && !quick.recognitionReadingOnlyEnabled && quick.writingEnabled)
        context.delete(tag); try context.save()
    }

    private func verifyTagDeletionAndDeleteDeck(url: URL) throws {
        let database = try container(at: url); let context = ModelContext(database)
        let card = try #require(context.fetch(FetchDescriptor<PyokoCard>()).first)
        #expect((card.tags ?? []).isEmpty)
        let review = try #require(context.fetch(FetchDescriptor<PyokoConfig>()).first)
        let quick = try #require(context.fetch(FetchDescriptor<PyokoQuickConfig>()).first)
        #expect((review.selectedTags ?? []).isEmpty && (quick.selectedTags ?? []).isEmpty)
        let deck = try #require(card.deck)
        try DeckManager(modelContext: context).delete(deck)
    }
}
