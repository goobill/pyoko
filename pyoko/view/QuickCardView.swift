import SwiftUI

struct QuickCardView: View {

    let card:
        PyokoQuickCard

    let beforeAnswerDisplayMode:
        TargetDisplayMode

    let afterAnswerDisplayMode:
        TargetDisplayMode

    let readingHintEnabled:
        Bool

    let recognitionReadingOnlyEnabled:
        Bool

    let writingEnabled:
        Bool

    let submittedAnswer:
        String

    let answerRevealed:
        Bool

    @Binding
    var hintRevealed:
        Bool

    let onReveal:
        () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.primary.opacity(0.06))
            VStack(spacing: 16) {
                header
                // The hint button sits outside the answer-reveal tap region.
                VStack(spacing: 16) {
                    Spacer()
                    if answerRevealed { answerContent } else { questionContent }
                    Spacer()
                    if !answerRevealed {
                        Text(footerText)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !answerRevealed, !writingEnabled else { return }
                    onReveal()
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 360)
    }

    // MARK: - Header

    private var header:
        some View {

        HStack {

            Label(
                headerTitle,
                systemImage:
                    headerImage
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
                .accessibilityIdentifier("card.hint")
                .accessibilityLabel(hintRevealed ? "Hide Hiragana hint" : "Show Hiragana hint")
                .buttonStyle(
                    .plain
                )
                .foregroundStyle(
                    .tint
                )
            }
        }
    }

    private var headerTitle:
        String {

        let direction =
            card.type == .recognition
            ? "Recognition"
            : "Recall"

        if writingEnabled {

            return
                "\(direction) · Writing"
        }

        return direction
    }

    private var headerImage:
        String {

        if writingEnabled {

            return "pencil"
        }

        return card.type == .recognition
            ? "eye"
            : "arrow.uturn.backward"
    }

    // MARK: - Question

    private var questionContent: some View {
        VStack(spacing: 10) {
            if card.type == .recognition {
                if recognitionReadingOnlyEnabled {
                    primaryText(card.targetText)
                } else {
                    targetContent(mode: beforeAnswerDisplayMode, primary: true)
                }
            } else {
                primaryText(card.sourceText)
            }
            if canShowHint && hintRevealed, let reading = card.targetReading {
                Text(reading.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.title3).foregroundStyle(.secondary)
                    .accessibilityIdentifier("card.hint.text")
            }
        }
    }

    // MARK: - Answer

    @ViewBuilder
    private var answerContent:
        some View {

        if writingEnabled {

            writingAnswerContent

        } else {

            normalAnswerContent
        }
    }

    // MARK: Normal Answer

    @ViewBuilder
    private var normalAnswerContent:
        some View {

        switch card.type {

        case .recognition:

            if recognitionReadingOnlyEnabled {

                VStack(
                    spacing: 18
                ) {

                    Text(
                        card.targetText
                    )
                    .font(
                        .title2
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .multilineTextAlignment(
                        .center
                    )

                    Divider()

                    primaryText(
                        card.targetReading
                        ?? card.targetText
                    )
                }

            } else {

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

    // MARK: Writing Answer

    @ViewBuilder
    private var writingAnswerContent:
        some View {

        switch card.type {

        case .recognition:

            if recognitionReadingOnlyEnabled {

                VStack(
                    spacing: 14
                ) {

                    Text(
                        card.targetText
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

                    Divider()

                    answerSection(
                        title:
                            "Correct answer",
                        text:
                            card.targetReading
                            ?? card.targetText
                    )

                    Divider()

                    answerSection(
                        title:
                            "Your answer",
                        text:
                            submittedAnswer
                    )
                }

            } else {

                VStack(
                    spacing: 14
                ) {

                    targetContent(
                        mode:
                            afterAnswerDisplayMode,
                        primary:
                            false
                    )

                    Divider()

                    answerSection(
                        title:
                            "Correct answer",
                        text:
                            card.sourceText
                    )

                    Divider()

                    answerSection(
                        title:
                            "Your answer",
                        text:
                            submittedAnswer
                    )
                }
            }

        case .recall:

            VStack(
                spacing: 14
            ) {

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

                Divider()

                VStack(
                    spacing: 5
                ) {

                    Text(
                        "Correct answer"
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    targetContent(
                        mode:
                            afterAnswerDisplayMode,
                        primary:
                            false
                    )
                }

                Divider()

                answerSection(
                    title:
                        "Your answer",
                    text:
                        submittedAnswer
                )
            }
        }
    }

    private func answerSection(
        title: String,
        text: String
    ) -> some View {

        VStack(
            spacing: 5
        ) {

            Text(
                title
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )

            Text(
                text
            )
            .font(
                .title3
            )
            .fontWeight(
                .medium
            )
            .multilineTextAlignment(
                .center
            )
            .minimumScaleFactor(
                0.7
            )
            .lineLimit(
                3
            )
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

            if primary {

                primaryText(
                    card.targetText
                )

            } else {

                secondaryAnswerText(
                    card.targetText
                )
            }

        case .reading:

            let text =
                card.targetReading
                ?? card.targetText

            if primary {

                primaryText(
                    text
                )

            } else {

                secondaryAnswerText(
                    text
                )
            }

        case .targetAndReading:

            VStack(
                spacing: 6
            ) {

                if primary {

                    primaryText(
                        card.targetText
                    )

                } else {

                    secondaryAnswerText(
                        card.targetText
                    )
                }

                Text(
                    card.targetReading
                    ?? card.targetText
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

    private func secondaryAnswerText(
        _ text: String
    ) -> some View {

        Text(
            text
        )
        .font(
            .title2
        )
        .fontWeight(
            .medium
        )
        .minimumScaleFactor(
            0.6
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

    // MARK: - Footer

    private var footerText:
        String {

        guard writingEnabled
        else {

            return
                "Tap card to reveal"
        }

        switch card.type {

        case .recognition:

            if recognitionReadingOnlyEnabled {

                return
                    "Write the Hiragana below"
            }

            return
                "Write the English meaning below"

        case .recall:

            return
                "Write the Kanji below"
        }
    }

    // MARK: - Hint

    private var canShowHint: Bool {
        guard !answerRevealed, readingHintEnabled,
              let reading = card.targetReading?.trimmingCharacters(in: .whitespacesAndNewlines),
              !reading.isEmpty else { return false }
        if card.type == .recognition {
            // Never reveal the answer through a hint, or repeat an already visible reading.
            if recognitionReadingOnlyEnabled || beforeAnswerDisplayMode.includesReading { return false }
        }
        return true
    }
}
