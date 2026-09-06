import Foundation
import SwiftData

@Model
final class PyokoDeck {
    
    // MARK: - Identity
    
    var id: UUID = UUID()
    
    /// Stable identifier for built-in decks.
    ///
    /// Example:
    /// "jlpt-n5"
    var catalogKey: String?
    
    var name: String = ""
    
    // MARK: - Origin
    
    var origin: DeckOrigin =
        DeckOrigin.file
    
    /// Human-readable information about
    /// the original source.
    ///
    /// Examples:
    /// "n5.csv"
    /// "JLPT N5"
    var originName: String?
    
    /// Original URL supplied by the user.
    ///
    /// Used for URL and Google Sheets imports.
    var originURLString: String?
    
    /// Stable source identifier where possible.
    ///
    /// Examples:
    ///
    /// built-in:
    /// "jlpt-n5"
    ///
    /// Google Sheets:
    /// "<spreadsheet-id>:<gid>"
    ///
    /// This will be useful when deck updating
    /// is implemented later.
    var originIdentifier: String?
    
    // MARK: - Counts
    
    var vocabularyCount: Int = 0
    
    var recognitionCount: Int = 0
    
    var recallCount: Int = 0
    
    // MARK: - Import
    
    var importedAt: Date = Date.now
    
    // MARK: - Relationships
    
    @Relationship(
        deleteRule: .cascade,
        inverse: \PyokoCard.deck
    )
    var cards: [PyokoCard]? = []
    
    var configurations:
        [PyokoConfiguration]? = []
    
    // MARK: - Helpers
    
    var totalCardCount: Int {
        recognitionCount +
        recallCount
    }
    
    var originDetail: String? {
        
        switch origin {
            
        case .builtIn:
            
            return originName
            
        case .file:
            
            return originName
            
        case .url:
            
            guard
                let originURLString,
                let url =
                    URL(
                        string:
                            originURLString
                    )
            else {
                return nil
            }
            
            return url.host
            
        case .googleSheets:
            
            return "Google spreadsheet"
            
        case .googleDrive:
            
            return originName
            
        case .iCloudDrive:
            
            return originName
        }
    }
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        catalogKey: String? = nil,
        name: String,
        origin: DeckOrigin = DeckOrigin.file,
        originName: String? = nil,
        originURLString: String? = nil,
        originIdentifier: String? = nil,
        vocabularyCount: Int = 0,
        recognitionCount: Int = 0,
        recallCount: Int = 0,
        importedAt: Date = Date.now
    ) {
        
        self.id = id
        
        self.catalogKey =
            catalogKey
        
        self.name =
            name
        
        self.origin =
            origin
        
        self.originName =
            originName
        
        self.originURLString =
            originURLString
        
        self.originIdentifier =
            originIdentifier
        
        self.vocabularyCount =
            vocabularyCount
        
        self.recognitionCount =
            recognitionCount
        
        self.recallCount =
            recallCount
        
        self.importedAt =
            importedAt
    }
}
