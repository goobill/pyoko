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

    let readingOnlyAnswer:
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
                        Text("Tap card to reveal")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !answerRevealed else { return }
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

    // MARK: - Question

    @ViewBuilder
    private var questionContent:
        some View {

        switch card.type {

        case .recognition:

            VStack(
                spacing: 10
            ) {

                if usesReadingOnlyAnswer {

                    // Reading-only Recognition must
                    // hide the reading on the front.
                    primaryText(
                        card.targetText
                    )

                } else {

                    targetContent(
                        mode:
                            beforeAnswerDisplayMode,
                        primary:
                            true
                    )
                }

                if canShowHint && hintRevealed,
                   let reading =
                    card.targetReading {

                    Text(
                        reading
                    )
                    .accessibilityIdentifier("card.hint.text")
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

                if canShowHint && hintRevealed,
                   let reading =
                    card.targetReading {

                    Text(
                        reading
                    )
                    .accessibilityIdentifier("card.hint.text")
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

    // MARK: - Answer

    @ViewBuilder
    private var answerContent:
        some View {

        switch card.type {

        case .recognition:

            if usesReadingOnlyAnswer {

                if let reading =
                    card.targetReading {

                    primaryText(
                        reading
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

    // MARK: - Reading Only

    private var usesReadingOnlyAnswer:
        Bool {

        readingOnlyAnswer
        && card.type == .recognition
        && card.targetReading != nil
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

    private var canShowHint: Bool {
        guard !answerRevealed, readingHintEnabled,
              let reading = card.targetReading?.trimmingCharacters(in: .whitespacesAndNewlines),
              !reading.isEmpty else { return false }
        if card.type == .recognition {
            // Never reveal the answer through a hint, or repeat an already visible reading.
            if usesReadingOnlyAnswer || beforeAnswerDisplayMode.includesReading { return false }
        }
        return true
    }
}
