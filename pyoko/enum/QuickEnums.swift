import Foundation

enum QuickSource: String, Codable, CaseIterable, Identifiable {

    case random
    case decks
    case tags
    case todaysReview

    var id: String {
        rawValue
    }

    var title: String {

        switch self {

        case .random:
            return "Random Vocabulary"

        case .decks:
            return "Selected Decks"

        case .tags:
            return "Selected Tags"

        case .todaysReview:
            return "Today's Review"
        }
    }

    var subtitle: String {

        switch self {

        case .random:
            return "Use vocabulary from your enabled review decks."

        case .decks:
            return "Choose specific decks for this session."

        case .tags:
            return "Choose specific tags for this session."

        case .todaysReview:
            return "Practise vocabulary you reviewed today."
        }
    }
}

// MARK: - Quick Review Result

enum QuickAnswerResult {

    case correct
    case incorrect
}
