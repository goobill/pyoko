import SwiftUI

struct ExampleCardView: View {

    let beforeAnswerDisplayMode:
        TargetDisplayMode

    let afterAnswerDisplayMode:
        TargetDisplayMode

    let readingHintEnabled:
        Bool

    @State
    private var direction:
        ExampleDirection =
            ExampleDirection.recognition

    @State
    private var answerRevealed =
        false

    @State
    private var readingRevealed =
        false

    private let sourceText =
        "to eat"

    private let targetText =
        "食べる"

    private let targetReading =
        "たべる"

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Picker(
                "Example Type",
                selection:
                    $direction
            ) {

                ForEach(
                    ExampleDirection.allCases
                ) { direction in

                    Text(
                        direction.title
                    )
                    .tag(
                        direction
                    )
                }
            }
            .pickerStyle(
                .segmented
            )
            .onChange(
                of: direction
            ) {

                reset()
            }

            VStack(
                spacing: 18
            ) {

                Spacer(
                    minLength: 4
                )

                frontContent

                if answerRevealed {

                    Divider()

                    answerContent

                } else {

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

                Spacer(
                    minLength: 4
                )
            }
            .frame(
                maxWidth: .infinity
            )
            .frame(
                minHeight: 210
            )
            .padding(
                22
            )
            .background(
                .regularMaterial,
                in:
                    RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
            )
            .overlay {

                RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
                .stroke(
                    .quaternary,
                    lineWidth: 1
                )
            }
            .contentShape(
                RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
            )
            .onTapGesture {

                withAnimation(
                    .easeInOut(
                        duration: 0.18
                    )
                ) {

                    answerRevealed =
                        true
                }
            }

            if shouldShowReadingHint {

                Button {

                    readingRevealed =
                        true

                } label: {

                    Label(
                        readingRevealed
                            ? targetReading
                            : "Show Reading",
                        systemImage:
                            "eye"
                    )
                }
                .buttonStyle(
                    .bordered
                )
            }

            if answerRevealed {

                Button(
                    "Reset Example"
                ) {

                    reset()
                }
                .buttonStyle(
                    .borderless
                )
                .font(
                    .caption
                )
            }
        }
    }

    // MARK: - Front

    @ViewBuilder
    private var frontContent:
        some View {

        switch direction {

        case .recognition:

            targetDisplay(
                mode:
                    beforeAnswerDisplayMode
            )

        case .recall:

            Text(
                sourceText
            )
            .font(
                .system(
                    size: 30,
                    weight: .semibold
                )
            )
            .multilineTextAlignment(
                .center
            )
            .frame(
                maxWidth: .infinity
            )
        }
    }

    // MARK: - Answer

    @ViewBuilder
    private var answerContent:
        some View {

        switch direction {

        case .recognition:

            VStack(
                spacing: 12
            ) {

                targetDisplay(
                    mode:
                        afterAnswerDisplayMode
                )

                Text(
                    sourceText
                )
                .font(
                    .title3
                )
                .foregroundStyle(
                    .secondary
                )
            }

        case .recall:

            targetDisplay(
                mode:
                    afterAnswerDisplayMode
            )
        }
    }

    // MARK: - Target Display

    @ViewBuilder
    private func targetDisplay(
        mode: TargetDisplayMode
    ) -> some View {

        switch mode {

        case .target:

            Text(
                targetText
            )
            .font(
                .system(
                    size: 34,
                    weight: .semibold
                )
            )
            .multilineTextAlignment(
                .center
            )
            .frame(
                maxWidth: .infinity
            )

        case .reading:

            Text(
                targetReading
            )
            .font(
                .system(
                    size: 30,
                    weight: .semibold
                )
            )
            .multilineTextAlignment(
                .center
            )
            .frame(
                maxWidth: .infinity
            )

        case .targetAndReading:

            VStack(
                spacing: 6
            ) {

                Text(
                    targetText
                )
                .font(
                    .system(
                        size: 34,
                        weight: .semibold
                    )
                )

                Text(
                    targetReading
                )
                .font(
                    .title3
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .multilineTextAlignment(
                .center
            )
            .frame(
                maxWidth: .infinity
            )
        }
    }

    // MARK: - Reading Hint

    private var shouldShowReadingHint:
        Bool {

        guard
            readingHintEnabled,
            !answerRevealed
        else {
            return false
        }

        if direction ==
            ExampleDirection.recognition,
           beforeAnswerDisplayMode
            .includesReading {

            return false
        }

        return true
    }

    // MARK: - Reset

    private func reset() {

        answerRevealed =
            false

        readingRevealed =
            false
    }
}

// MARK: - Example Direction

private enum ExampleDirection:
    String,
    CaseIterable,
    Identifiable {

    case recognition
    case recall

    var id: Self {
        self
    }

    var title: String {

        switch self {

        case .recognition:
            return "Recognition"

        case .recall:
            return "Recall"
        }
    }
}
