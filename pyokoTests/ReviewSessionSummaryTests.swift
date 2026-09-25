import Foundation
import Testing
@testable import pyoko

@MainActor
struct ReviewSessionSummaryTests {
    @Test func countsSavedQueueWithoutChangingIt() throws {
        let store = try TestStore()
        let deck = store.deck()
        let card = store.card(deck)
        let done = PyokoReviewCard(reviewDate: store.now, reviewed: true, card: card)
        let pending = PyokoReviewCard(reviewDate: store.now, card: card)
        let summary = ReviewSessionSummary(reviews: [done, pending], now: store.now)
        #expect(summary.completed == 1)
        #expect(summary.remaining == 1)
        #expect(summary.actionTitle == "Resume Review")
        #expect(done.reviewed && !pending.reviewed)
        pending.reviewed = true
        let completed = ReviewSessionSummary(reviews: [done, pending], now: store.now)
        #expect(completed.remaining == 0)
        #expect(completed.actionTitle == "Open Review")
    }

    @Test func excludesOtherDaysAndDeletedCards() throws {
        let store = try TestStore()
        let card = store.card(store.deck())
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.startOfDay(for: store.now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: start)!
        let rows = [
            PyokoReviewCard(reviewDate: start.addingTimeInterval(-1), reviewed: true, card: card),
            PyokoReviewCard(reviewDate: tomorrow, card: card),
            PyokoReviewCard(reviewDate: store.now, card: nil)
        ]
        let empty = ReviewSessionSummary(reviews: rows, now: store.now, calendar: calendar)
        #expect(empty.total == 0)
        #expect(empty.actionTitle == "Start Review")
        let midnight = PyokoReviewCard(reviewDate: start, card: card)
        #expect(ReviewSessionSummary(reviews: rows + [midnight], now: store.now, calendar: calendar).remaining == 1)
    }
}
