import SwiftUI

struct ReviewCardView: View {

    let card:
        PyokoCard

    let beforeAnswerDisplayMode:
        TargetDisplayMode

    let afterAnswerDisplayMode:
        TargetDisplayMode

    let readingHintEnabled:
        Bool

    let answerRevealed:
        Bool

    @Binding
    var hintRevealed:
        Bool

    let onReveal:
        () -> Void

    var body: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .fill(
                Color.primary
                    .opacity(
                        0.06
                    )
            )

            VStack(
                spacing: 16
            ) {

                header

                Spacer()

                cardContent

                Spacer()

                if !answerRevealed {

                    Text(
                        "Tap card to reveal"
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
            .padding(
                24
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .frame(
            height: 360
        )
        .contentShape(
            Rectangle()
        )
        .onTapGesture {

            if !answerRevealed {

                onReveal()
            }
        }
    }

    // MARK: - Header

    private var header:
        some View {

        HStack {

            Label(
                card.type == .recognition
                ? "Recognition"
                : "Recall",
                systemImage:
                    card.type == .recognition
                    ? "eye"
                    : "arrow.uturn.backward"
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )

            Spacer()

            if canShowHint {

                Button {

                    hintRevealed.toggle()

                } label: {

                    Label(
                        "Hint",
                        systemImage:
                            "lightbulb"
                    )
                    .font(
                        .caption
                    )
                }
                .buttonStyle(
                    .plain
                )
                .foregroundStyle(
                    .tint
                )
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var cardContent:
        some View {

        if answerRevealed {

            answerContent

        } else {

            questionContent
        }
    }

    @ViewBuilder
    private var questionContent:
        some View {

        switch card.type {

        case .recognition:

            VStack(
                spacing: 10
            ) {

                targetContent(
                    mode:
                        beforeAnswerDisplayMode,
                    primary:
                        true
                )

                if hintRevealed,
                   let reading =
                    card.targetReading {

                    Text(
                        reading
                    )
                    .font(
                        .title3
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }

        case .recall:

            VStack(
                spacing: 10
            ) {

                primaryText(
                    card.sourceText
                )

                if hintRevealed,
                   let reading =
                    card.targetReading {

                    Text(
                        reading
                    )
                    .font(
                        .title3
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var answerContent:
        some View {

        switch card.type {

        case .recognition:

            VStack(
                spacing: 18
            ) {

                targetContent(
                    mode:
                        afterAnswerDisplayMode,
                    primary:
                        true
                )

                Divider()

                Text(
                    card.sourceText
                )
                .font(
                    .title2
                )
                .multilineTextAlignment(
                    .center
                )
            }

        case .recall:

            VStack(
                spacing: 18
            ) {

                Text(
                    card.sourceText
                )
                .font(
                    .title2
                )
                .multilineTextAlignment(
                    .center
                )

                Divider()

                targetContent(
                    mode:
                        afterAnswerDisplayMode,
                    primary:
                        true
                )
            }
        }
    }

    // MARK: - Target

    @ViewBuilder
    private func targetContent(
        mode: TargetDisplayMode,
        primary: Bool
    ) -> some View {

        switch mode {

        case .target:

            primaryText(
                card.targetText
            )

        case .reading:

            primaryText(
                card.targetReading
                ?? card.targetText
            )

        case .targetAndReading:

            VStack(
                spacing: 6
            ) {

                primaryText(
                    card.targetText
                )

                Text(
                    card.targetReading
                    ?? card.targetText
                )
                .font(
                    primary
                    ? .title3
                    : .body
                )
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )
            }
        }
    }

    private func primaryText(
        _ text: String
    ) -> some View {

        Text(
            text
        )
        .font(
            .system(
                size: 38,
                weight: .semibold
            )
        )
        .minimumScaleFactor(
            0.45
        )
        .lineLimit(
            3
        )
        .multilineTextAlignment(
            .center
        )
        .frame(
            maxWidth: .infinity
        )
    }

    // MARK: - Hint

    private var canShowHint:
        Bool {

        guard !answerRevealed
        else {
            return false
        }

        guard readingHintEnabled
        else {
            return false
        }

        guard card.targetReading != nil
        else {
            return false
        }

        if card.type == .recognition,
           beforeAnswerDisplayMode
            .includesReading {

            return false
        }

        return true
    }
}
