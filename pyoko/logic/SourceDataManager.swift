//
//  SourceDataManager.swift
//  pyoko
//
//  Created by Bill on 05/09/2026.
//

import Foundation
import SwiftData

@MainActor
final class SourceDataManager {
    
    private let modelContext: ModelContext
    
    init(
        modelContext: ModelContext
    ) {
        self.modelContext = modelContext
    }
    
    // MARK: - Install Default Source
    
    func install(
        _ source: DefaultDataSource
    ) async throws {
        
        let loader = DataLoader(
            modelContext: modelContext
        )
        
        try await loader.loadFromURL(
            sourceName: source.name,
            urlString: source.urlString,
            createRecognition: true,
            createRecall: true,
            catalogKey: source.key,
            origin: DataSourceOrigin.defaultCatalog
        )
    }
    
    // MARK: - Delete
    
    func delete(
        _ source: PyokoDataSource
    ) throws {
        
        modelContext.delete(source)
        
        try modelContext.save()
    }
}
