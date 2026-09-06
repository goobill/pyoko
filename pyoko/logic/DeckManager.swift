import Foundation
import SwiftData

@MainActor
final class DeckManager {
    
    private let modelContext: ModelContext
    
    init(
        modelContext: ModelContext
    ) {
        self.modelContext = modelContext
    }
    
    // MARK: - Install Built-in Deck
    
    func install(
        _ deck: DefaultDeck
    ) async throws {
        
        guard
            try !isInstalled(
                catalogKey: deck.key
            )
        else {
            throw DeckManagerError.alreadyInstalled(
                name: deck.name
            )
        }
        
        let loader = DataLoader(
            modelContext: modelContext
        )
        
        try await loader.loadFromURL(
            deckName: deck.name,
            urlString: deck.urlString,
            createRecognition: true,
            createRecall: true,
            catalogKey: deck.key,
            origin: DeckOrigin.builtIn,
            originName: deck.name,
            originIdentifier: deck.key
        )
    }
    
    // MARK: - Installed
    
    func isInstalled(
        catalogKey: String
    ) throws -> Bool {
        
        let key = catalogKey
        
        let descriptor =
            FetchDescriptor<PyokoDeck>(
                predicate:
                    #Predicate<PyokoDeck> { deck in
                        deck.catalogKey == key
                    }
            )
        
        return try modelContext
            .fetch(descriptor)
            .first != nil
    }
    
    func installedDeck(
        catalogKey: String
    ) throws -> PyokoDeck? {
        
        let key = catalogKey
        
        let descriptor =
            FetchDescriptor<PyokoDeck>(
                predicate:
                    #Predicate<PyokoDeck> { deck in
                        deck.catalogKey == key
                    }
            )
        
        return try modelContext
            .fetch(descriptor)
            .first
    }
    
    // MARK: - Delete
    
    func delete(
        _ deck: PyokoDeck
    ) throws {
        
        modelContext.delete(
            deck
        )
        
        try modelContext.save()
    }
    
    // MARK: - Delete Built-in
    
    func deleteBuiltIn(
        catalogKey: String
    ) throws {
        
        guard
            let deck =
                try installedDeck(
                    catalogKey:
                        catalogKey
                )
        else {
            return
        }
        
        try delete(deck)
    }
}

// MARK: - Errors

enum DeckManagerError: LocalizedError {
    
    case alreadyInstalled(
        name: String
    )
    
    case deckNotFound
    
    var errorDescription: String? {
        
        switch self {
            
        case .alreadyInstalled(
            let name
        ):
            
            return """
            "\(name)" is already installed.
            """
            
        case .deckNotFound:
            
            return """
            The deck could not be found.
            """
        }
    }
}
