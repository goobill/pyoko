//
//  PreviewData.swift
//  pyoko
//
//  Created by Bill on 03/09/2026.
//

import SwiftData

enum PreviewData {
    
    static let container: ModelContainer = {
        let schema = Schema([
            PyokoCard.self,
            ReviewPyokoCard.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            let context = container.mainContext
            
            // Add preview cards
            let card1 = PyokoCard(
                id: 1,
                sourceId: 1,
                type: .recall,
                japanese: "こんにちは",
                reading: "こんにちは",
                english: "hello"
            )
            
            let card2 = PyokoCard(
                id: 2,
                sourceId: 2,
                type: .recall,
                japanese: "ありがとう",
                reading: "ありがとう",
                english: "thank you"
            )
            
            context.insert(card1)
            context.insert(card2)
            
            try context.save()
            
            return container
            
        } catch {
            fatalError("Could not create preview container: \(error)")
        }
    }()
}
