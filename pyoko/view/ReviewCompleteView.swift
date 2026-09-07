//
//  ReviewCompleteView.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

import SwiftUI

struct ReviewCompleteView: View {

    let progress:
        ReviewProgress

    let status:
        CardManager.ExtensionStatus

    let onContinue:
        () -> Void

    let onCheckAgain:
        () -> Void

    let onExit:
        () -> Void

    var body: some View {

        VStack(
            spacing: 24
        ) {

            Spacer()

            Image(
                systemName:
                    status.canExtend
                    ? "arrow.clockwise.circle.fill"
                    : "checkmark.circle.fill"
            )
            .font(
                .system(
                    size: 56
                )
            )
            .foregroundStyle(
                .tint
            )

            VStack(
                spacing: 8
            ) {

                Text(
                    title
                )
                .font(
                    .title2
                )
                .fontWeight(
                    .semibold
                )

                Text(
                    message
                )
                .multilineTextAlignment(
                    .center
                )
                .foregroundStyle(
                    .secondary
                )
            }

            if status.canExtend {

                Button {

                    onContinue()

                } label: {

                    Text(
                        continueTitle
                    )
                    .frame(
                        maxWidth:
                            .infinity
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )

            } else if status.laterToday > 0 {

                Button {

                    onCheckAgain()

                } label: {

                    Text(
                        "Check Again"
                    )
                    .frame(
                        maxWidth:
                            .infinity
                    )
                }
                .buttonStyle(
                    .bordered
                )
            }

            Button {

                onExit()

            } label: {

                Text(
                    "Back to Home"
                )
                .frame(
                    maxWidth:
                        .infinity
                )
            }
            .buttonStyle(
                .bordered
            )

            Spacer()
        }
        .padding(
            24
        )
        .frame(
            maxWidth: 440
        )
        .frame(
            maxWidth: .infinity
        )
    }

    private var title: String {

        if progress.total == 0 {

            return "Nothing Due"
        }

        if status.canExtend {

            return "Review Complete"
        }

        if status.laterToday > 0 {

            return "Caught Up for Now"
        }

        return "All Caught Up"
    }

    private var message: String {

        if status.canExtend {

            let cardWord =
                status.dueNow == 1
                ? "card is"
                : "cards are"

            return
                """
                You completed \(progress.completed) cards.

                \(status.dueNow) more \(cardWord) due now. Would you like to continue reviewing?
                """
        }

        if status.laterToday > 0 {

            let cardWord =
                status.laterToday == 1
                ? "card is"
                : "cards are"

            return
                """
                No more cards are due right now.

                \(status.laterToday) \(cardWord) scheduled later today.
                """
        }

        if progress.total == 0 {

            return
                "You have no cards due right now."
        }

        return
            """
            You completed \(progress.completed) cards.

            No more cards are due today.
            """
    }

    private var continueTitle: String {

        if status.nextBatchCount == 1 {

            return "Review 1 More Card"
        }

        return
            "Review \(status.nextBatchCount) More Cards"
    }
}
