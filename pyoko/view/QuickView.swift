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
            total: 0
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

            nextArea

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

    // MARK: - Next

    private var nextArea:
        some View {

        ZStack {

            Rectangle()
                .fill(
                    .clear
                )

            Text(
                "Next Card"
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

            nextCard()
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
                    progress.total == 0
                    ? "rectangle.stack"
                    : "checkmark.circle.fill"
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
                    progress.total == 0
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

            Spacer()
        }
        .padding(
            24
        )
    }

    private var completionMessage:
        String {

        if progress.total == 0 {

            return
                """
                No vocabulary matched the current Quick Review settings.
                """
        }

        return
            """
            You reviewed \(progress.completed) cards.

            Your FSRS scheduling was not changed.
            """
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

    // MARK: - Next

    private func nextCard() {

        guard answerRevealed
        else {
            return
        }

        guard let manager
        else {
            return
        }

        manager.next()

        refresh()
    }
}
