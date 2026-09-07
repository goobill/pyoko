//
//  QuickEnums.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

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

enum QuickRating: String, CaseIterable, Identifiable {

    case again
    case hard
    case good
    case easy

    var id: String {
        rawValue
    }

    var title: String {

        switch self {

        case .again:
            return "Again"

        case .hard:
            return "Hard"

        case .good:
            return "Good"

        case .easy:
            return "Easy"
        }
    }

    var repeatsCard: Bool {

        switch self {

        case .again, .hard:
            return true

        case .good, .easy:
            return false
        }
    }
}
