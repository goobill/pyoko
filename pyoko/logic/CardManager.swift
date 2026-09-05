import Foundation
import SwiftData
import FSRS

// MARK: - Errors

enum CardManagerError: LocalizedError {
    
    case cardNotFound
    case reviewCardNotFound
    
    var errorDescription: String? {
        
        switch self {
            
        case .cardNotFound:
            return "The card could not be found."
            
        case .reviewCardNotFound:
            return "The review card could not be found."
        }
    }
}

// MARK: - Review Progress

struct ReviewProgress {
    
    let completed: Int
    let total: Int
    
    var remaining: Int {
        max(total - completed, 0)
    }
}

// MARK: - Review Configuration

private struct ReviewConfiguration {
    
    let dailyCardLimit: Int
    
    let selectedSourceIDs: Set<UUID>
    
    /// Empty means no tag filter.
    let selectedTagIDs: Set<UUID>
}

// MARK: - Card Manager

@MainActor
final class CardManager {
    
    private let modelContext: ModelContext
    
    private let scheduler: FSRS
    
    init(
        modelContext: ModelContext
    ) {
        self.modelContext = modelContext
        
        self.scheduler = FSRS(
            parameters: .init()
        )
    }
    
    // MARK: - Start Review
    
    func startReviewIfNeeded() {
        
        do {
            
            let reviewCards =
                try fetchReviewCards()
            
            // No existing session.
            if reviewCards.isEmpty {
                
                try generateReviewCards()
                
                return
            }
            
            // A new day always gets a new queue.
            if isNewDay(reviewCards) {
                
                try generateReviewCards()
                
                return
            }
            
            // Otherwise today's existing queue
            // remains unchanged.
            
        } catch {
            
            print(
                "Failed to start review: \(error)"
            )
        }
    }
    
    // MARK: - Next Card
    
