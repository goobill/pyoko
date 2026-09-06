import Foundation
import SwiftData

@MainActor
struct CardRetrieval {
    
    private let modelContext: ModelContext
    
    init(
        modelContext: ModelContext
    ) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public
    
    func getCardsForReview() throws -> [PyokoCard] {
        
        let settings =
            try getReviewSettings()
        
        guard
            !settings.selectedSourceIDs.isEmpty
        else {
            return []
        }
        
        let dueCards =
            try fetchDueCards()
        
        let eligibleCards =
            dueCards.filter { card in
                
                matchesSource(
                    card,
                    settings: settings
                )
                &&
                matchesCardType(
                    card,
                    settings: settings
                )
                &&
                matchesTags(
                    card,
                    settings: settings
                )
            }
        
        return Array(
            eligibleCards.prefix(
                settings.dailyCardLimit
            )
        )
    }
    
    // MARK: - Settings
    
    private func getReviewSettings()
        throws -> ReviewSettings {
        
        let configurationDescriptor =
            FetchDescriptor<PyokoConfiguration>()
        
        if let configuration =
            try modelContext
                .fetch(
                    configurationDescriptor
                )
                .first {
            
            return ReviewSettings(
                dailyCardLimit:
                    max(
                        configuration.dailyCardLimit,
                        1
                    ),
                showRecognitionCards:
                    configuration
                        .showRecognitionCards,
                showRecallCards:
                    configuration
                        .showRecallCards,
                selectedSourceIDs:
                    Set(
                        configuration
                            .sources
                            .map(\.id)
                    ),
                selectedTagIDs:
                    Set(
                        configuration
                            .tags
                            .map(\.id)
                    )
            )
        }
        
        // No configuration has been saved yet.
        //
        // Defaults:
        // - 20 cards
        // - Recognition enabled
        // - Recall enabled
        // - all installed decks
        // - no tag filter
        
        let sourceDescriptor =
            FetchDescriptor<PyokoDeck>()
        
        let sources =
            try modelContext.fetch(
                sourceDescriptor
            )
        
        return ReviewSettings(
            dailyCardLimit: 20,
            showRecognitionCards: true,
            showRecallCards: true,
            selectedSourceIDs:
                Set(
                    sources.map(\.id)
                ),
            selectedTagIDs: []
        )
    }
    
    // MARK: - Due Cards
    
    private func fetchDueCards()
        throws -> [PyokoCard] {
        
        let now = Date.now
        
        let descriptor =
            FetchDescriptor<PyokoCard>(
                predicate:
                    #Predicate<PyokoCard> {
                        card in
                        
                        card.due <= now
                    },
                sortBy: [
                    SortDescriptor(
                        \PyokoCard.due,
                        order: .forward
                    )
                ]
            )
        
        return try modelContext.fetch(
            descriptor
        )
    }
    
    // MARK: - Source Filter
    
    private func matchesSource(
        _ card: PyokoCard,
        settings: ReviewSettings
    ) -> Bool {
        
        guard
            let sourceID =
                card.deck?.id
        else {
            return false
        }
        
        return settings
            .selectedSourceIDs
            .contains(
                sourceID
            )
    }
    
    // MARK: - Card Type Filter
    
    private func matchesCardType(
        _ card: PyokoCard,
        settings: ReviewSettings
    ) -> Bool {
        
        switch card.type {
            
        case .recognition:
            
            return settings
                .showRecognitionCards
            
        case .recall:
            
            return settings
                .showRecallCards
        }
    }
    
    // MARK: - Tag Filter
    
    private func matchesTags(
        _ card: PyokoCard,
        settings: ReviewSettings
    ) -> Bool {
        
        // Empty selected tags means:
        // no tag filter.
        
        guard
            !settings
                .selectedTagIDs
                .isEmpty
        else {
            return true
        }
        
        let cardTagIDs =
            Set(
                (card.tags ?? [])
                    .map(\.id)
            )
        
        return !cardTagIDs
            .isDisjoint(
                with:
                    settings
                        .selectedTagIDs
            )
    }
}

// MARK: - Review Settings

private struct ReviewSettings {
    
    let dailyCardLimit: Int
    
    let showRecognitionCards: Bool
    
    let showRecallCards: Bool
    
    let selectedSourceIDs: Set<UUID>
    
    /// Empty means no tag filter.
    let selectedTagIDs: Set<UUID>
}
