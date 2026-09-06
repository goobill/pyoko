//
//  CardRetrieval.swift
//  pyoko
//
//  Created by Bill on 05/09/2026.
//

import Foundation
import SwiftData

struct CardRetrieval {
    
    private let modelContext: ModelContext
    
    init(
        modelContext: ModelContext
    ) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public
    
    func getCardsForReview()
        throws -> [PyokoCard] {
        
        let configuration =
            try getConfiguration()
        
        let allSources =
            try getAllSources()
        
        let settings =
            makeReviewSettings(
                configuration: configuration,
                allSources: allSources
            )
        
        let dueCards =
            try getDueCards()
        
        let filteredCards =
            filterCards(
                dueCards,
                using: settings
            )
        
        return Array(
            filteredCards
                .sorted {
                    $0.due < $1.due
                }
                .prefix(
                    settings.dailyCardLimit
                )
        )
    }
    
    // MARK: - Configuration
    
    private func getConfiguration()
        throws -> PyokoConfiguration? {
        
        let descriptor =
            FetchDescriptor<
                PyokoConfiguration
            >()
        
        return try modelContext
            .fetch(descriptor)
            .first
    }
    
    // MARK: - Sources
    
    private func getAllSources()
        throws -> [PyokoDataSource] {
        
        let descriptor =
            FetchDescriptor<
                PyokoDataSource
            >()
        
        return try modelContext
            .fetch(descriptor)
    }
    
    // MARK: - Due Cards
    
    private func getDueCards()
        throws -> [PyokoCard] {
        
        let now = Date()
        
        let descriptor =
            FetchDescriptor<PyokoCard>(
                predicate:
                    #Predicate<PyokoCard> {
                        card in
                        
                        card.due <= now
                    }
            )
        
        return try modelContext
            .fetch(descriptor)
    }
    
    // MARK: - Settings
    
    private func makeReviewSettings(
        configuration: PyokoConfiguration?,
        allSources: [PyokoDataSource]
    ) -> ReviewSettings {
        
        guard let configuration else {
            
            return ReviewSettings(
                dailyCardLimit: 20,
                showRecognitionCards: true,
                showRecallCards: true,
                sourceIDs:
                    Set(
                        allSources.map(\.id)
                    ),
                tagIDs: []
            )
        }
        
        return ReviewSettings(
            dailyCardLimit:
                configuration.dailyCardLimit,
            
            showRecognitionCards:
                configuration
                    .showRecognitionCards,
            
            showRecallCards:
                configuration
                    .showRecallCards,
            
            sourceIDs:
                Set(
                    configuration
                        .sources
                        .map(\.id)
                ),
            
            tagIDs:
                Set(
                    configuration
                        .tags
                        .map(\.id)
                )
        )
    }
    
    // MARK: - Filtering
    
    private func filterCards(
        _ cards: [PyokoCard],
        using settings:
            ReviewSettings
    ) -> [PyokoCard] {
        
        cards.filter { card in
            
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
    }
    
    // MARK: Source Filter
    
    private func matchesSource(
        _ card: PyokoCard,
        settings: ReviewSettings
    ) -> Bool {
        
        guard
            let sourceID =
                card.source?.id
        else {
            return false
        }
        
        return settings
            .sourceIDs
            .contains(
                sourceID
            )
    }
    
    // MARK: Card Type Filter
    
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
    
    // MARK: Tag Filter
    
    private func matchesTags(
        _ card: PyokoCard,
        settings: ReviewSettings
    ) -> Bool {
        
        // No selected tags means:
        // do not filter by tags.
        
        guard
            !settings.tagIDs.isEmpty
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
                    settings.tagIDs
            )
    }
}

// MARK: - Review Settings

private struct ReviewSettings {
    
    let dailyCardLimit: Int
    
    let showRecognitionCards: Bool
    
    let showRecallCards: Bool
    
    let sourceIDs: Set<UUID>
    
    let tagIDs: Set<UUID>
}
