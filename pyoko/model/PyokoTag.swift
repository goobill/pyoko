import Foundation
import SwiftData

@Model
final class PyokoTag {
    
    // MARK: - Identity
    
    var id: UUID = UUID()
    
    // MARK: - Data
    
    var name: String = ""
    
    // MARK: - Relationships
    
    /// Inverse is defined by PyokoCard.tags.
    var cards: [PyokoCard]? = []
    
    /// Inverse is defined by
    /// PyokoConfiguration.selectedTags.
    var configurations: [PyokoConfiguration]? = []
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        name: String
    ) {
        self.id = id
        self.name = name
    }
}
