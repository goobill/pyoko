import Foundation

enum ReviewIntervalFormatter {

    static func string(
        from now: Date,
        to due: Date
    ) -> String {

        let seconds =
            max(
                due.timeIntervalSince(
                    now
                ),
                0
            )

        if seconds < 60 {

            return "<1m"
        }

        let minutes =
            seconds / 60

        if minutes < 60 {

            return
                "\(max(Int(minutes.rounded()), 1))m"
        }

        let hours =
            minutes / 60

        if hours < 24 {

            return
                "\(max(Int(hours.rounded()), 1))h"
        }

        let days =
            hours / 24

        if days < 30 {

            return
                "\(max(Int(days.rounded()), 1))d"
        }

        let months =
            days / 30

        if months < 12 {

            return
                "\(max(Int(months.rounded()), 1))mo"
        }

        let years =
            days / 365

        return
            "\(max(Int(years.rounded()), 1))y"
    }
}
