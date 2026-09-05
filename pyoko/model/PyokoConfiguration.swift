import Foundation
import SwiftData

enum TargetDisplayMode: String, Codable, CaseIterable {
    
    case target
    case reading
    
    var title: String {
        
        switch self {
            
        case .target:
            return "Target"
            
        case .reading:
            return "Reading"
        }
    }
}

@Model
final class PyokoConfiguration {
    
    // MARK: - Identity
    
    var id: UUID = UUID()
    
    // MARK: - Study
    
    var dailyCardLimit: Int = 20
    
    // MARK: - Target Display
    
    var beforeAnswerDisplayMode: TargetDisplayMode = TargetDisplayMode.target
    
    var afterAnswerDisplayMode: TargetDisplayMode = TargetDisplayMode.reading
    
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
        beforeAnswerDisplayMode: TargetDisplayMode = .target,
        afterAnswerDisplayMode: TargetDisplayMode = .reading,
        selectedSources: [PyokoDataSource] = [],
        selectedTags: [PyokoTag] = []
    ) {
        self.id = id
        
        self.dailyCardLimit = dailyCardLimit
        
        self.beforeAnswerDisplayMode = beforeAnswerDisplayMode
        self.afterAnswerDisplayMode = afterAnswerDisplayMode
        
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
