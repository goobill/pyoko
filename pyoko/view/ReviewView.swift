import SwiftUI
import SwiftData
import FSRS

struct ReviewView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Environment(\.dismiss)
    private var dismiss
    
    @Query
    private var configurations:
        [PyokoConfiguration]
    
    @State
    private var currentCard:
        PyokoCard?
    
    @State
    private var showingAnswer =
        false
    
    @State
    private var isReadingHintVisible =
        false
    
    @State
    private var progress =
        ReviewProgress(
            completed: 0,
            total: 0
        )
    
    @State
    private var showingError =
        false
    
    @State
    private var errorMessage =
        ""
    
    // MARK: - Body
    
    var body: some View {
        
        ScrollView {
            
            VStack(
                spacing: 24
            ) {
                
                progressHeader
                
                if let currentCard {
                    
                    ReviewCardView(
                        card:
                            currentCard,
                        isAnswerVisible:
                            showingAnswer,
                        beforeAnswerDisplayMode:
                            beforeAnswerDisplayMode,
                        afterAnswerDisplayMode:
                            afterAnswerDisplayMode,
                        readingHintEnabled:
                            readingHintEnabled,
                        isReadingHintVisible:
                            isReadingHintVisible,
                        onReveal: {
                            
                            withAnimation(
                                .easeInOut(
                                    duration: 0.2
                                )
                            ) {
                                
                                showingAnswer =
                                    true
                            }
                        },
                        onShowReadingHint: {
                            
                            withAnimation(
                                .easeInOut(
                                    duration: 0.2
                                )
                            ) {
                                
                                isReadingHintVisible =
                                    true
                            }
                        }
                    )
                    
                    if showingAnswer {
                        
                        ratingButtons
                    }
                    
                } else {
                    
                    finishedContent
                }
            }
            .padding()
            .frame(
                maxWidth: 700
            )
            .frame(
                maxWidth:
                    .infinity
            )
        }
        .navigationTitle(
            "Review"
        )
        .onAppear {
            loadReview()
        }
        .alert(
            "Review Error",
            isPresented:
                $showingError
        ) {
            
            Button("OK") {}
            
        } message: {
            
            Text(
                errorMessage
            )
        }
    }
    
    // MARK: - Configuration
    
    private var configuration:
        PyokoConfiguration? {
        
        configurations.first
    }
    
    private var beforeAnswerDisplayMode:
        TargetDisplayMode {
        
        configuration?
            .beforeAnswerDisplayMode
        ??
        TargetDisplayMode.target
    }
    
    private var afterAnswerDisplayMode:
        TargetDisplayMode {
        
        configuration?
            .afterAnswerDisplayMode
        ??
        TargetDisplayMode
            .targetAndReading
    }
    
    private var readingHintEnabled:
        Bool {
        
        configuration?
            .readingHintEnabled
        ??
        true
    }
    
    // MARK: - Progress
    
    private var progressHeader:
        some View {
        
        VStack(
            spacing: 8
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
                .foregroundStyle(
                    .secondary
                )
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
    
    // MARK: - Rating Buttons
    
    private var ratingButtons:
        some View {
        
        VStack(
            spacing: 12
        ) {
            
            Text(
                "How well did you remember?"
            )
            .font(
                .headline
            )
            
            HStack(
                spacing: 10
            ) {
                
                ratingButton(
                    title: "Again",
                    rating:
                        Rating.again
                )
                
                ratingButton(
                    title: "Hard",
                    rating:
                        Rating.hard
                )
                
                ratingButton(
                    title: "Good",
                    rating:
                        Rating.good
                )
                
                ratingButton(
                    title: "Easy",
                    rating:
                        Rating.easy
                )
            }
        }
    }
    
    private func ratingButton(
        title: String,
        rating: Rating
    ) -> some View {
        
        Button(title) {
            
            submit(
                rating:
                    rating
            )
        }
        .buttonStyle(
            .bordered
        )
        .frame(
            maxWidth:
                .infinity
        )
    }
    
    // MARK: - Finished
    
    @ViewBuilder
    private var finishedContent:
        some View {
        
        VStack(
            spacing: 18
        ) {
            
            Image(
                systemName:
                    progress.total == 0
                    ? "moon.zzz"
                    : "checkmark.circle"
            )
            .font(
                .system(
                    size: 52
                )
            )
            .foregroundStyle(
                .secondary
            )
            
            if progress.total == 0 {
                
                Text(
                    "Nothing to review"
                )
                .font(
                    .title2
                )
                .fontWeight(
                    .semibold
                )
                
                Text(
                    "There are no cards due right now."
                )
                .foregroundStyle(
                    .secondary
                )
                
            } else {
                
                Text(
                    "Review complete"
                )
                .font(
                    .title2
                )
                .fontWeight(
                    .semibold
                )
                
                Text(
                    "You completed \(progress.total) cards."
                )
                .foregroundStyle(
                    .secondary
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
        .padding(
            .vertical,
            40
        )
    }
    
    // MARK: - Load
    
    private func loadReview() {
        
        let manager =
            CardManager(
                modelContext:
                    modelContext
            )
        
        progress =
            manager.getProgress()
        
        currentCard =
            manager.getNextCard()
        
        showingAnswer =
            false
        
        isReadingHintVisible =
            false
    }
    
    // MARK: - Submit
    
    private func submit(
        rating: Rating
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
            
            showingAnswer =
                false
            
            isReadingHintVisible =
                false
            
            progress =
                manager.getProgress()
            
            self.currentCard =
                manager.getNextCard()
            
        } catch {
            
            showError(
                error
            )
        }
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
