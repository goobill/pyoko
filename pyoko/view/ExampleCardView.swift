import SwiftUI

struct ExampleCardView: View {

    let beforeAnswerDisplayMode:
        TargetDisplayMode

    let afterAnswerDisplayMode:
        TargetDisplayMode

    let readingHintEnabled:
        Bool

    let readingOnlyAnswer:
        Bool

    @State
    private var answerRevealed =
        false

    @State
    private var hintRevealed =
        false

    private let source =
        "to eat"

    private let target =
        "食べる"

    private let reading =
        "たべる"

    var body: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(
                Color.primary
                    .opacity(
                        0.06
                    )
            )

            VStack(
                spacing: 14
            ) {

                HStack {

                    Label(
                        "Recognition",
                        systemImage:
                            "eye"
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

                Spacer()

                if answerRevealed {

                    answerContent

                } else {

                    questionContent
                }

                Spacer()

                Text(
                    answerRevealed
                    ? "Tap to reset"
                    : "Tap to reveal"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .padding(
                20
            )
        }
        .frame(
            height: 250
        )
        .contentShape(
            Rectangle()
        )
        .onTapGesture {

            if answerRevealed {

                answerRevealed =
                    false

                hintRevealed =
                    false

            } else {

                answerRevealed =
                    true

                hintRevealed =
                    false
            }
        }
    }

    @ViewBuilder
    private var questionContent:
        some View {

        if readingOnlyAnswer {

            mainText(
                target
            )

        } else {

            targetContent(
                beforeAnswerDisplayMode
            )
        }

        if hintRevealed {

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

    @ViewBuilder
    private var answerContent:
        some View {

        if readingOnlyAnswer {

            mainText(
                reading
            )

        } else {

            VStack(
                spacing: 14
            ) {

                targetContent(
                    afterAnswerDisplayMode
                )

                Divider()

                Text(
                    source
                )
                .font(
                    .title3
                )
            }
        }
    }

    @ViewBuilder
    private func targetContent(
        _ mode:
            TargetDisplayMode
    ) -> some View {

        switch mode {

        case .target:

            mainText(
                target
            )

        case .reading:

            mainText(
                reading
            )

        case .targetAndReading:

            VStack(
                spacing: 5
            ) {

                mainText(
                    target
                )

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

    private func mainText(
        _ text: String
    ) -> some View {

        Text(
            text
        )
        .font(
            .system(
                size: 32,
                weight: .semibold
            )
        )
        .minimumScaleFactor(
            0.5
        )
        .lineLimit(
            2
        )
        .multilineTextAlignment(
            .center
        )
    }

    private var canShowHint:
        Bool {

        readingHintEnabled
        && !answerRevealed
        && !readingOnlyAnswer
        && !beforeAnswerDisplayMode
            .includesReading
    }
}
