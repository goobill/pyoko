import SwiftUI
import SwiftData
import FSRS

struct ReviewView: View {

    @Environment(
        \.modelContext
    )
    private var modelContext

    @Environment(
        \.dismiss
    )
    private var dismiss

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

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            header

            if progress.total > 0 {

                progressSection
                    .padding(
                        .top,
                        28
                    )
            }

            reviewContent
                .padding(
                    .top,
                    28
                )

            Spacer(
                minLength: 0
            )
        }
        .frame(
            maxWidth: 760
        )
        .frame(
            maxWidth: .infinity,
            alignment: .top
        )
        .padding(
            .horizontal,
            24
        )
        .padding(
            .top,
            8
        )
        .safeAreaInset(
            edge: .bottom,
            spacing: 0
        ) {

            bottomReviewControls
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

    // MARK: - Header

    private var header:
        some View {

        VStack(
            alignment: .leading,
            spacing: 24
        ) {

            Button {

                dismiss()

            } label: {

                Image(
                    systemName:
                        "chevron.left"
                )
                .font(
                    .title2
                        .weight(
                            .semibold
                        )
                )
                .frame(
                    width: 52,
                    height: 52
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

            Text(
                "Review"
            )
            .font(
                .largeTitle
                    .bold()
            )
        }
    }

    // MARK: - Progress

    private var progressSection:
        some View {

        VStack(
            spacing: 10
        ) {

            HStack {

                Text(
                    "Progress"
                )
                .font(
                    .headline
                )

                Spacer()

                Text(
                    "\(progress.completed) / \(progress.total)"
                )
                .font(
                    .title3
                )
                .foregroundStyle(
                    .secondary
                )
                .monospacedDigit()
            }

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
        }
    }

    // MARK: - Review Content

    @ViewBuilder
    private var reviewContent:
        some View {

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

        } else if
            progress.total > 0,
            progress.remaining == 0 {

            reviewCompleteView

        } else {

            noCardsView
        }
    }

    // MARK: - Bottom Controls

    @ViewBuilder
    private var bottomReviewControls:
        some View {

        if currentCard != nil,
           answerRevealed {

            VStack(
                spacing: 12
            ) {

                Divider()

                Text(
                    "How well did you remember?"
                )
                .font(
                    .headline
                )
                .multilineTextAlignment(
                    .center
                )

                HStack(
                    spacing: 10
                ) {

                    ratingButton(
                        title:
                            "Again",
                        rating:
                            Rating.again
                    )

                    ratingButton(
                        title:
                            "Hard",
                        rating:
                            Rating.hard
                    )

                    ratingButton(
                        title:
                            "Good",
                        rating:
                            Rating.good
                    )

                    ratingButton(
                        title:
                            "Easy",
                        rating:
                            Rating.easy
                    )
                }
            }
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
            .background(
                .regularMaterial
            )
        }
    }

    private func ratingButton(
        title: String,
        rating: Rating
    ) -> some View {

        Button {

            submitReview(
                rating
            )

        } label: {

            VStack(
                spacing: 5
            ) {

                Text(
                    intervalText(
                        for: rating
                    )
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
                .monospacedDigit()

                Text(
                    title
                )
                .font(
                    .headline
                )
            }
            .frame(
                maxWidth: .infinity
            )
            .frame(
                minHeight: 64
            )
        }
        .buttonStyle(
            .bordered
        )
        .controlSize(
            .large
        )
    }

    // MARK: - Completion

    private var reviewCompleteView:
        some View {

        VStack(
            spacing: 20
        ) {

            ContentUnavailableView {

                Label(
                    "Review Complete",
                    systemImage:
                        "checkmark.circle"
                )

            } description: {

                Text(
                    "You've finished today's review."
                )
            }

            Button(
                "Go Home"
            ) {

                dismiss()
            }
            .buttonStyle(
                .borderedProminent
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .top,
            40
        )
    }

    private var noCardsView:
        some View {

        VStack(
            spacing: 20
        ) {

            ContentUnavailableView {

                Label(
                    "No Cards Due",
                    systemImage:
                        "checkmark.circle"
                )

            } description: {

                Text(
                    "There are no cards available for review right now."
                )
            }

            Button(
                "Go Home"
            ) {

                dismiss()
            }
            .buttonStyle(
                .bordered
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .top,
            40
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

    // MARK: - Preview

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

    // MARK: - Review

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
