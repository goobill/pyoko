import Foundation

struct DefaultDeck: Identifiable, Hashable {
    
    let key: String
    let name: String
    let description: String
    let urlString: String
    
    var id: String {
        key
    }
}

// MARK: - Built-in Deck Catalogue

enum DefaultDecks {
    
    static let n5 = DefaultDeck(
        key: "jlpt-n5",
        name: "JLPT N5",
        description: "Beginner Japanese vocabulary for JLPT N5.",
        urlString: "https://example.com/n5.csv"
    )
    
    static let n4 = DefaultDeck(
        key: "jlpt-n4",
        name: "JLPT N4",
        description: "Elementary Japanese vocabulary for JLPT N4.",
        urlString: "https://example.com/n4.csv"
    )
    
    static let all: [DefaultDeck] = [
        n5,
        n4
    ]
}
