//
//  ReviewIntervalFormatter.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

import Foundation

enum ReviewIntervalFormatter {

    static func string(
        from referenceDate: Date,
        to dueDate: Date
    ) -> String {

        let seconds =
            max(
                dueDate.timeIntervalSince(
                    referenceDate
                ),
                0
            )

        if seconds < 60 {
            return "<1m"
        }

        let minutes =
            max(
                Int(
                    round(
                        seconds / 60
                    )
                ),
                1
            )

        if minutes < 60 {
            return "\(minutes)m"
        }

        let hours =
            max(
                Int(
                    round(
                        seconds / 3_600
                    )
                ),
                1
            )

        if hours < 24 {
            return "\(hours)h"
        }

        let days =
            max(
                Int(
                    round(
                        seconds / 86_400
                    )
                ),
                1
            )

        if days < 30 {
            return "\(days)d"
        }

        if days < 365 {

            let months =
                max(
                    Int(
                        round(
                            Double(days) / 30.44
                        )
                    ),
                    1
                )

            return "\(months)mo"
        }

        let years =
            max(
                Int(
                    round(
                        Double(days) / 365.25
                    )
                ),
                1
            )

        return "\(years)y"
    }
}
