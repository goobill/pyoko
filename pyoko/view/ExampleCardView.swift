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

            ZStack {

                cardBackground

                cardContent
                    .allowsHitTesting(
                        false
                    )

                if shouldShowReadingHint {

                    VStack {

                        HStack {

                            Spacer()

                            hintButton
                        }

                        Spacer()
                    }
                    .padding(
                        22
                    )
                }
            }
            .frame(
                maxWidth: .infinity
            )
            .frame(
                minHeight: 250
            )

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

    // MARK: - Background

    private var cardBackground:
        some View {

        RoundedRectangle(
            cornerRadius: 20,
            style: .continuous
        )
        .fill(
            .regularMaterial
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
    }

    // MARK: - Card

    private var cardContent:
        some View {

        VStack(
            spacing: 18
        ) {

            HStack {

                Label(
                    direction.title,
                    systemImage:
                        direction ==
                            ExampleDirection.recognition
                        ? "eye"
                        : "arrow.turn.down.right"
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .secondary
                )

                Spacer()
            }

            Spacer(
                minLength: 4
            )

            frontContent

            if readingRevealed,
               !answerRevealed {

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
        .padding(
            22
        )
    }

    // MARK: - Hint

    private var hintButton:
        some View {

        Button {

            withAnimation(
                .easeInOut(
                    duration: 0.15
                )
            ) {

                readingRevealed
                    .toggle()
            }

        } label: {

            Label(
                "Hint",
                systemImage:
                    readingRevealed
                    ? "lightbulb.fill"
                    : "lightbulb"
            )
            .font(
                .subheadline
            )
        }
        .buttonStyle(
            .plain
        )
        .foregroundStyle(
            .secondary
        )
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

    // MARK: - Target

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

// MARK: - Direction

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
