import Foundation
import SwiftData

@Model
final class PyokoReviewCard {
    
    // MARK: - Identity
    
    var id: UUID = UUID()
    
    // MARK: - Review
    
    var reviewDate: Date = Date.now
    
    var reviewed: Bool = false
    
    // MARK: - Relationship
    
    var card: PyokoCard?
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        reviewDate: Date = Date.now,
        reviewed: Bool = false,
        card: PyokoCard? = nil
    ) {
        self.id = id
        self.reviewDate = reviewDate
        self.reviewed = reviewed
        self.card = card
    }
}
