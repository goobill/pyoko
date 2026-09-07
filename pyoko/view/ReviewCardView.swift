import SwiftUI

struct ReviewCardView: View {

    let card: PyokoCard

    @Binding
    var answerRevealed: Bool

    let beforeAnswerDisplayMode:
        TargetDisplayMode

    let afterAnswerDisplayMode:
        TargetDisplayMode

    let readingHintEnabled:
        Bool

    @State
    private var readingHintRevealed =
        false

    var body: some View {

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
                    24
                )
            }
        }
        .frame(
            maxWidth: .infinity
        )
        .frame(
            minHeight: 360
        )
        .onChange(
            of: card.id
        ) {

            resetHint()
        }
        .onChange(
            of: answerRevealed
        ) {

            if answerRevealed {
                resetHint()
            }
        }
    }

    // MARK: - Background

    private var cardBackground:
        some View {

        RoundedRectangle(
            cornerRadius: 24,
            style: .continuous
        )
        .fill(
            .regularMaterial
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                .quaternary,
                lineWidth: 1
            )
        }
        .contentShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
        .onTapGesture {

            revealAnswer()
        }
    }

    // MARK: - Content

    private var cardContent:
        some View {

        VStack(
            spacing: 22
        ) {

            HStack {

                cardTypeLabel

                Spacer()

                // Space is left here for
                // the Hint button overlay.
            }

            Spacer(
                minLength: 20
            )

            frontContent

            if readingHintRevealed,
               let readingText {

                Text(
                    readingText
                )
                .font(
                    .title3
                )
                .foregroundStyle(
                    .secondary
                )
                .transition(
                    .opacity
                )
            }

            if answerRevealed {

                Divider()
                    .padding(
                        .vertical,
                        4
                    )

                answerContent

            } else {

                Spacer(
                    minLength: 8
                )

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
                minLength: 20
            )
        }
        .padding(
            24
        )
    }

    // MARK: - Card Type

    private var cardTypeLabel:
        some View {

        Group {

            switch card.type {

            case .recognition:

                Label(
                    "Recognition",
                    systemImage:
                        "eye"
                )

            case .recall:

                Label(
                    "Recall",
                    systemImage:
                        "arrow.turn.down.right"
                )
            }
        }
        .font(
            .subheadline
        )
        .foregroundStyle(
            .secondary
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

                readingHintRevealed
                    .toggle()
            }

        } label: {

            Label(
                "Hint",
                systemImage:
                    readingHintRevealed
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
        .help(
            "Show Reading"
        )
    }

    private var shouldShowReadingHint:
        Bool {

        guard
            readingHintEnabled,
            !answerRevealed,
            readingText != nil
        else {
            return false
        }

        if card.type ==
            CardType.recognition,
           beforeAnswerDisplayMode
            .includesReading {

            return false
        }

        return true
    }

    private var readingText:
        String? {

        guard
            let reading =
                card.targetReading?
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    ),
            !reading.isEmpty
        else {

            return nil
        }

        return reading
    }

    // MARK: - Front

    @ViewBuilder
    private var frontContent:
        some View {

        switch card.type {

        case .recognition:

            targetDisplay(
                mode:
                    beforeAnswerDisplayMode
            )

        case .recall:

            Text(
                card.sourceText
            )
            .font(
                .system(
                    size: 30,
                    weight: .medium
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

        switch card.type {

        case .recognition:

            VStack(
                spacing: 14
            ) {

                targetDisplay(
                    mode:
                        afterAnswerDisplayMode
                )

                Text(
                    card.sourceText
                )
                .font(
                    .title3
                )
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
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

            targetTextView(
                card.targetText
            )

        case .reading:

            targetTextView(
                displayReading
            )

        case .targetAndReading:

            VStack(
                spacing: 7
            ) {

                targetTextView(
                    card.targetText
                )

                if displayReading !=
                    card.targetText {

                    Text(
                        displayReading
                    )
                    .font(
                        .title3
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
    }

    private func targetTextView(
        _ text: String
    ) -> some View {

        Text(
            text
        )
        .font(
            .system(
                size: 36,
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

    private var displayReading:
        String {

        readingText ??
            card.targetText
    }

    // MARK: - Actions

    private func revealAnswer() {

        guard
            !answerRevealed
        else {
            return
        }

        withAnimation(
            .easeInOut(
                duration: 0.18
            )
        ) {

            answerRevealed =
                true
        }
    }

    private func resetHint() {

        readingHintRevealed =
            false
    }
}
