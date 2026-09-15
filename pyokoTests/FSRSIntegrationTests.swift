import Foundation
import SwiftData
import Testing
import FSRS
@testable import pyoko

/// Exercises Pyoko's real scheduler, model mapping, queue and saved results together.
/// The independent FSRS call is an integration oracle; explicit step/state assertions
/// below also protect against an unintended change in the pinned library's defaults.
@MainActor
struct FSRSIntegrationTests {
    @Test(arguments: [Rating.again, .hard, .good, .easy],
          [CardState.new, .learning, .review, .relearning])
    func everyRatingAndStatePersistsTheCompleteFSRSResult(_ rating: Rating, _ state: CardState) throws {
        let s = try TestStore()
        let deck = s.deck()
        let card = s.card(deck)
        card.state = state
        if state != .new {
            card.stability = 8.25; card.difficulty = 6.3
            card.elapsedDays = 3; card.scheduledDays = 7
            card.learningSteps = state == .learning ? 1 : 0
            card.reps = 9; card.lapses = 2
            card.lastReview = s.now.addingTimeInterval(-7 * 86400)
        }
        _ = s.config([deck])
        try s.context.save()
        let input = Card(due: card.due, stability: card.stability, difficulty: card.difficulty,
                         elapsedDays: card.elapsedDays, scheduledDays: card.scheduledDays,
                         learningSteps: card.learningSteps, reps: card.reps, lapses: card.lapses,
                         state: card.state, lastReview: card.lastReview)
        // The pinned FSRS revision seeds fuzzing from the card and review instant.
        let expected = try FSRS(parameters: .init()).next(card: input, now: s.now, grade: rating).card
        let manager = CardManager(modelContext: s.context, clock: { s.now })
        manager.startReviewIfNeeded()
        let preview = try manager.getIntervalPreview(id: card.id)
        #expect(card.due == input.due && card.reps == input.reps)
        #expect(card.stability == input.stability && card.lastReview == input.lastReview)
        try manager.reviewCard(id: card.id, rating: rating)
        let fresh = ModelContext(s.container)
        let saved = try #require(fresh.fetch(FetchDescriptor<PyokoCard>()).first)
        #expect(saved.due == expected.due)
        #expect(saved.due == preview.dueDate(for: rating))
        #expect(saved.stability == expected.stability)
        #expect(saved.difficulty == expected.difficulty)
        #expect(saved.elapsedDays == expected.elapsedDays)
        #expect(saved.scheduledDays == expected.scheduledDays)
        #expect(saved.learningSteps == expected.learningSteps)
        #expect(saved.reps == expected.reps && saved.reps == input.reps + 1)
        #expect(saved.lapses == expected.lapses && saved.state == expected.state)
        #expect(saved.lastReview == s.now && saved.lastReview == expected.lastReview)
        #expect(saved.stability.isFinite && saved.stability > 0)
        #expect(saved.difficulty.isFinite && (1...10).contains(saved.difficulty))
        let queue = try #require(fresh.fetch(FetchDescriptor<PyokoReviewCard>()).first)
        #expect(queue.reviewed && queue.card?.id == saved.id)
        #expect(saved.deck?.id == deck.id && saved.targetText == "食べる")
    }

