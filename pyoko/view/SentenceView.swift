//
//  SentenceView.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

import SwiftUI
import SwiftData

struct SentenceView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    let config:
        PyokoSentenceConfig

    @State
    private var manager:
        SentenceManager?

    @State
    private var isRevealed =
        false

    @State
    private var userAnswer =
        ""

    var body: some View {

        Group {

            if let manager {

                sessionContent(
                    manager
                )

            } else {

                ProgressView(
                    "Starting practice…"
                )
            }
        }
        .navigationBarBackButtonHidden(
            true
        )
        .task {

            await startIfNeeded()
        }
    }

    @ViewBuilder
    private func sessionContent(
        _ manager:
            SentenceManager
    ) -> some View {

        if manager.isComplete {

            completionView(
                manager
            )

        } else {

            VStack(
                spacing: 18
            ) {

                topBar(
                    manager
                )

                if let error =
                    manager.errorMessage {

                    errorView(
                        error,
                        manager:
                            manager
                    )

                } else if
                    manager.isLoading,
                    manager.currentSentence ==
                        nil {

                    Spacer()

                    ProgressView(
                        "Generating sentence…"
                    )

                    Spacer()

                } else if let sentence =
                    manager.currentSentence {

                    ScrollView {

                        VStack(
                            spacing: 18
                        ) {

                            SentenceCardView(
                                sentence:
                                    sentence,
                                direction:
                                    manager
                                        .currentDirection,
                                display:
                                    config
                                        .display,
                                isRevealed:
                                    isRevealed,
                                userAnswer:
                                    $userAnswer,
                                onReveal: {

                                    withAnimation {

                                        isRevealed =
                                            true
                                    }
                                }
                            )

                            if isRevealed {

                                ratingArea(
                                    manager
                                )
                            }
                        }
                        .frame(
                            maxWidth:
                                700
                        )
                        .frame(
                            maxWidth:
                                .infinity
                        )
                        .padding(
                            .horizontal,
                            16
                        )
                        .padding(
                            .bottom,
                            24
                        )
                    }

                } else {

                    Spacer()

                    ProgressView()

                    Spacer()
                }
            }
        }
    }

    // MARK: - Top Bar

    private func topBar(
        _ manager:
            SentenceManager
    ) -> some View {

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
                .fontWeight(
                    .semibold
                )
                .frame(
                    width: 36,
                    height: 36
                )
            }
            .buttonStyle(
                .plain
            )
            .accessibilityLabel(
                "Back"
            )

            ProgressView(
                value:
                    Double(
                        min(
                            manager.currentIndex,
                            manager.total
                        )
                    ),
                total:
                    Double(
                        max(
                            manager.total,
                            1
                        )
                    )
            )

            Text(
                "\(min(manager.currentIndex + 1, manager.total))/\(manager.total)"
            )
            .font(
                .caption
            )
            .monospacedDigit()
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

    // MARK: - Ratings

    private func ratingArea(
        _ manager:
            SentenceManager
    ) -> some View {

        VStack(
            spacing: 12
        ) {

            Text(
                "How did you do?"
            )
            .font(
                .headline
            )

            HStack(
                spacing: 8
            ) {

                ForEach(
                    SentenceRating.allCases
                ) { rating in

                    ratingButton(
                        rating,
                        manager:
                            manager
                    )
                }
            }
        }
        .padding(
            .top,
            4
        )
    }

    private func ratingButton(
        _ rating:
            SentenceRating,
        manager:
            SentenceManager
    ) -> some View {

        Button {

            moveNext(
                rating,
                manager:
                    manager
            )

        } label: {

            Text(
                rating.title
            )
            .font(
                .subheadline
            )
            .fontWeight(
                .medium
            )
            .frame(
                maxWidth:
                    .infinity
            )
        }
        .buttonStyle(
            .bordered
        )
        .disabled(
            manager.isLoading
        )
    }

    private func moveNext(
        _ rating:
            SentenceRating,
        manager:
            SentenceManager
    ) {

        isRevealed =
            false

        userAnswer =
            ""

        Task {

            await manager.rate(
                rating
            )
        }
    }

    // MARK: - Error

    private func errorView(
        _ message:
            String,
        manager:
            SentenceManager
    ) -> some View {

        ContentUnavailableView {

            Label(
                "Couldn't Generate Sentence",
                systemImage:
                    "exclamationmark.triangle"
            )

        } description: {

            Text(
                message
            )

        } actions: {

            Button(
                "Try Again"
            ) {

                Task {

                    await manager.retry()
                }
            }
            .buttonStyle(
                .borderedProminent
            )
        }
        .frame(
            maxWidth:
                .infinity,
            maxHeight:
                .infinity
        )
    }

    // MARK: - Completion

    private func completionView(
        _ manager:
            SentenceManager
    ) -> some View {

        ScrollView {

            VStack(
                spacing: 24
            ) {

                Image(
                    systemName:
                        "checkmark.circle.fill"
                )
                .font(
                    .system(
                        size: 54
                    )
                )
                .foregroundStyle(
                    .tint
                )

                VStack(
                    spacing: 6
                ) {

                    Text(
                        "Practice Complete"
                    )
                    .font(
                        .title2
                    )
                    .fontWeight(
                        .semibold
                    )

                    Text(
                        "\(manager.total) sentences completed"
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                ratingSummary(
                    manager
                )

                Button(
                    "Done"
                ) {

                    dismiss()
                }
                .buttonStyle(
                    .borderedProminent
                )
                .controlSize(
                    .large
                )
            }
            .frame(
                maxWidth: 500
            )
            .frame(
                maxWidth:
                    .infinity
            )
            .padding(
                30
            )
        }
    }

    private func ratingSummary(
        _ manager:
            SentenceManager
    ) -> some View {

        HStack(
            spacing: 10
        ) {

            ForEach(
                SentenceRating.allCases
            ) { rating in

                VStack(
                    spacing: 4
                ) {

                    Text(
                        "\(ratingCount(rating, manager: manager))"
                    )
                    .font(
                        .title3
                    )
                    .fontWeight(
                        .semibold
                    )
                    .monospacedDigit()

                    Text(
                        rating.title
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
                .frame(
                    maxWidth:
                        .infinity
                )
                .padding(
                    .vertical,
                    12
                )
                .background {

                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                    .fill(
                        .regularMaterial
                    )
                }
            }
        }
    }

    private func ratingCount(
        _ rating:
            SentenceRating,
        manager:
            SentenceManager
    ) -> Int {

        manager.ratings.filter {
            $0 == rating
        }
        .count
    }

    // MARK: - Start

    private func startIfNeeded()
        async {

        guard manager == nil else {
            return
        }

        let newManager =
            SentenceManager(
                modelContext:
                    modelContext
            )

        manager =
            newManager

        await newManager.start(
            config:
                config
        )
    }
}
