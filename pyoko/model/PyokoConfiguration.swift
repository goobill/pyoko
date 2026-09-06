import Foundation
import SwiftData

enum TargetDisplayMode: String, Codable, CaseIterable {
    
    case target
    case reading
    case targetAndReading
    
    var title: String {
        switch self {
        case .target:
            return "Target"
            
        case .reading:
            return "Reading"
            
        case .targetAndReading:
            return "Target + Reading"
        }
    }
}

@Model
final class PyokoConfiguration {
    
    var id: UUID = UUID()
    
    // MARK: - Review
    
    var dailyCardLimit: Int = 20
    
    var showRecognitionCards: Bool = true
    
    var showRecallCards: Bool = true
    
    // MARK: - Display
    
    var beforeAnswerDisplayMode:
        TargetDisplayMode = TargetDisplayMode.target
    
    var afterAnswerDisplayMode:
        TargetDisplayMode = TargetDisplayMode.targetAndReading
    
    // MARK: - Sources
    
    @Relationship(
        deleteRule: .nullify,
        inverse: \PyokoDataSource.configurations
    )
    var selectedSources:
        [PyokoDataSource]? = []
    
    // MARK: - Tags
    
    @Relationship(
        deleteRule: .nullify,
        inverse: \PyokoTag.configurations
    )
    var selectedTags:
        [PyokoTag]? = []
    
    // MARK: - Helpers
    
    var sources: [PyokoDataSource] {
        selectedSources ?? []
    }
    
    var tags: [PyokoTag] {
        selectedTags ?? []
    }
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        dailyCardLimit: Int = 20,
        showRecognitionCards: Bool = true,
        showRecallCards: Bool = true,
        beforeAnswerDisplayMode: TargetDisplayMode = .target,
        afterAnswerDisplayMode: TargetDisplayMode = .targetAndReading,
        selectedSources: [PyokoDataSource] = [],
        selectedTags: [PyokoTag] = []
    ) {
        self.id = id
        
        self.dailyCardLimit =
            dailyCardLimit
        
        self.showRecognitionCards =
            showRecognitionCards
        
        self.showRecallCards =
            showRecallCards
        
        self.beforeAnswerDisplayMode =
            beforeAnswerDisplayMode
        
        self.afterAnswerDisplayMode =
            afterAnswerDisplayMode
        
        self.selectedSources =
            selectedSources
        
        self.selectedTags =
            selectedTags
    }
}
