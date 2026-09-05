import Foundation
import SwiftData

enum KanjiLevel: String, Codable, CaseIterable {
    case n5 = "N5"
    case n4 = "N4"
    case n3 = "N3"
    case n2 = "N2"
    case n1 = "N1"
}

@Model
final class PyokoConfiguration {
    
    // MARK: - Identity
    
    var id: UUID = UUID()
    
    // MARK: - Configuration
    
    var dailyCardLimit: Int = 20
    
    var kanjiLevel: KanjiLevel = KanjiLevel.n5
    
    // MARK: - Sources
    
    @Relationship(
        deleteRule: .nullify,
        inverse: \PyokoDataSource.configurations
    )
    var selectedSources: [PyokoDataSource]? = []
    
    // MARK: - Tags
    
    @Relationship(
        deleteRule: .nullify,
        inverse: \PyokoTag.configurations
    )
    var selectedTags: [PyokoTag]? = []
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        dailyCardLimit: Int = 20,
        kanjiLevel: KanjiLevel = KanjiLevel.n5,
        selectedSources: [PyokoDataSource] = [],
        selectedTags: [PyokoTag] = []
    ) {
        self.id = id
        self.dailyCardLimit = dailyCardLimit
        self.kanjiLevel = kanjiLevel
        self.selectedSources = selectedSources
        self.selectedTags = selectedTags
    }
    
    // MARK: - Convenience
    
    var sources: [PyokoDataSource] {
        selectedSources ?? []
    }
    
    var tags: [PyokoTag] {
        selectedTags ?? []
    }
}