    func getNextCard() -> PyokoCard? {
        
        do {
            
            let descriptor =
                FetchDescriptor<PyokoReviewCard>(
                    predicate:
                        #Predicate<PyokoReviewCard> {
                            reviewCard in
                            
                            !reviewCard.reviewed
                        },
                    sortBy: [
                        SortDescriptor(
                            \PyokoReviewCard.reviewDate,
                            order: .forward
                        )
                    ]
                )
            
            let reviewCards =
                try modelContext.fetch(
                    descriptor
                )
            
            // The relationship is optional for
            // future CloudKit compatibility.
            //
            // Ignore temporarily incomplete
            // relationship records.
            
            return reviewCards
                .compactMap {
                    $0.card
                }
                .first
            
        } catch {
            
            print(
                "Failed to get next card: \(error)"
            )
            
            return nil
        }
    }
    
    // MARK: - Progress
    
    func getProgress() -> ReviewProgress {
        
        do {
            
            let reviewCards =
                try fetchReviewCards()
            
            let validReviewCards =
                reviewCards.filter {
                    $0.card != nil
                }
            
            let completed =
                validReviewCards.filter {
                    $0.reviewed
                }
                .count
            
            return ReviewProgress(
                completed: completed,
                total: validReviewCards.count
            )
            
        } catch {
            
            print(
                "Failed to get review progress: \(error)"
            )
            
            return ReviewProgress(
                completed: 0,
                total: 0
            )
        }
    }
    
    // MARK: - Review Card
    
    func reviewCard(
        id: UUID,
        rating: Rating
    ) throws {
        
        guard let card =
            getCard(
                id: id
            )
        else {
            throw CardManagerError.cardNotFound
        }
        
        guard let reviewCard =
            try getReviewCard(
                cardID: id
            )
        else {
            throw CardManagerError
                .reviewCardNotFound
        }
        
        let fsrsCard =
            makeFSRSCard(
                from: card
            )
        
        let result =
            try scheduler.next(
                card: fsrsCard,
                now: .now,
                grade: rating
            )
        
        update(
            card: card,
            with: result.card
        )
        
        reviewCard.reviewed = true
        
        try modelContext.save()
    }
    
    // MARK: - Reset
    
    func resetReviewCards() {
        
        do {
            
            let reviewCards =
                try fetchReviewCards()
            
            for reviewCard in reviewCards {
                
                modelContext.delete(
                    reviewCard
                )
            }
            
            try modelContext.save()
            
        } catch {
            
            print(
                "Failed to reset review cards: \(error)"
            )
        }
    }
    
    // MARK: - Card
    
    func getCard(
        id: UUID
    ) -> PyokoCard? {
        
        let cardID = id
        
        let descriptor =
            FetchDescriptor<PyokoCard>(
                predicate:
                    #Predicate<PyokoCard> {
                        card in
                        
                        card.id == cardID
                    }
            )
        
        do {
            
            return try modelContext
                .fetch(descriptor)
                .first
            
        } catch {
            
            print(
                "Failed to fetch card: \(error)"
            )
            
            return nil
        }
    }
    
    // MARK: - Review Cards
    
    private func fetchReviewCards()
        throws -> [PyokoReviewCard] {
        
        let descriptor =
            FetchDescriptor<PyokoReviewCard>(
                sortBy: [
                    SortDescriptor(
                        \PyokoReviewCard.reviewDate,
                        order: .forward
                    )
                ]
            )
        
        return try modelContext.fetch(
            descriptor
        )
    }
    
    private func getReviewCard(
        cardID: UUID
    ) throws -> PyokoReviewCard? {
        
        let reviewCards =
            try fetchReviewCards()
        
        return reviewCards.first {
            
            $0.card?.id == cardID &&
            !$0.reviewed
        }
    }
    
    // MARK: - Generate Session
    
    private func generateReviewCards()
        throws {
        
        // Remove yesterday's / previous session.
        
        let existingReviewCards =
            try fetchReviewCards()
        
        for reviewCard
            in existingReviewCards {
            
            modelContext.delete(
                reviewCard
            )
        }
        
        let configuration =
            try getReviewConfiguration()
        
        let eligibleCards =
            try fetchEligibleCards(
                configuration:
                    configuration
            )
        
        let selectedCards =
            Array(
                eligibleCards.prefix(
                    configuration
                        .dailyCardLimit
                )
            )
        
        let reviewDate = Date.now
        
        for card in selectedCards {
            
            let reviewCard =
                PyokoReviewCard(
                    reviewDate:
                        reviewDate,
                    reviewed:
                        false,
                    card:
                        card
                )
            
            modelContext.insert(
                reviewCard
            )
        }
        
        try modelContext.save()
    }
    
    // MARK: - Configuration
    
    private func getReviewConfiguration()
        throws -> ReviewConfiguration {
        
        let descriptor =
            FetchDescriptor<PyokoConfiguration>()
        
        if let configuration =
            try modelContext
                .fetch(descriptor)
                .first {
            
            return ReviewConfiguration(
                dailyCardLimit:
                    max(
                        configuration
                            .dailyCardLimit,
                        1
                    ),
                selectedSourceIDs:
                    Set(
                        configuration
                            .sources
                            .map(
                                \.id
                            )
                    ),
                selectedTagIDs:
                    Set(
                        configuration
                            .tags
                            .map(
                                \.id
                            )
                    )
            )
        }
        
        // No configuration has been saved yet.
        //
        // Default behaviour matches the
        // ConfigurationView:
        //
        // - 20 cards
        // - all installed sources
        // - no tag filter
        
        let sourceDescriptor =
            FetchDescriptor<PyokoDataSource>()
        
        let sources =
            try modelContext.fetch(
                sourceDescriptor
            )
        
        return ReviewConfiguration(
            dailyCardLimit: 20,
            selectedSourceIDs:
                Set(
                    sources.map(
                        \.id
                    )
                ),
            selectedTagIDs: []
        )
    }
    
    // MARK: - Eligible Cards
    
    private func fetchEligibleCards(
        configuration:
            ReviewConfiguration
    ) throws -> [PyokoCard] {
        
        guard
            !configuration
                .selectedSourceIDs
                .isEmpty
        else {
            return []
        }
        
        let now = Date.now
        
        // Let SwiftData handle the cheap
        // due-date filtering and ordering.
        
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
        
        let dueCards =
            try modelContext.fetch(
                descriptor
            )
        
        // Relationship filtering happens in
        // Swift.
        //
        // This keeps the predicates simple and
        // safely handles optional CloudKit-ready
        // relationships.
        
        return dueCards.filter { card in
            
            guard let sourceID =
                card.source?.id
            else {
                return false
            }
            
            // Source filter
            
            guard configuration
                .selectedSourceIDs
                .contains(
                    sourceID
                )
            else {
                return false
            }
            
            // Empty selected tags means:
            //
            // "No tag filter"
            
            guard
                !configuration
                    .selectedTagIDs
                    .isEmpty
            else {
                return true
            }
            
            // Tag filter
            
            let cardTagIDs =
                Set(
                    (card.tags ?? [])
                        .map(
                            \.id
                        )
                )
            
            return !cardTagIDs
                .isDisjoint(
                    with:
                        configuration
                            .selectedTagIDs
                )
        }
    }
    
    // MARK: - Date
    
    private func isNewDay(
        _ reviewCards:
            [PyokoReviewCard]
    ) -> Bool {
        
        guard let reviewDate =
            reviewCards
                .first?
                .reviewDate
        else {
            return true
        }
        
        return !Calendar.current
            .isDate(
                reviewDate,
                inSameDayAs:
                    Date.now
            )
    }
    
    // MARK: - FSRS
    
    private func makeFSRSCard(
        from card: PyokoCard
    ) -> Card {
        
        Card(
            due:
                card.due,
            stability:
                card.stability,
            difficulty:
                card.difficulty,
            elapsedDays:
                card.elapsedDays,
            scheduledDays:
                card.scheduledDays,
            learningSteps:
                card.learningSteps,
            reps:
                card.reps,
            lapses:
                card.lapses,
            state:
                card.state,
            lastReview:
                card.lastReview
        )
    }
    
    private func update(
        card: PyokoCard,
        with fsrsCard: Card
    ) {
        
        card.due =
            fsrsCard.due
        
        card.stability =
            fsrsCard.stability
        
        card.difficulty =
            fsrsCard.difficulty
        
        card.elapsedDays =
            fsrsCard.elapsedDays
        
        card.scheduledDays =
            fsrsCard.scheduledDays
        
        card.learningSteps =
            fsrsCard.learningSteps
        
        card.reps =
            fsrsCard.reps
        
        card.lapses =
            fsrsCard.lapses
        
        card.state =
            fsrsCard.state
        
        card.lastReview =
            fsrsCard.lastReview
    }
}
