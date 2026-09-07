import SwiftUI
import SwiftData
import FSRS

struct ReviewView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.colorScheme)
    private var colorScheme

    @Query
    private var configurations:
        [PyokoConfiguration]

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
    private var ratingPreviews:
        RatingPreviews?

    @State
    private var showingError =
        false

    @State
    private var errorMessage =
        ""

    var body: some View {

        GeometryReader { geometry in

            VStack(
                spacing: 0
            ) {

                topBar

                Spacer(
                    minLength: 18
                )

                reviewContent(
                    cardHeight:
                        cardHeight(
                            availableHeight:
                                geometry.size.height
                        )
                )

                Spacer(
                    minLength: 12
                )

                actionArea
                    .frame(
                        height: 142
                    )
            }
            .frame(
                maxWidth: 720
            )
            .frame(
                maxWidth: .infinity
            )
            .padding(
                .horizontal,
                20
            )
            .padding(
                .top,
                8
            )
            .padding(
                .bottom,
                8
            )
        }
        .onAppear {

            loadReviewState()
        }
        .onChange(
            of: answerRevealed
        ) {

            if answerRevealed {

                loadRatingPreviews()

            } else {

                ratingPreviews =
                    nil
            }
        }
        .alert(
            "Review Error",
            isPresented:
                $showingError
        ) {

            Button(
                "OK"
            ) {}

        } message: {

            Text(
                errorMessage
            )
        }
        .pyokoReviewNavigationStyle()
    }

    // MARK: - Top Bar

    private var topBar:
        some View {

        HStack(
            spacing: 14
        ) {

            Button {

                dismiss()

            } label: {

                Image(
                    systemName:
                        "chevron.left"
                )
                .font(
                    .system(
                        size: 19,
                        weight: .semibold
                    )
                )
                .frame(
                    width: 44,
                    height: 44
                )
                .background(
                    .regularMaterial,
                    in:
                        Circle()
                )
                .overlay {

                    Circle()
                        .stroke(
                            .quaternary,
                            lineWidth: 1
                        )
                }
            }
            .buttonStyle(
                .plain
            )
            .accessibilityLabel(
                "Go Back"
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
            .frame(
                maxWidth: .infinity
            )

            Text(
                "\(progress.completed)/\(progress.total)"
            )
            .font(
                .subheadline
            )
            .foregroundStyle(
                .secondary
            )
            .monospacedDigit()
            .fixedSize()
        }
    }

    // MARK: - Card

    @ViewBuilder
    private func reviewContent(
        cardHeight: CGFloat
    ) -> some View {

        if let currentCard {

            ReviewCardView(
                card:
                    currentCard,
                answerRevealed:
                    $answerRevealed,
                beforeAnswerDisplayMode:
                    beforeAnswerDisplayMode,
                afterAnswerDisplayMode:
                    afterAnswerDisplayMode,
                readingHintEnabled:
                    readingHintEnabled
            )
            .frame(
                height: cardHeight
            )

        } else if
            progress.total > 0 &&
            progress.remaining == 0 {

            reviewCompleteView
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

        } else {

            noCardsView
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
        }
    }

    // MARK: - Action Area

    @ViewBuilder
    private var actionArea:
        some View {

        if currentCard != nil {

            if answerRevealed {

                ratingControls

            } else {

                showAnswerArea
            }

        } else {

            Color.clear
        }
    }

    // MARK: - Show Answer

    private var showAnswerArea:
        some View {

        Button {

            revealAnswer()

        } label: {

            VStack(
                spacing: 0
            ) {

                Spacer()

                Text(
                    "Show Answer"
                )
                .font(
                    .headline
                )
                .foregroundStyle(
                    .tint
                )

                Spacer()
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(
            .plain
        )
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .contentShape(
            Rectangle()
        )
        .accessibilityLabel(
            "Show Answer"
        )
        .accessibilityHint(
            "Reveals the answer to the current card"
        )
    }

    // MARK: - Rating Controls

    private var ratingControls:
        some View {

        VStack(
            spacing: 10
        ) {

            Text(
                "How difficult was this card?"
            )
            .font(
                .subheadline
                    .weight(
                        .semibold
                    )
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

            HStack(
                spacing: 8
            ) {

                ratingButton(
                    rating:
                        Rating.again,
                    position:
                        0
                )

                ratingButton(
                    rating:
                        Rating.hard,
                    position:
                        1
                )

                ratingButton(
                    rating:
                        Rating.good,
                    position:
                        2
                )

                ratingButton(
                    rating:
                        Rating.easy,
                    position:
                        3
                )
            }
        }
    }

    // MARK: - Rating Button

    private func ratingButton(
        rating: Rating,
        position: Int
    ) -> some View {

        let interval =
            intervalText(
                for: rating
            )

        return Button {

            submitReview(
                rating
            )

        } label: {

            Text(
                interval
            )
            .font(
                .system(
                    size: 17,
                    weight: .semibold,
                    design: .rounded
                )
            )
            .monospacedDigit()
            .lineLimit(
                1
            )
            .minimumScaleFactor(
                0.75
            )
            .frame(
                maxWidth: .infinity
            )
            .frame(
                height: 58
            )
            .background(
                ratingBackground(
                    position:
                        position
                ),
                in:
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
            )
            .overlay {

                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .stroke(
                    .quaternary,
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(
            .plain
        )
        .accessibilityLabel(
            accessibilityText(
                for:
                    rating,
                interval:
                    interval
            )
        )
    }

    // MARK: - Rating Gradient

    private func ratingBackground(
        position: Int
    ) -> Color {

        let darkModeOpacities = [
            0.24,
            0.34,
            0.46,
            0.60
        ]

        let lightModeOpacities = [
            0.78,
            0.62,
            0.46,
            0.30
        ]

        let safePosition =
            min(
                max(
                    position,
                    0
                ),
                3
            )

        let opacity:
            Double

        switch colorScheme {

        case .dark:

            opacity =
                darkModeOpacities[
                    safePosition
                ]

        default:

            opacity =
                lightModeOpacities[
                    safePosition
                ]
        }

        return Color.accentColor
            .opacity(
                opacity
            )
    }

    // MARK: - Accessibility

    private func accessibilityText(
        for rating: Rating,
        interval: String
    ) -> String {

        let ratingName:
            String

        switch rating {

        case .again:

            ratingName =
                "Again"

        case .hard:

            ratingName =
                "Hard"

        case .good:

            ratingName =
                "Good"

        case .easy:

            ratingName =
                "Easy"

        default:

            ratingName =
                "Review"
        }

        return
            "\(ratingName), next review \(interval)"
    }

    // MARK: - Completion

    private var reviewCompleteView:
        some View {

        VStack(
            spacing: 20
        ) {

            Spacer()

            Image(
                systemName:
                    "checkmark.circle"
            )
            .font(
                .system(
                    size: 46
                )
            )
            .foregroundStyle(
                .secondary
            )

            Text(
                "Review Complete"
            )
            .font(
                .title2
                    .bold()
            )

            Text(
                "You've finished today's review."
            )
            .foregroundStyle(
                .secondary
            )

            Button(
                "Go Home"
            ) {

                dismiss()
            }
            .buttonStyle(
                .borderedProminent
            )

            Spacer()
        }
    }

    private var noCardsView:
        some View {

        VStack(
            spacing: 20
        ) {

            Spacer()

            Image(
                systemName:
                    "checkmark.circle"
            )
            .font(
                .system(
                    size: 46
                )
            )
            .foregroundStyle(
                .secondary
            )

            Text(
                "No Cards Due"
            )
            .font(
                .title2
                    .bold()
            )

            Text(
                "There are no cards available for review right now."
            )
            .multilineTextAlignment(
                .center
            )
            .foregroundStyle(
                .secondary
            )

            Button(
                "Go Home"
            ) {

                dismiss()
            }
            .buttonStyle(
                .bordered
            )

            Spacer()
        }
    }

    // MARK: - Card Height

    private func cardHeight(
        availableHeight: CGFloat
    ) -> CGFloat {

        let proposedHeight =
            availableHeight * 0.60

        return min(
            max(
                proposedHeight,
                320
            ),
            500
        )
    }

    // MARK: - Configuration

    private var configuration:
        PyokoConfiguration? {

        configurations.first
    }

    private var beforeAnswerDisplayMode:
        TargetDisplayMode {

        configuration?
            .beforeAnswerDisplayMode ??
            TargetDisplayMode.target
    }

    private var afterAnswerDisplayMode:
        TargetDisplayMode {

        configuration?
            .afterAnswerDisplayMode ??
            TargetDisplayMode.reading
    }

    private var readingHintEnabled:
        Bool {

        configuration?
            .readingHintEnabled ??
            true
    }

    // MARK: - Reveal

    private func revealAnswer() {

        guard
            currentCard != nil,
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

    // MARK: - Rating Preview

    private func loadRatingPreviews() {

        guard
            let currentCard
        else {

            ratingPreviews =
                nil

            return
        }

        let manager =
            CardManager(
                modelContext:
                    modelContext
            )

        do {

            ratingPreviews =
                try manager
                    .getRatingPreviews(
                        for:
                            currentCard
                    )

        } catch {

            showError(
                error
            )
        }
    }

    private func intervalText(
        for rating: Rating
    ) -> String {

        guard
            let ratingPreviews
        else {

            return "—"
        }

        let dueDate =
            ratingPreviews
                .dueDate(
                    for:
                        rating
                )

        return ReviewIntervalFormatter
            .string(
                from:
                    ratingPreviews
                        .generatedAt,
                to:
                    dueDate
            )
    }

    // MARK: - Submit Rating

    private func submitReview(
        _ rating: Rating
    ) {

        guard
            let currentCard
        else {
            return
        }

        let manager =
            CardManager(
                modelContext:
                    modelContext
            )

        do {

            try manager.reviewCard(
                id:
                    currentCard.id,
                rating:
                    rating
            )

            answerRevealed =
                false

            ratingPreviews =
                nil

            loadReviewState()

        } catch {

            showError(
                error
            )
        }
    }

    // MARK: - State

    private func loadReviewState() {

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

        ratingPreviews =
            nil
    }

    // MARK: - Error

    private func showError(
        _ error: Error
    ) {

        errorMessage =
            error.localizedDescription

        showingError =
            true
    }
}

// MARK: - Cross-platform Navigation

private extension View {

    @ViewBuilder
    func pyokoReviewNavigationStyle()
        -> some View {

        #if os(iOS)

        self
            .toolbar(
                .hidden,
                for:
                    .navigationBar
            )

        #else

        self

        #endif
    }
}
