import Foundation
import SwiftData
import Testing
@testable import pyoko

@MainActor
struct BundledDeckTests {
    private func container() throws -> ModelContainer {
        let schema = Schema([
            PyokoDeck.self, PyokoTag.self, PyokoCard.self, PyokoReviewCard.self,
            PyokoConfig.self, PyokoQuickConfig.self
        ])
        return try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        ])
    }

    @Test func bundledDecksPreserveDisabledDecksAndRejectDuplicates() async throws {
        let store = try container()
        let context = ModelContext(store)
        let manager = DeckManager(modelContext: context)
        _ = try manager.ensureReviewConfigExists()
        try await manager.install(DefaultDecks.n5)
        let n5 = try #require(context.fetch(FetchDescriptor<PyokoDeck>()).first)
        #expect(n5.catalogKey == "jlpt-n5")
        #expect(n5.vocabularyCount == 644)
        #expect(n5.origin == .builtIn)
        #expect(n5.originURLString == nil)
        // Also verify the imported records from a fresh context.
        let freshContext = ModelContext(store)
        let freshManager = DeckManager(modelContext: freshContext)
        let freshN5 = try #require(freshContext.fetch(FetchDescriptor<PyokoDeck>()).first)
        let freshConfig = try freshManager.ensureReviewConfigExists()
        #expect(freshManager.isEnabledForReview(freshN5, config: freshConfig))
        try freshManager.setEnabledForReview(freshN5, enabled: false, config: freshConfig)
        try await freshManager.install(DefaultDecks.n4)
        let check = ModelContext(store)
        let decks = try check.fetch(FetchDescriptor<PyokoDeck>())
        let savedConfig = try #require(check.fetch(FetchDescriptor<PyokoConfig>()).first)
        #expect(decks.count == 2)
        #expect(savedConfig.selectedDecks?.map(\.catalogKey) == ["jlpt-n4"])
        #expect(try check.fetchCount(FetchDescriptor<PyokoCard>()) == 2430)
        #expect(decks.first(where: { $0.catalogKey == "jlpt-n4" })?.vocabularyCount == 571)
        do {
            try await manager.install(DefaultDecks.n5)
            Issue.record("Installing an existing catalogue deck should fail.")
        } catch {
            #expect(try check.fetchCount(FetchDescriptor<PyokoDeck>()) == 2)
            #expect(try check.fetchCount(FetchDescriptor<PyokoCard>()) == 2430)
        }
    }

    @Test func missingResourceDoesNotCreatePartialDeck() throws {
        let store = try container()
        let context = ModelContext(store)
        let deck = DefaultDeck(key: "missing", name: "Missing", description: "", resourceName: "no_such_resource")
        do {
            try DataLoader(modelContext: context).loadBundledDeck(deck)
            Issue.record("A missing bundled file should fail.")
        } catch {
            #expect(try context.fetchCount(FetchDescriptor<PyokoDeck>()) == 0)
            #expect(try context.fetchCount(FetchDescriptor<PyokoCard>()) == 0)
        }
    }
}
