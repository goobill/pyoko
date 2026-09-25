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

    let onExit:
        () -> Void

    var body: some View {
        #if os(macOS)
        MacCompletionPage(title: title, message: message,
                          icon: status.canExtend ? "arrow.clockwise.circle.fill" : "checkmark.circle.fill") {
            HStack(spacing: 32) {
                completionMetric("Completed", count: progress.completed, icon: "checkmark.circle")
                completionMetric("Due now", count: status.dueNow, icon: "rectangle.stack")
            }
        } actions: {
            if status.canExtend {
                MacCompletionButton(title: continueTitle, action: onContinue)
                    .accessibilityIdentifier("review.extend")
                    .macReviewShortcut(.space)
            }
            MacCompletionButton(title: "Back to Home", action: onExit)
                .accessibilityIdentifier("review.complete.exit")
        }
        #else
        phoneContent
        #endif
    }

    private var phoneContent: some View {
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
                .accessibilityIdentifier("review.extend")
                .macReviewShortcut(.space)

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
            .accessibilityIdentifier("review.complete.exit")

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

    private func completionMetric(_ title: String, count: Int, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(.secondary)
            Text("\(count)").font(.system(size: 32, weight: .semibold)).monospacedDigit()
            Text(title).font(.callout).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("review.complete.metric.\(title)")
        .accessibilityValue("\(count)")
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
            return "No more cards are due right now."
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
