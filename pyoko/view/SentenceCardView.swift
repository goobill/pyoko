//
//  SentenceCardView.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

import SwiftUI

struct SentenceCardView: View {

    let sentence:
        PyokoSentence

    let direction:
        CardType

    let display:
        SentenceDisplay

    let isRevealed:
        Bool

    @Binding
    var userAnswer:
        String

    let onReveal:
        () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            header

            question

            Divider()

            answerInput

            if isRevealed {

                Divider()

                expectedAnswer

                alternatives
            }

            if !isRevealed {

                showAnswerButton
            }
        }
        .padding(
            20
        )
        .frame(
            maxWidth:
                .infinity,
            alignment:
                .leading
        )
        .background {

            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(
                .regularMaterial
            )
        }
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
    }

    // MARK: - Header

    private var header:
        some View {

        HStack {

            Label(
                direction ==
                    .recognition
                ? "Recognition"
                : "Recall",
                systemImage:
                    direction ==
                        .recognition
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
        }
    }

    // MARK: - Question

    @ViewBuilder
    private var question:
        some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(
                "Translate"
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )

            if direction ==
                .recognition {

                japaneseText(
                    japanese:
                        sentence.japanese,
                    hiragana:
                        sentence.hiragana,
                    prominent:
                        true
                )

            } else {

                Text(
                    sentence.english
                )
                .font(
                    .title2
                )
                .fontWeight(
                    .medium
                )
                .textSelection(
                    .enabled
                )
            }
        }
        .frame(
            maxWidth:
                .infinity,
            alignment:
                .leading
        )
    }

    // MARK: - User Answer

    private var answerInput:
        some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(
                "Your Answer"
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )

            TextEditor(
                text:
                    $userAnswer
            )
            .scrollContentBackground(
                .hidden
            )
            .frame(
                minHeight: 90
            )
            .padding(
                8
            )
            .background {

                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(
                    Color.primary
                        .opacity(
                            0.04
                        )
                )
            }
            .overlay {

                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .stroke(
                    .quaternary,
                    lineWidth: 1
                )
            }
            .disabled(
                isRevealed
            )
        }
    }

    // MARK: - Expected Answer

    private var expectedAnswer:
        some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(
                "Answer"
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )

            if direction ==
                .recognition {

                Text(
                    sentence.english
                )
                .font(
                    .title3
                )
                .fontWeight(
                    .semibold
                )
                .textSelection(
                    .enabled
                )

            } else {

                japaneseText(
                    japanese:
                        sentence.japanese,
                    hiragana:
                        sentence.hiragana,
                    prominent:
                        false
                )
            }
        }
    }

    // MARK: - Alternatives

    @ViewBuilder
    private var alternatives:
        some View {

        if direction ==
            .recognition {

            if !sentence
                .alternativeEnglish
                .isEmpty {

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Text(
                        "Other Possible Answers"
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    ForEach(
                        Array(
                            sentence
                                .alternativeEnglish
                                .enumerated()
                        ),
                        id: \.offset
                    ) { _, answer in

                        alternativeRow {

                            Text(
                                answer
                            )
                        }
                    }
                }
            }

        } else {

            if !sentence
                .alternativeJapanese
                .isEmpty {

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Text(
                        "Other Possible Answers"
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    ForEach(
                        Array(
                            sentence
                                .alternativeJapanese
                                .enumerated()
                        ),
                        id: \.offset
                    ) { _, answer in

                        alternativeRow {

                            japaneseText(
                                japanese:
                                    answer.japanese,
                                hiragana:
                                    answer.hiragana,
                                prominent:
                                    false
                            )
                        }
                    }
                }
            }
        }
    }

    private func alternativeRow<
        Content: View
    >(
        @ViewBuilder content:
            () -> Content
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 10
        ) {

            Image(
                systemName:
                    "checkmark.circle"
            )
            .foregroundStyle(
                .secondary
            )
            .padding(
                .top,
                2
            )

            content()
        }
        .frame(
            maxWidth:
                .infinity,
            alignment:
                .leading
        )
    }

    // MARK: - Japanese Display

    @ViewBuilder
    private func japaneseText(
        japanese:
            String,
        hiragana:
            String,
        prominent:
            Bool
    ) -> some View {

        switch display {

        case .kanji:

            Text(
                japanese
            )
            .font(
                prominent
                ? .title2
                : .title3
            )
            .fontWeight(
                prominent
                ? .medium
                : .semibold
            )
            .textSelection(
                .enabled
            )

        case .hiragana:

            Text(
                hiragana
            )
            .font(
                prominent
                ? .title2
                : .title3
            )
            .fontWeight(
                prominent
                ? .medium
                : .semibold
            )
            .textSelection(
                .enabled
            )

        case .both:

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(
                    japanese
                )
                .font(
                    prominent
                    ? .title2
                    : .title3
                )
                .fontWeight(
                    prominent
                    ? .medium
                    : .semibold
                )

                Text(
                    hiragana
                )
                .font(
                    prominent
                    ? .body
                    : .callout
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .textSelection(
                .enabled
            )
        }
    }

    // MARK: - Reveal

    private var showAnswerButton:
        some View {

        Button {

            onReveal()

        } label: {

            Text(
                "Show Answer"
            )
            .fontWeight(
                .semibold
            )
            .foregroundStyle(
                .tint
            )
            .frame(
                maxWidth:
                    .infinity
            )
            .padding(
                .vertical,
                8
            )
        }
        .buttonStyle(
            .plain
        )
        .accessibilityHint(
            "Shows the generated answer and alternative answers"
        )
    }
}
