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
    
    // MARK: - Review State
    
    @State private var currentCard:
        PyokoCard?
    
    @State private var showingAnswer =
        false
    
    @State private var progress =
        ReviewProgress(
            completed: 0,
            total: 0
        )
    
    @State private var hasLoaded =
        false
    
    // MARK: - Error
    
    @State private var showingError =
        false
    
    @State private var errorMessage =
        ""
    
    // MARK: - Body
    
    var body: some View {
        
        VStack(
            spacing: 24
        ) {
            
            if let currentCard {
                
                reviewContent(
                    card: currentCard
                )
                
            } else if hasLoaded {
                
                completeContent
                
            } else {
                
                ProgressView()
            }
        }
        .padding()
        .navigationTitle(
            "Review"
        )
        .onAppear {
            loadReview()
        }
        .alert(
            "Review Error",
            isPresented: $showingError
        ) {
            
            Button("OK") {}
            
        } message: {
            
            Text(errorMessage)
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
            ?? .target
    }
    
    private var afterAnswerDisplayMode:
        TargetDisplayMode {
        
        configuration?
            .afterAnswerDisplayMode
            ?? .reading
    }
    
    // MARK: - Review Content
    
    private func reviewContent(
        card: PyokoCard
    ) -> some View {
        
        VStack(
            spacing: 24
        ) {
            
            progressView
            
            Spacer()
            
            cardTypeLabel(
                card: card
            )
            
            questionView(
                card: card
            )
            
            if showingAnswer {
                
                Divider()
                    .frame(
                        maxWidth: 500
                    )
                
                answerView(
                    card: card
                )
            }
            
            Spacer()
            
            if showingAnswer {
                
                ratingButtons
                
            } else {
                
                Button {
                    
                    showingAnswer = true
                    
                } label: {
                    
                    Text(
                        "Show Answer"
                    )
                    .frame(
                        maxWidth: 300
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )
                .controlSize(
                    .large
                )
            }
        }
        .frame(
            maxWidth: 700,
            maxHeight: .infinity
        )
    }
    
    // MARK: - Question
    
    @ViewBuilder
    private func questionView(
        card: PyokoCard
    ) -> some View {
        
        switch card.type {
            
        case .recognition:
            
            Text(
                displayedTarget(
                    card: card,
                    mode:
                        showingAnswer
                        ? afterAnswerDisplayMode
                        : beforeAnswerDisplayMode
                )
            )
            .font(
                .system(
                    size: 36,
                    weight: .semibold
                )
            )
            .multilineTextAlignment(
                .center
            )
            .textSelection(
                .enabled
            )
            
        case .recall:
            
            Text(
                card.sourceText
            )
            .font(
                .system(
                    size: 36,
                    weight: .semibold
                )
            )
            .multilineTextAlignment(
                .center
            )
            .textSelection(
                .enabled
            )
        }
    }
    
    // MARK: - Answer
    
    @ViewBuilder
    private func answerView(
        card: PyokoCard
    ) -> some View {
        
        switch card.type {
            
        case .recognition:
            
            Text(
                card.sourceText
            )
            .font(
                .system(
                    size: 30
                )
            )
            .multilineTextAlignment(
                .center
            )
            .textSelection(
                .enabled
            )
            
        case .recall:
            
            Text(
                displayedTarget(
                    card: card,
                    mode:
                        afterAnswerDisplayMode
                )
            )
            .font(
                .system(
                    size: 30
                )
            )
            .multilineTextAlignment(
                .center
            )
            .textSelection(
                .enabled
            )
        }
    }
    
    // MARK: - Target Display
    
    private func displayedTarget(
        card: PyokoCard,
        mode: TargetDisplayMode
    ) -> String {
        
        switch mode {
            
        case .target:
            
            return card.targetText
            
        case .reading:
            
            return card.targetReading
                ?? card.targetText
        }
    }
    
    // MARK: - Progress
    
    private var progressView:
        some View {
        
        VStack(
            spacing: 6
        ) {
            
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
            
            Text(
                "\(progress.completed) of \(progress.total)"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
        }
        .frame(
            maxWidth: 500
        )
    }
    
    // MARK: - Card Type
    
    @ViewBuilder
    private func cardTypeLabel(
        card: PyokoCard
    ) -> some View {
        
        switch card.type {
            
        case .recognition:
            
            Label(
                "Recognition",
                systemImage: "eye"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
            
        case .recall:
            
            Label(
                "Recall",
                systemImage:
                    "bubble.left.and.bubble.right"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
        }
    }
    
    // MARK: - Rating Buttons
    
    private var ratingButtons:
        some View {
        
        LazyVGrid(
            columns: [
                GridItem(
                    .adaptive(
                        minimum: 110
                    )
                )
            ],
            spacing: 12
        ) {
            
            ratingButton(
                title: "Again",
                rating: .again,
                prominent: false
            )
            
            ratingButton(
                title: "Hard",
                rating: .hard,
                prominent: false
            )
            
            ratingButton(
                title: "Good",
                rating: .good,
                prominent: true
            )
            
            ratingButton(
                title: "Easy",
                rating: .easy,
                prominent: false
            )
        }
        .frame(
            maxWidth: 600
        )
    }
    
    @ViewBuilder
    private func ratingButton(
        title: String,
        rating: Rating,
        prominent: Bool
    ) -> some View {
        
        if prominent {
            
            Button(title) {
                
                submitRating(
                    rating
                )
            }
            .buttonStyle(
                .borderedProminent
            )
            .controlSize(
                .large
            )
            
        } else {
            
            Button(title) {
                
                submitRating(
                    rating
                )
            }
            .buttonStyle(
                .bordered
            )
            .controlSize(
                .large
            )
        }
    }
    
    // MARK: - Complete
    
    private var completeContent:
        some View {
        
        VStack(
            spacing: 20
        ) {
            
            Spacer()
            
            Image(
                systemName:
                    progress.total == 0
                    ? "tray"
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
                    "No Cards to Review"
                )
                .font(.title2)
                .fontWeight(
                    .semibold
                )
                
                Text(
                    "There are currently no due cards matching your configuration."
                )
                .multilineTextAlignment(
                    .center
                )
                .foregroundStyle(
                    .secondary
                )
                
            } else {
                
                Text(
                    "Review Complete"
                )
                .font(.title2)
                .fontWeight(
                    .semibold
                )
                
                Text(
                    "You reviewed \(progress.completed) cards."
                )
                .foregroundStyle(
                    .secondary
                )
            }
            
            Button {
                
                dismiss()
                
            } label: {
                
                Text(
                    "Go Home"
                )
                .frame(
                    minWidth: 140
                )
            }
            .buttonStyle(
                .borderedProminent
            )
            
            Spacer()
        }
        .frame(
            maxWidth: 500
        )
    }
    
    // MARK: - Load Review
    
    private func loadReview() {
        
        guard !hasLoaded else {
            return
        }
        
        let manager = CardManager(
            modelContext:
                modelContext
        )
        
        currentCard =
            manager.getNextCard()
        
        progress =
            manager.getProgress()
        
        hasLoaded = true
    }
    
    // MARK: - Submit Rating
    
    private func submitRating(
        _ rating: Rating
    ) {
        
        guard let currentCard else {
            return
        }
        
        let manager = CardManager(
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
            
            showingAnswer = false
            
            self.currentCard =
                manager.getNextCard()
            
            progress =
                manager.getProgress()
            
        } catch {
            
            errorMessage =
                error.localizedDescription
            
            showingError =
                true
        }
    }
}
