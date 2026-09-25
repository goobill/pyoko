import SwiftUI
import SwiftData
import FSRS

struct ReviewView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    @Query(sort: \PyokoConfig.createdAt)
    private var configs:
        [PyokoConfig]

    @State
    private var currentCard:
        PyokoCard?

    @State
    private var progress =
        ReviewProgress(
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
    private var intervalPreview:
        CardManager.IntervalPreview?

    @State
    private var extensionStatus =
        CardManager
            .ExtensionStatus
            .empty

    @State
    private var errorMessage:
        String?

    var body: some View {

        Group {

            if let currentCard {

                reviewContent(
                    card:
                        currentCard
                )

            } else {

                ReviewCompleteView(
                    progress:
                        progress,
                    status:
                        extensionStatus,
                    onContinue:
                        extendReview,
                    onExit: {
                        dismiss()
                    }
                )
            }
        }
        .pyokoHideBackButton()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pyokoSurface()
        .task {

            loadSession()
        }
        .alert(
            "Review Error",
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
                ?? "An unknown error occurred."
            )
        }
    }

    // MARK: - Review

    private func reviewContent(
        card: PyokoCard
    ) -> some View {

        StudyLayout {
            topBar
        } card: {
            ReviewCardView(
                card:
                    card,
                beforeAnswerDisplayMode:
                    beforeAnswerDisplayMode,
                afterAnswerDisplayMode:
                    afterAnswerDisplayMode,
                readingHintEnabled:
                    readingHintEnabled,
                readingOnlyAnswer:
                    readingOnlyAnswer,
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

            .accessibilityIdentifier("review.exit")

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
                alignment: .trailing
            )
            #if os(macOS)
            MacShortcutHelp().fixedSize()
            #endif
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

            ratingArea

        } else {

            showAnswerArea
        }
    }

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
        .accessibilityIdentifier("review.reveal")
    }

    private var ratingArea:
        some View {

        VStack(
            spacing: 10
        ) {

            Text(
                "How difficult was this card?"
            )
            .font(
                .subheadline
            )
            .fontWeight(
                .medium
            )

            HStack {

                Text(
                    "Harder"
                )

                Spacer()

                Text(
                    "Easier"
                )
            }
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )

            RatingButtonsLayout {

                ratingButton(
                    rating:
                        .again,
                    opacity:
                        0.16
                )

                ratingButton(
                    rating:
                        .hard,
                    opacity:
                        0.16
                )

                ratingButton(
                    rating:
                        .good,
                    opacity:
                        0.16
                )

                ratingButton(
                    rating:
                        .easy,
                    opacity:
                        0.16
                )
            }
        }
    }

    private func ratingButton(
        rating: Rating,
        opacity: Double
    ) -> some View {

        Button {

            submitRating(
                rating
            )

        } label: {

            RatingButtonLabel(title: String(describing: rating).capitalized,
                              interval: intervalText(for: rating))
            .background {

                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(
                    Color.accentColor
                        .opacity(
                            opacity
                        )
                )
            }
        }
        .buttonStyle(
            .plain
        )
        .accessibilityLabel(
            accessibilityLabel(
                for:
                    rating
            )
        )
        .accessibilityIdentifier("review.rating.\(String(describing: rating))")
        .macReviewShortcut(shortcut(for: rating))
    }

    // MARK: - Session

    private func loadSession() {

        let manager =
            CardManager(
                modelContext:
                    modelContext
            )

        manager
            .startReviewIfNeeded()

        loadNextCard()
    }

    private func loadNextCard() {

        let manager =
            CardManager(
                modelContext:
                    modelContext
            )

        progress =
            manager.getProgress()

        currentCard =
            manager.getNextCard()

        answerRevealed =
            false

        hintRevealed =
            false

        intervalPreview =
            nil

        if currentCard == nil {

            refreshCompletion()
        }
    }

    // MARK: - Reveal

    private func revealAnswer() {

        guard !answerRevealed,
              let currentCard
        else {
            return
        }

        answerRevealed =
            true

        hintRevealed =
            false

        do {

            intervalPreview =
                try CardManager(
                    modelContext:
                        modelContext
                )
                .getIntervalPreview(
                    id:
                        currentCard.id
                )

        } catch {

            errorMessage =
                error.localizedDescription
        }
    }

    // MARK: - Rating

    private func shortcut(for rating: Rating) -> KeyEquivalent {
        switch rating {
        case .again: return "1"
        case .hard: return "2"
        case .good: return "3"
        case .easy: return "4"
        default: return "0" // The rating area only creates the four answer buttons.
        }
    }

    private func submitRating(
        _ rating: Rating
    ) {

        guard let currentCard
        else {
            return
        }

        do {

            let manager =
                CardManager(
                    modelContext:
                        modelContext
                )

            try manager.reviewCard(
                id:
                    currentCard.id,
                rating:
                    rating
            )

            loadNextCard()

        } catch {

            errorMessage =
                error.localizedDescription
        }
    }

    // MARK: - Extension

    private func refreshCompletion() {

        let manager =
            CardManager(
                modelContext:
                    modelContext
            )

        progress =
            manager.getProgress()

        do {

            extensionStatus =
                try manager
                    .getReviewExtensionStatus()

        } catch {

            extensionStatus =
                .empty

            errorMessage =
                error.localizedDescription
        }
    }

    private func extendReview() {

        do {

            let manager =
                CardManager(
                    modelContext:
                        modelContext
                )

            let added =
                try manager
                    .extendReviewSession()

            if added == 0 {

                refreshCompletion()

                return
            }

            extensionStatus =
                .empty

            loadNextCard()

        } catch {

            errorMessage =
                error.localizedDescription
        }
    }

    // MARK: - Config

    private var beforeAnswerDisplayMode:
        TargetDisplayMode {

        configs
            .first?
            .beforeAnswerDisplayMode
        ?? .target
    }

    private var afterAnswerDisplayMode:
        TargetDisplayMode {

        configs
            .first?
            .afterAnswerDisplayMode
        ?? .reading
    }

    private var readingHintEnabled:
        Bool {

        configs
            .first?
            .readingHintEnabled
        ?? true
    }

    private var readingOnlyAnswer:
        Bool {

        configs
            .first?
            .readingOnlyAnswer
        ?? false
    }

    // MARK: - Interval

    private func intervalText(
        for rating: Rating
    ) -> String {

        guard let preview =
            intervalPreview
        else {
            return "—"
        }

        return ReviewIntervalFormatter
            .string(
                from:
                    preview.generatedAt,
                to:
                    preview.dueDate(
                        for:
                            rating
                    )
            )
    }

    private func accessibilityLabel(
        for rating: Rating
    ) -> String {

        let name:
            String

        switch rating {

        case .again:
            name = "Again"

        case .hard:
            name = "Hard"

        case .good:
            name = "Good"

        case .easy:
            name = "Easy"

        case .manual:
            name = "Manual"
        }

        return "\(name), next review \(intervalText(for: rating))"
    }
}
