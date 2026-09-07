import SwiftUI
import SwiftData

struct QuickView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    let config:
        PyokoQuickConfig

    @State
    private var manager:
        QuickManager?

    @State
    private var currentCard:
        PyokoQuickCard?

    @State
    private var progress =
        QuickProgress(
            completed: 0,
            total: 0,
            sessionTotal: 0,
            correct: 0,
            incorrect: 0
        )

    @State
    private var answerRevealed =
        false

    @State
    private var hintRevealed =
        false

    @State
    private var writingText =
        ""

    @State
    private var submittedWritingText =
        ""

    @State
    private var isLoading =
        true

    @State
    private var errorMessage:
        String?

    var body: some View {

        Group {

            if isLoading {

                ProgressView(
                    "Preparing Quick Review..."
                )

            } else if let currentCard {

                reviewContent(
                    currentCard
                )

            } else {

                completionView
            }
        }
        .navigationBarBackButtonHidden(
            true
        )
        .task {

            startSession()
        }
        .alert(
            "Quick Review",
            isPresented:
                Binding(
                    get: {
                        errorMessage != nil
                    },
                    set: {
                        if !$0 {
                            errorMessage = nil
                        }
                    }
                )
        ) {

            Button(
                "OK",
                role: .cancel
            ) {}

        } message: {

            Text(
                errorMessage
                ?? ""
            )
        }
    }

    // MARK: - Review

    private func reviewContent(
        _ card:
            PyokoQuickCard
    ) -> some View {

        VStack(
            spacing: 0
        ) {

            topBar

            Spacer(
                minLength: 16
            )

            QuickCardView(
                card:
                    card,
                beforeAnswerDisplayMode:
                    config
                        .beforeAnswerDisplayMode,
                afterAnswerDisplayMode:
                    config
                        .afterAnswerDisplayMode,
                readingHintEnabled:
                    config
                        .readingHintEnabled,
                writingEnabled:
                    config
                        .writingEnabled,
                submittedAnswer:
                    submittedWritingText,
                answerRevealed:
                    answerRevealed,
                hintRevealed:
                    $hintRevealed,
                onReveal:
                    revealAnswer
            )
            .padding(
                .horizontal,
                20
            )

            Spacer(
                minLength: 12
            )

            actionArea
                .frame(
                    height: 142
                )
                .padding(
                    .horizontal,
                    20
                )

            Spacer(
                minLength: 16
            )
        }
    }

    // MARK: - Top Bar

    private var topBar:
        some View {

        VStack(
            spacing: 7
        ) {

            HStack(
                spacing: 12
            ) {

                Button {

                    dismiss()

                } label: {

                    Image(
                        systemName:
                            "chevron.left"
                    )
                    .font(
                        .headline
                    )
                    .frame(
                        width: 36,
                        height: 36
                    )
                }
                .buttonStyle(
                    .plain
                )

                ProgressView(
                    value:
                        Double(
                            progress.completed
                        ),
                    total:
                        Double(
                            max(
                                progress.total,
                                1
                            )
                        )
                )
                .tint(
                    .accentColor
                )

                Text(
                    "\(progress.completed)/\(progress.total)"
                )
                .font(
                    .caption
                )
                .monospacedDigit()
                .foregroundStyle(
                    .secondary
                )
                .frame(
                    minWidth: 42,
                    alignment: .trailing
                )
            }

            HStack(
                spacing: 18
            ) {

                Spacer(
                    minLength: 48
                )

                Label(
                    "\(progress.correct) Correct",
                    systemImage:
                        "checkmark"
                )

                Label(
                    "\(progress.incorrect) Incorrect",
                    systemImage:
                        "xmark"
                )
            }
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
        }
        .padding(
            .horizontal,
            16
        )
        .padding(
            .top,
            8
        )
    }

    // MARK: - Action Area

    @ViewBuilder
    private var actionArea:
        some View {

        if answerRevealed {

            resultArea

        } else if config
            .writingEnabled {

            writingArea

        } else {

            showAnswerArea
        }
    }

    // MARK: - Show Answer

    private var showAnswerArea:
        some View {

        ZStack {

            Rectangle()
                .fill(
                    .clear
                )

            Text(
                "Show Answer"
            )
            .fontWeight(
                .medium
            )
            .foregroundStyle(
                .tint
            )
        }
        .contentShape(
            Rectangle()
        )
        .onTapGesture {

            revealAnswer()
        }
    }

    // MARK: - Writing

    private var writingArea:
        some View {

        VStack(
            spacing: 12
        ) {

            TextField(
                writingPlaceholder,
                text:
                    $writingText
            )
            .textFieldStyle(
                .roundedBorder
            )
            .submitLabel(
                .done
            )
            .onSubmit {

                submitWriting()
            }

            Button {

                submitWriting()

            } label: {

                Text(
                    "Check Answer"
                )
                .frame(
                    maxWidth:
                        .infinity
                )
            }
            .buttonStyle(
                .borderedProminent
            )
            .disabled(
                writingAnswerIsEmpty
            )
        }
    }

    private var writingPlaceholder:
        String {

        guard let currentCard
        else {
            return "Write your answer"
        }

        switch currentCard.type {

        case .recognition:

            return
                "Write the source meaning"

        case .recall:

            return
                "Write the target word"
        }
    }

    // MARK: - Correct / Incorrect

    private var resultArea:
        some View {

        VStack(
            spacing: 12
        ) {

            Text(
                "How did you do?"
            )
            .font(
                .subheadline
            )
            .fontWeight(
                .medium
            )

            HStack(
                spacing: 12
            ) {

                Button {

                    submitResult(
                        .incorrect
                    )

                } label: {

                    Label(
                        "Incorrect",
                        systemImage:
                            "xmark"
                    )
                    .frame(
                        maxWidth:
                            .infinity
                    )
                    .frame(
                        height: 48
                    )
                }
                .buttonStyle(
                    .bordered
                )

                Button {

                    submitResult(
                        .correct
                    )

                } label: {

                    Label(
                        "Correct",
                        systemImage:
                            "checkmark"
                    )
                    .frame(
                        maxWidth:
                            .infinity
                    )
                    .frame(
                        height: 48
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )
            }
        }
    }

    // MARK: - Complete

    private var completionView:
        some View {

        VStack(
            spacing: 24
        ) {

            Spacer()

            Image(
                systemName:
                    progress.sessionTotal == 0
                    ? "rectangle.stack"
                    : (
                        progress.incorrect == 0
                        ? "checkmark.circle.fill"
                        : "checkmark.circle"
                    )
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
                    progress.sessionTotal == 0
                    ? "No Words Available"
                    : "Quick Review Complete"
                )
                .font(
                    .title2
                )
                .fontWeight(
                    .semibold
                )

                Text(
                    completionMessage
                )
                .multilineTextAlignment(
                    .center
                )
                .foregroundStyle(
                    .secondary
                )
            }

            if progress.sessionTotal > 0 {

                resultSummary

                VStack(
                    spacing: 12
                ) {

                    if progress.incorrect > 0 {

                        Button {

                            reviewIncorrect()

                        } label: {

                            Text(
                                reviewIncorrectTitle
                            )
                            .frame(
                                maxWidth:
                                    .infinity
                            )
                        }
                        .buttonStyle(
                            .borderedProminent
                        )
                    }

                    Button {

                        resetReview()

                    } label: {

                        Text(
                            "Reset Review"
                        )
                        .frame(
                            maxWidth:
                                .infinity
                        )
                    }
                    .buttonStyle(
                        .bordered
                    )

                    Button {

                        dismiss()

                    } label: {

                        Text(
                            "Back to Quick Review"
                        )
                        .frame(
                            maxWidth:
                                .infinity
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                }
                .frame(
                    maxWidth: 360
                )

            } else {

                Button {

                    dismiss()

                } label: {

                    Text(
                        "Back to Quick Review"
                    )
                    .frame(
                        maxWidth:
                            .infinity
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )
                .frame(
                    maxWidth: 360
                )
            }

            Spacer()
        }
        .padding(
            24
        )
    }

    private var resultSummary:
        some View {

        HStack(
            spacing: 32
        ) {

            VStack(
                spacing: 5
            ) {

                Image(
                    systemName:
                        "checkmark.circle"
                )
                .font(
                    .title2
                )

                Text(
                    "\(progress.correct)"
                )
                .font(
                    .title2
                )
                .fontWeight(
                    .semibold
                )
                .monospacedDigit()

                Text(
                    "Correct"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }

            VStack(
                spacing: 5
            ) {

                Image(
                    systemName:
                        "xmark.circle"
                )
                .font(
                    .title2
                )

                Text(
                    "\(progress.incorrect)"
                )
                .font(
                    .title2
                )
                .fontWeight(
                    .semibold
                )
                .monospacedDigit()

                Text(
                    "Incorrect"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }

    private var completionMessage:
        String {

        if progress.sessionTotal == 0 {

            return
                """
                No vocabulary matched the current Quick Review settings.
                """
        }

        if progress.incorrect == 0 {

            return
                """
                All \(progress.sessionTotal) cards are now correct.
                """
        }

        return
            """
            Review the cards you missed, or reset the full session and start again.
            """
    }

    private var reviewIncorrectTitle:
        String {

        if progress.incorrect == 1 {

            return
                "Review 1 Incorrect Card"
        }

        return
            "Review \(progress.incorrect) Incorrect Cards"
    }

    // MARK: - Session

    private func startSession() {

        guard manager == nil
        else {
            return
        }

        do {

            let newManager =
                QuickManager(
                    modelContext:
                        modelContext
                )

            try newManager.start(
                config:
                    config
            )

            manager =
                newManager

            refresh()

            isLoading =
                false

        } catch {

            errorMessage =
                error.localizedDescription

            isLoading =
                false
        }
    }

    private func refresh() {

        guard let manager
        else {
            return
        }

        currentCard =
            manager.currentCard()

        progress =
            manager.getProgress()

        answerRevealed =
            false

        hintRevealed =
            false

        writingText =
            ""

        submittedWritingText =
            ""
    }

    // MARK: - Reveal

    private func revealAnswer() {

        guard !config
            .writingEnabled
        else {
            return
        }

        guard !answerRevealed
        else {
            return
        }

        hintRevealed =
            false

        answerRevealed =
            true
    }

    // MARK: - Writing

    private var writingAnswerIsEmpty:
        Bool {

        writingText
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty
    }

    private func submitWriting() {

        guard config
            .writingEnabled
        else {
            return
        }

        let trimmed =
            writingText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        guard !trimmed.isEmpty
        else {
            return
        }

        submittedWritingText =
            trimmed

        hintRevealed =
            false

        answerRevealed =
            true
    }

    // MARK: - Result

    private func submitResult(
        _ result:
            QuickAnswerResult
    ) {

        guard answerRevealed
        else {
            return
        }

        guard let manager
        else {
            return
        }

        manager.markCurrent(
            result
        )

        refresh()
    }

    // MARK: - Incorrect Review

    private func reviewIncorrect() {

        guard let manager
        else {
            return
        }

        manager.reviewIncorrect()

        refresh()
    }

    // MARK: - Reset

    private func resetReview() {

        guard let manager
        else {
            return
        }

        manager.reset()

        refresh()
    }
}
