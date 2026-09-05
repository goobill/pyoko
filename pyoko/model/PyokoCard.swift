import Foundation
import SwiftData
import FSRS

@Model
final class PyokoCard {
    
    // MARK: - Identity
    
    var id: UUID = UUID()
    
    // MARK: - Vocabulary
    
    var type: CardType = CardType.recognition
    
    var english: String = ""
    
    var japanese: String = ""
    
    // MARK: - Source
    
    var source: PyokoDataSource?
    
    // MARK: - Tags
    
    @Relationship(
        deleteRule: .nullify,
        inverse: \PyokoTag.cards
    )
    var tags: [PyokoTag]? = []
    
    // MARK: - Review Session
    
    @Relationship(
        deleteRule: .cascade,
        inverse: \PyokoReviewCard.card
    )
    var reviewCards: [PyokoReviewCard]? = []
    
    // MARK: - FSRS
    
    var due: Date = Date.now
    
    var stability: Double = 0
    
    var difficulty: Double = 0
    
    var elapsedDays: Double = 0
    
    var scheduledDays: Double = 0
    
    var learningSteps: Int = 0
    
    var reps: Int = 0
    
    var lapses: Int = 0
    
    var state: CardState = CardState.new
    
    var lastReview: Date?
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        type: CardType,
        english: String,
        japanese: String,
        source: PyokoDataSource?,
        tags: [PyokoTag] = [],
        due: Date = Date.now,
        stability: Double = 0,
        difficulty: Double = 0,
        elapsedDays: Double = 0,
        scheduledDays: Double = 0,
        learningSteps: Int = 0,
        reps: Int = 0,
        lapses: Int = 0,
        state: CardState = CardState.new,
        lastReview: Date? = nil
    ) {
        self.id = id
        
        self.type = type
        
        self.english = english
        self.japanese = japanese
        
        self.source = source
        self.tags = tags
        
        self.due = due
        self.stability = stability
        self.difficulty = difficulty
        
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        
        self.learningSteps = learningSteps
        
        self.reps = reps
        self.lapses = lapses
        
        self.state = state
        
        self.lastReview = lastReview
    }
}

enum CardType: String, Codable {
    case recognition = "RECOGNITION"
    case recall = "RECALL"
}

//extension PyokoCard {
//    static let sample = sampleData[0]
//    
//    static let sampleData = [
//        PyokoCard(
//            id: 1,
//            type: .recall,
//            japanese: "食べる",
//            reading: "たべる",
//            english: "to eat",
//        ),
//        PyokoCard(
//            id: 2,
//            type: .recognition,
//            japanese: "食べる",
//            reading: "たべる",
//            english: "to eat",
//        ),
//        PyokoCard(
//            id: 3,
//            type: .recall,
//            japanese: "飲む",
//            reading: "のむ",
//            english: "to drink"
//        ),
//        PyokoCard(
//            id: 4,
//            type: .recognition,
//            japanese: "飲む",
//            reading: "のむ",
//            english: "to drink"
//        ),
//        PyokoCard(
//            id: 5,
//            type: .recall,
//            japanese: "行く",
//            reading: "いく",
//            english: "to go"
//        ),
//        PyokoCard(
//            id: 6,
//            type: .recognition,
//            japanese: "行く",
//            reading: "いく",
//            english: "to go"
//        )
//    ]
//}
