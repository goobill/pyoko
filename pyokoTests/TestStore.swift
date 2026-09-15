import Foundation
import SwiftData
@testable import pyoko

/// Each test owns an isolated store; no fixture can touch iCloud or the app database.
@MainActor
final class TestStore {
    let container: ModelContainer
    let context: ModelContext
    let now = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 9, hour: 12))!

    init() throws {
        let schema = Schema([PyokoDeck.self, PyokoTag.self, PyokoCard.self,
                             PyokoReviewCard.self, PyokoConfig.self,
                             PyokoQuickConfig.self])
        container = try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        ])
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    func deck(_ name: String = "N5 Vocab") -> PyokoDeck {
        let deck = PyokoDeck(name: name)
        context.insert(deck)
        return deck
    }

    func card(_ deck: PyokoDeck, type: CardType = .recognition,
              english: String = "to eat", kanji: String = "食べる",
              reading: String? = "たべる", offset: TimeInterval = -60) -> PyokoCard {
        let card = PyokoCard(type: type, sourceText: english, targetText: kanji,
                             targetReading: reading, deck: deck, due: now.addingTimeInterval(offset))
        context.insert(card)
        return card
    }

    func config(_ decks: [PyokoDeck], limit: Int = 20, minimumNew: Int = 0) -> PyokoConfig {
        let config = PyokoConfig(dailyCardLimit: limit, minimumNewCards: minimumNew, selectedDecks: decks)
        context.insert(config)
        return config
    }

    func importCSV(_ csv: String, name: String = "Imported", recognition: Bool = true, recall: Bool = true) throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("csv")
        try Data(csv.utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        try DataLoader(modelContext: context).loadFromFile(deckName: name, url: file,
                                                         createRecognition: recognition, createRecall: recall)
    }
}
