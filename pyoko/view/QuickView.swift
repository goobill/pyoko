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

    @FocusState private var writingFocused: Bool

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
        .pyokoHideBackButton()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pyokoSurface()
        .task {

            startSession()
        }
        .alert(
            "Quick Review",
            isPresented:
                Binding(
                    get: {

                        errorMessage
                            != nil
                    },
                    set: {

                        if !$0 {

                            errorMessage =
                                nil
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

        StudyLayout {
            topBar
        } card: {
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
                recognitionReadingOnlyEnabled:
                    config
                        .recognitionReadingOnlyEnabled,
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
        } actions: {
            actionArea
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
                .accessibilityIdentifier("quick.exit")

                ProgressView(
                    value:
                        Double(
                            progress
                                .completed
                        ),
                    total:
                        Double(
                            max(
                                progress
                                    .total,
                                1
                            )
                        )
                )
                .accessibilityIdentifier("study.progress")
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
                    alignment:
                        .trailing
                )
                #if os(macOS)
                MacShortcutHelp().fixedSize()
                #endif
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
                .accessibilityIdentifier("quick.score.correct")
                .accessibilityValue("\(progress.correct)")

                Label(
                    "\(progress.incorrect) Incorrect",
                    systemImage:
                        "xmark"
                )
                .accessibilityIdentifier("quick.score.incorrect")
                .accessibilityValue("\(progress.incorrect)")
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
        Button {
            revealAnswer()
        } label: {
            Text("Show Answer")
                .fontWeight(.medium)
                .foregroundStyle(.tint)
                #if os(macOS)
                .padding(.horizontal, 24)
                .frame(height: 44)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                #else
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                #endif
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .macReviewShortcut(.space)
        .accessibilityIdentifier("quick.reveal")
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
            .focused($writingFocused)
            .task(id: currentCard?.id) {
                // Wait for the new field to join the view hierarchy before focusing it.
                await Task.yield()
                guard !Task.isCancelled else { return }
                writingFocused = !answerRevealed
            }
            #if os(macOS)
            .textFieldStyle(.plain)
            .font(.title3)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.15)))
            #else
            .textFieldStyle(.roundedBorder)
            #endif
            .accessibilityIdentifier("quick.answer")

            #if os(iOS)
            .submitLabel(
                .done
            )
            #endif

            .onSubmit {

                submitWriting()
            }
            #if os(macOS)
            // Inset the whole field, while the action row retains the card's width.
            .padding(.horizontal, 32)
            #endif

            WritingButtonsLayout {
                #if os(macOS)
                unsureButton
                checkAnswerButton
                #else
                checkAnswerButton
                unsureButton
                #endif
            }
        }
    }

    private var checkAnswerButton: some View {
        Button(action: submitWriting) {
            Text("Check Answer")
                #if os(macOS)
                .frame(minHeight: 36)
                #endif
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(writingAnswerIsEmpty)
        .accessibilityIdentifier("quick.check")
    }

    private var unsureButton: some View {
        Button(action: revealUnsureAnswer) {
            Text("Unsure — Show Answer")
                #if os(macOS)
                .frame(maxWidth: .infinity, minHeight: 36)
                #endif
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("quick.unsure")
    }

    private var writingPlaceholder:
        String {

        guard let currentCard
        else {

            return
                "Write your answer"
        }

        switch currentCard.type {

        case .recognition:

            if config
                .recognitionReadingOnlyEnabled {

                return
                    "Write the Hiragana"
            }

            return
                "Write the English meaning"

        case .recall:

            return
                "Write the Kanji"
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
                .accessibilityIdentifier("quick.incorrect")
                .macReviewShortcut("3")

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
                .accessibilityIdentifier("quick.correct")
                .macReviewShortcut("4")
            }

            #if os(macOS)
            Button("Next Card") {
                manager?.skipCurrent()
                refresh()
            }
            .macReviewShortcut(.space)
            .accessibilityIdentifier("quick.next")
            #endif
        }
    }

    // MARK: - Complete

    private var completionView: some View {
        #if os(macOS)
        MacCompletionPage(
            title: progress.sessionTotal == 0 ? "No Words Available" : "Quick Review Complete",
            message: completionMessage,
            icon: progress.sessionTotal == 0 ? "rectangle.stack" : "checkmark.circle.fill"
        ) {
            if progress.sessionTotal > 0 { resultSummary }
            else { Text("Choose vocabulary in Quick Review Config.").font(.title3) }
        } actions: {
            if progress.sessionTotal > 0 {
                if progress.incorrect > 0 {
                    MacCompletionButton(title: reviewIncorrectTitle, action: reviewIncorrect)
                        .accessibilityIdentifier("quick.retry")
                }
                MacCompletionButton(title: "Reset Review", action: resetReview)
                    .accessibilityIdentifier("quick.reset")
            }
            MacCompletionButton(title: "Back to Quick Review", action: { dismiss() })
                .accessibilityIdentifier("quick.complete.exit")
        }
        #else
        phoneCompletionView
        #endif
    }

    private var phoneCompletionView: some View {
        VStack(
            spacing: 24
        ) {

            Spacer()

            Image(
                systemName:
                    progress.sessionTotal
                        == 0
                    ? "rectangle.stack"
                    : (
                        progress.incorrect
                            == 0
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
                    progress.sessionTotal
                        == 0
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

            if progress
                .sessionTotal > 0 {

                resultSummary

                VStack(
                    spacing: 12
                ) {

                    if progress
                        .incorrect > 0 {

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
                        .accessibilityIdentifier("quick.retry")
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
                    .accessibilityIdentifier("quick.reset")

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
                    .accessibilityIdentifier("quick.complete.exit")
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

    // MARK: - Result Summary

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
                .accessibilityIdentifier("quick.score.correct")
                .accessibilityValue("\(progress.correct)")
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
                .accessibilityIdentifier("quick.score.incorrect")
                .accessibilityValue("\(progress.incorrect)")
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

        if progress
            .sessionTotal == 0 {

            return
                """
                No vocabulary matched the current Quick Review settings.
                """
        }

        if progress.correct == progress.sessionTotal {

            return
                """
                All \(progress.sessionTotal) cards are now correct.
                """
        }

        if progress.incorrect == 0 {
            return "Session complete. \(progress.correct) of \(progress.sessionTotal) cards marked correct."
        }

        return
            """
            Review the cards you missed, or reset the full session and start again.
            """
    }

    private var reviewIncorrectTitle:
        String {

        if progress
            .incorrect == 1 {

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
            manager
                .currentCard()

        progress =
            manager
                .getProgress()

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

        writingFocused = false
        submittedWritingText =
            trimmed

        hintRevealed =
            false

        answerRevealed =
            true
    }

    // MARK: - Result

    /// Allows an empty response while preserving any attempt; scoring happens after reveal.
    private func revealUnsureAnswer() {
        guard config.writingEnabled, !answerRevealed else { return }
        submittedWritingText = writingText.trimmingCharacters(in: .whitespacesAndNewlines)
        hintRevealed = false
        answerRevealed = true
    }

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

        manager
            .reviewIncorrect()

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
