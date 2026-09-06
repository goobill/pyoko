import Foundation
import SwiftData
import FSRS

@Model
final class PyokoCard {
    
    // MARK: - Identity
    
    var id: UUID = UUID()
    
    // MARK: - Card
    
    var type: CardType = CardType.recognition
    
    /// The source-language text.
    ///
    /// Examples:
    /// English: "to eat"
    /// English: "library"
    var sourceText: String = ""
    
    /// The target-language text.
    ///
    /// Examples:
    /// Japanese: "食べる"
    /// French: "manger"
    var targetText: String = ""
    
    /// Optional pronunciation / reading representation
    /// of the target text.
    ///
    /// Japanese:
    /// 食べる → たべる
    ///
    /// French would normally use nil.
    var targetReading: String?
    
    // MARK: - Source
    
    var deck: PyokoDeck?
    
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
        sourceText: String,
        targetText: String,
        targetReading: String? = nil,
        deck: PyokoDeck?,
        tags: [PyokoTag] = [],
        due: Date = .now,
        stability: Double = 0,
        difficulty: Double = 0,
        elapsedDays: Double = 0,
        scheduledDays: Double = 0,
        learningSteps: Int = 0,
        reps: Int = 0,
        lapses: Int = 0,
        state: CardState = .new,
        lastReview: Date? = nil
    ) {
        self.id = id
        self.type = type
        
        self.sourceText = sourceText
        self.targetText = targetText
        self.targetReading = targetReading
        
        self.deck = deck
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
