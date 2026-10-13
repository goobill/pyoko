import Foundation

/// Device-specific widget preferences, independent of scheduled and quick review.
struct PyokoWidgetConfig: Codable, Equatable {
    static let preferenceKey = "widgetConfig"
    enum Source: String, Codable, CaseIterable {
        case all, decks, tags, filtered, today
        static var allCases: [Self] { [.all, .decks, .tags, .today] }
        var title: String {
            switch self {
            case .all: return "All Enabled Cards"
            case .decks: return "Selected Decks"
            case .tags: return "Selected Tags"
            case .filtered: return "Choose Cards and Tags"
            case .today: return "Today's Review Words"
            }
        }
    }
    var deckIDs: Set<UUID>? = nil
    var before: TargetDisplayMode? = nil
    var after: TargetDisplayMode? = nil
    var source: Source = .all
    var tagIDs: Set<UUID> = []
    var wordIDs: Set<String> = []
    var chooseCards = false
    var recognition = true
    var recall = true
    var readingOnly = false
    var theme = "system"
    // Optional for compatibility with preferences saved before these options existed.
    var mode: PyokoWidgetMode? = nil
    var pair: PyokoWidgetPair? = nil

    static func decode(_ data: Data) -> Self {
        (try? JSONDecoder().decode(Self.self, from: data)) ?? Self()
    }
    var encoded: Data { (try? JSONEncoder().encode(self)) ?? Data() }
}
