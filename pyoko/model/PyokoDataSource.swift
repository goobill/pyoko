import Foundation
import SwiftData

enum DataSourceOrigin: String, Codable {
    case custom
    case defaultCatalog
}

@Model
final class PyokoDataSource {
    
    // MARK: - Identity
    
    var id: UUID = UUID()
    
    /// Stable identifier for Pyoko's built-in catalog sources.
    /// Custom sources use nil.
    var catalogKey: String?
    
    // MARK: - Metadata
    
    var name: String = ""
    
    var origin: DataSourceOrigin = DataSourceOrigin.custom
    
    var importedAt: Date = Date.now
    
    // MARK: - Aggregate Import Data
    
    var vocabularyCount: Int = 0
    
    var recognitionCount: Int = 0
    
    var recallCount: Int = 0
    
    // MARK: - Relationships
    
    @Relationship(
        deleteRule: .cascade,
        inverse: \PyokoCard.source
    )
    var cards: [PyokoCard]? = []
    
    /// Inverse of PyokoConfiguration.selectedSources.
    ///
    /// Deleting a configuration must not delete a source.
    var configurations: [PyokoConfiguration]? = []
    
    // MARK: - Computed
    
    var totalCardCount: Int {
        recognitionCount + recallCount
    }
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        catalogKey: String? = nil,
        name: String,
        origin: DataSourceOrigin = DataSourceOrigin.custom,
        vocabularyCount: Int = 0,
        recognitionCount: Int = 0,
        recallCount: Int = 0,
        importedAt: Date = Date.now
    ) {
        self.id = id
        self.catalogKey = catalogKey
        self.name = name
        self.origin = origin
        self.vocabularyCount = vocabularyCount
        self.recognitionCount = recognitionCount
        self.recallCount = recallCount
        self.importedAt = importedAt
    }
}