    @Test func defaultLearningStepsAndGraduationHaveExpectedMeaning() throws {
        let s = try TestStore(); let deck = s.deck(); let card = s.card(deck)
        _ = s.config([deck]); try s.context.save()
        var now = s.now
        let manager = CardManager(modelContext: s.context, clock: { now })
        manager.startReviewIfNeeded()
        let preview = try manager.getIntervalPreview(id: card.id)
        #expect(preview.again.timeIntervalSince(now) == 60)
        // The pinned scheduler rounds the midpoint of 1m and 10m to 6m.
        #expect(preview.hard.timeIntervalSince(now) == 360)
        #expect(preview.good.timeIntervalSince(now) == 600)
        #expect(preview.easy.timeIntervalSince(now) >= 86400)
        try manager.reviewCard(id: card.id, rating: .again)
        #expect(card.state == .learning && card.learningSteps == 0 && card.lapses == 0)
        // Not yet due: an extension must not repeat it prematurely.
        #expect(try manager.extendReviewSession() == 0)
        now = card.due
        #expect(try manager.extendReviewSession() == 1)
        try manager.reviewCard(id: card.id, rating: .good)
        #expect(card.state == .learning && card.learningSteps == 1)
        now = card.due
        #expect(try manager.extendReviewSession() == 1)
        try manager.reviewCard(id: card.id, rating: .good)
        #expect(card.state == .review && card.learningSteps == 0)
        #expect(card.scheduledDays >= 1 && card.due > now)
        #expect(card.reps == 3 && card.lapses == 0)
        // Forget a mature card: lapse count increases and relearning begins.
        now = card.due
        manager.startReviewIfNeeded()
        try manager.reviewCard(id: card.id, rating: .again)
        #expect(card.state == .relearning && card.lapses == 1 && card.reps == 4)
        #expect(card.due.timeIntervalSince(now) == 600)
    }

    @Test func invalidAndDuplicateRatingsLeaveAllSchedulingFieldsUntouched() throws {
        let s = try TestStore(); let deck = s.deck(); let card = s.card(deck)
        _ = s.config([deck]); try s.context.save()
        let manager = CardManager(modelContext: s.context, clock: { s.now })
        do {
            try manager.reviewCard(id: UUID(), rating: .good)
            Issue.record("An unknown card must throw cardNotFound")
        } catch CardManagerError.cardNotFound { }
        do {
            try manager.reviewCard(id: card.id, rating: .good)
            Issue.record("A card outside the queue must throw reviewCardNotFound")
        } catch CardManagerError.reviewCardNotFound { }
        #expect(ScheduleState(card) == ScheduleState(due: s.now.addingTimeInterval(-60)))
        manager.startReviewIfNeeded()
        try manager.reviewCard(id: card.id, rating: .easy)
        let completed = ScheduleState(card)
        do {
            try manager.reviewCard(id: card.id, rating: .again)
            Issue.record("Double submission must throw reviewCardNotFound")
        } catch CardManagerError.reviewCardNotFound { }
        #expect(ScheduleState(card) == completed)
        #expect(manager.getProgress().completed == 1)
    }

    @Test func quickPracticeNeverChangesAnySchedulingField() throws {
        let s = try TestStore(); let deck = s.deck(); let card = s.card(deck)
        card.state = .review; card.stability = 12.4; card.difficulty = 5.6
        card.elapsedDays = 4; card.scheduledDays = 9; card.learningSteps = 1
        card.reps = 20; card.lapses = 3; card.lastReview = s.now.addingTimeInterval(-86400)
        try s.context.save()
        let before = ScheduleState(card)
        let manager = QuickManager(modelContext: s.context)
        try manager.start(config: PyokoQuickConfig(source: .decks, includeRecall: false, selectedDecks: [deck]))
        manager.markCurrent(.incorrect); manager.reviewIncorrect()
        manager.markCurrent(.correct); manager.reset()
        manager.skipCurrent()
        let saved = try #require(ModelContext(s.container).fetch(FetchDescriptor<PyokoCard>()).first)
        #expect(ScheduleState(saved) == before)
        #expect(try s.context.fetchCount(FetchDescriptor<PyokoReviewCard>()) == 0)
    }
}

/// A value snapshot detects accidental mutations, including easily missed FSRS fields.
struct ScheduleState: Equatable {
    var due: Date
    var stability: Double = 0
    var difficulty: Double = 0
    var elapsedDays: Double = 0
    var scheduledDays: Double = 0
    var learningSteps: Int = 0
    var reps: Int = 0
    var lapses: Int = 0
    var state: CardState = .new
    var lastReview: Date? = nil

    init(due: Date) { self.due = due }
    @MainActor init(_ card: PyokoCard) {
        due = card.due; stability = card.stability; difficulty = card.difficulty
        elapsedDays = card.elapsedDays; scheduledDays = card.scheduledDays
        learningSteps = card.learningSteps; reps = card.reps; lapses = card.lapses
        state = card.state; lastReview = card.lastReview
    }
}
