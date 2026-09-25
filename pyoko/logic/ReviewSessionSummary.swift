import Foundation

/// Read-only summary of today's persisted queue. Opening the landing page never starts a session.
struct ReviewSessionSummary {
    let completed: Int
    let remaining: Int
    var total: Int { completed + remaining }
    var actionTitle: String {
        remaining > 0 ? "Resume Review" : (total > 0 ? "Open Review" : "Start Review")
    }

    @MainActor
    init(reviews: [PyokoReviewCard], now: Date, calendar: Calendar = .current) {
        let today = reviews.filter { $0.card != nil && calendar.isDate($0.reviewDate, inSameDayAs: now) }
        completed = today.filter(\.reviewed).count
        remaining = today.count - completed
    }
}
