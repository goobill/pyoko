import SwiftUI

struct ReviewCardView: View {

    let card:
        PyokoCard

    @Binding
    var answerRevealed:
        Bool

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

                hintOverlay
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
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

    // MARK: - Card Content

    private var cardContent:
        some View {

        VStack(
            spacing: 0
        ) {

            cardHeader

            Spacer(
                minLength: 20
            )

            if answerRevealed {

                revealedContent

            } else {

                hiddenContent
            }

            Spacer(
                minLength: 20
            )

            if !answerRevealed {

                Text(
                    "Tap card to reveal"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .tertiary
                )
            }
        }
        .padding(
            24
        )
    }

    // MARK: - Header

    private var cardHeader:
        some View {

        HStack {

            cardTypeLabel

            Spacer()

            // Hint is an interactive overlay,
            // so this content leaves room for it.

            if shouldShowReadingHint {

                Color.clear
                    .frame(
                        width: 72,
                        height: 24
                    )
            }
        }
    }

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

    private var hintOverlay:
        some View {

        VStack {

            HStack {

                Spacer()

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

            Spacer()
        }
        .padding(
            24
        )
    }

    // MARK: - Hidden Content

    private var hiddenContent:
        some View {

        VStack(
            spacing: 16
        ) {

            Spacer(
                minLength: 0
            )

            frontContent

            if readingHintRevealed,
               let readingText {

                Text(
                    readingText
                )
                .font(
                    .system(
                        size: 27,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )
                .transition(
                    .opacity
                )
            }

            Spacer(
                minLength: 0
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    // MARK: - Revealed Content

    private var revealedContent:
        some View {

        VStack(
            spacing: 22
        ) {

            Spacer(
                minLength: 0
            )

            frontContent

            Divider()

            answerContent

            Spacer(
                minLength: 0
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    // MARK: - Front

    @ViewBuilder
    private var frontContent:
        some View {

        switch card.type {

        case .recognition:

            targetDisplay(
                mode:
                    beforeAnswerDisplayMode,
                isPrimary:
                    true
            )

        case .recall:

            primaryText(
                card.sourceText
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
                spacing: 12
            ) {

                targetDisplay(
                    mode:
                        afterAnswerDisplayMode,
                    isPrimary:
                        false
                )

                secondaryAnswerText(
                    card.sourceText
                )
            }

        case .recall:

            targetDisplay(
                mode:
                    afterAnswerDisplayMode,
                isPrimary:
                    false
            )
        }
    }

    // MARK: - Target Display

    @ViewBuilder
    private func targetDisplay(
        mode: TargetDisplayMode,
        isPrimary: Bool
    ) -> some View {

        switch mode {

        case .target:

            if isPrimary {

                primaryText(
                    card.targetText
                )

            } else {

                answerTargetText(
                    card.targetText
                )
            }

        case .reading:

            if isPrimary {

                primaryText(
                    displayReading
                )

            } else {

                answerTargetText(
                    displayReading
                )
            }

        case .targetAndReading:

            VStack(
                spacing: 8
            ) {

                if isPrimary {

                    primaryText(
                        card.targetText
                    )

                } else {

                    answerTargetText(
                        card.targetText
                    )
                }

                if displayReading !=
                    card.targetText {

                    Text(
                        displayReading
                    )
                    .font(
                        .system(
                            size:
                                isPrimary
                                ? 28
                                : 24,
                            weight:
                                .medium
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .multilineTextAlignment(
                        .center
                    )
                    .lineLimit(
                        3
                    )
                    .minimumScaleFactor(
                        0.7
                    )
                }
            }
        }
    }

    // MARK: - Text Styles

    private func primaryText(
        _ text: String
    ) -> some View {

        Text(
            text
        )
        .font(
            .system(
                size: 54,
                weight: .semibold
            )
        )
        .multilineTextAlignment(
            .center
        )
        .lineLimit(
            3
        )
        .minimumScaleFactor(
            0.55
        )
        .frame(
            maxWidth: .infinity
        )
    }

    private func answerTargetText(
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
        .multilineTextAlignment(
            .center
        )
        .lineLimit(
            3
        )
        .minimumScaleFactor(
            0.65
        )
        .frame(
            maxWidth: .infinity
        )
    }

    private func secondaryAnswerText(
        _ text: String
    ) -> some View {

        Text(
            text
        )
        .font(
            .system(
                size: 25,
                weight: .regular
            )
        )
        .foregroundStyle(
            .secondary
        )
        .multilineTextAlignment(
            .center
        )
        .lineLimit(
            3
        )
        .minimumScaleFactor(
            0.7
        )
        .frame(
            maxWidth: .infinity
        )
    }

    // MARK: - Reading

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

    private var displayReading:
        String {

        readingText ??
            card.targetText
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

    // MARK: - Reveal

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

    // MARK: - Reset

    private func resetHint() {

        readingHintRevealed =
            false
    }
}
