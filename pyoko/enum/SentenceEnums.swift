//
//  SentenceEnums.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

import Foundation

enum SentenceSource: String, Codable, CaseIterable, Identifiable {
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

    var description: String {
        switch self {
        case .random:
            return "Choose vocabulary randomly from decks enabled for normal review."
        case .decks:
            return "Choose vocabulary from specific decks."
        case .tags:
            return "Choose vocabulary matching specific tags."
        case .todaysReview:
            return "Use vocabulary from today's review session."
        }
    }
}


enum SentenceDensity: String, Codable, CaseIterable, Identifiable {
    case focused
    case normal
    case challenging

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .focused:
            return "Focused"
        case .normal:
            return "Normal"
        case .challenging:
            return "Challenging"
        }
    }

    var range: ClosedRange<Int> {
        switch self {
        case .focused:
            return 1...1
        case .normal:
            return 2...3
        case .challenging:
            return 4...5
        }
    }

    var description: String {
        switch self {
        case .focused:
            return "1 vocabulary item per sentence"
        case .normal:
            return "2–3 vocabulary items per sentence"
        case .challenging:
            return "4–5 vocabulary items per sentence"
        }
    }
}


enum SentenceLevel: String, Codable, CaseIterable, Identifiable {
    case simple
    case beginner
    case intermediate
    case advanced

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .simple:
            return "Simple"
        case .beginner:
            return "Beginner"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        }
    }

    var promptInstruction: String {
        switch self {
        case .simple:
            return """
            Use very short, simple Japanese with basic sentence structure.
            Avoid difficult grammar.
            """

        case .beginner:
            return """
            Use beginner Japanese appropriate for roughly JLPT N5–N4 learners.
            Prefer common grammar and natural everyday language.
            """

        case .intermediate:
            return """
            Use intermediate Japanese with a wider range of natural grammar,
            while keeping the sentence practical and understandable.
            """

        case .advanced:
            return """
            Use natural advanced Japanese and more sophisticated grammar where appropriate.
            Do not make the sentence unnecessarily obscure.
            """
        }
    }
}


enum SentenceType: String, Codable, CaseIterable, Identifiable {
    case present
    case past
    case future
    case connecting
    case longer

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .present:
            return "Present"
        case .past:
            return "Past"
        case .future:
            return "Future"
        case .connecting:
            return "Connecting"
        case .longer:
            return "Longer Sentences"
        }
    }

    var promptInstruction: String {
        switch self {
        case .present:
            return "Present or habitual tense."
        case .past:
            return "Past tense."
        case .future:
            return "Future intention, plan, or future context."
        case .connecting:
            return "Connect two related ideas naturally."
        case .longer:
            return "Use a slightly longer sentence containing more context."
        }
    }
}


enum SentenceDisplay: String, Codable, CaseIterable, Identifiable {
    case kanji
    case hiragana
    case both

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .kanji:
            return "Kanji"
        case .hiragana:
            return "Hiragana"
        case .both:
            return "Both"
        }
    }
}


enum SentenceRating: String, Codable, CaseIterable, Identifiable {
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
}


enum SentenceModelAvailability: Equatable {
    case available
    case unsupportedSystem
    case deviceNotEligible
    case appleIntelligenceDisabled
    case modelNotReady
    case unavailable

    var isAvailable: Bool {
        self == .available
    }

    var message: String {
        switch self {
        case .available:
            return "Sentence generation is available."

        case .unsupportedSystem:
            return """
            Sentence generation requires iOS 26 or macOS 26 or later.
            """

        case .deviceNotEligible:
            return """
            This device does not support Apple Intelligence.
            """

        case .appleIntelligenceDisabled:
            return """
            Apple Intelligence is turned off. Enable it in system settings to use sentence generation.
            """

        case .modelNotReady:
            return """
            The on-device language model is not ready yet. It may still be downloading.
            """

        case .unavailable:
            return """
            Sentence generation is currently unavailable.
            """
        }
    }
}
