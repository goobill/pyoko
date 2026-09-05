//
//  Card.swift
//  pyoko
//
//  Created by Bill on 29/08/2026.
//

import Foundation
import SwiftData

//public var due: Date             // Date when the card is next due for review
//public var stability: Double     // A measure of how well the information is retained
//public var difficulty: Double    // Reflects the inherent difficulty of the card content
//public var elapsedDays: Double   // Days since the card was last reviewed
//public var scheduledDays: Double // The interval at which the card is next scheduled
///// 0-based index into `params.learningSteps` / `relearningSteps`. Only
///// meaningful when `state` is `.learning` or `.relearning` — in
///// `.new`/`.review` the value is just 0 because no step applies. Always
///// 0 under v5 (v5's scheduler doesn't expose configurable steps).
//public var learningSteps: Int
//public var reps: Int             // Total number of times the card has been reviewed
//public var lapses: Int           // Times the card was forgotten or remembered incorrectly
//public var state: CardState      // The current state of the card (New, Learning, Review, Relearning)
//public var lastReview: Date?

@Model
final class PyokoCard {
    @Attribute(.unique)
    var id: Int

    // recall or regonition
    var type: CardType
    
    //TODO: add more card breakdown i.e. noun or verb, cooking or family...

    // Vocabulary
    var japanese: String
    var reading: String?
    var english: String

    // FSRS state
    var state: Int
    var due: Date

    var stability: Double?
    var difficulty: Double?

    var elapsedDays: Int
    var scheduledDays: Int

    var learningSteps: Int
    var reps: Int
    var lapses: Int

    var lastReview: Date?
    
    init(
        id: Int,
        type: CardType,
        japanese: String,
        reading: String?,
        english: String,
        state: Int = 0,
        due: Date = .now,
        stability: Double? = nil,
        difficulty: Double? = nil,
        elapsedDays: Int = 0,
        scheduledDays: Int = 0,
        learningSteps: Int = 0,
        reps: Int = 0,
        lapses: Int = 0,
        lastReview: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.japanese = japanese
        self.reading = reading
        self.english = english
        self.state = state
        self.due = due
        self.stability = stability
        self.difficulty = difficulty
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.learningSteps = learningSteps
        self.reps = reps
        self.lapses = lapses
        self.lastReview = lastReview
    }
}

enum CardType: String, Codable {
    case recognition = "RECOGNITION"
    case recall = "RECALL"
}

extension PyokoCard {
    static let sample = sampleData[0]
    
    static let sampleData = [
        PyokoCard(
            id: 1,
            type: .recall,
            japanese: "食べる",
            reading: "たべる",
            english: "to eat",
        ),
        PyokoCard(
            id: 2,
            type: .recognition,
            japanese: "食べる",
            reading: "たべる",
            english: "to eat",
        ),
        PyokoCard(
            id: 3,
            type: .recall,
            japanese: "飲む",
            reading: "のむ",
            english: "to drink"
        ),
        PyokoCard(
            id: 4,
            type: .recognition,
            japanese: "飲む",
            reading: "のむ",
            english: "to drink"
        ),
        PyokoCard(
            id: 5,
            type: .recall,
            japanese: "行く",
            reading: "いく",
            english: "to go"
        ),
        PyokoCard(
            id: 6,
            type: .recognition,
            japanese: "行く",
            reading: "いく",
            english: "to go"
        )
    ]
}
