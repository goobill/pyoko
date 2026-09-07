import SwiftUI
import SwiftData
import FSRS

struct ReviewView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Environment(\.dismiss)
    private var dismiss
    
    @Query
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
                    onCheckAgain:
                        refreshCompletion,
                    onExit: {
                        dismiss()
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(
            true
        )
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
    
    // MARK: - Review Content
    
    private func reviewContent(
        card: PyokoCard
    ) -> some View {
        
        VStack(
            spacing: 0
        ) {
            
            topBar
            
            Spacer(
                minLength: 16
            )
            
            ReviewCardView(
                card: card,
                beforeAnswerDisplayMode:
                    beforeAnswerDisplayMode,
                afterAnswerDisplayMode:
                    afterAnswerDisplayMode,
                readingHintEnabled:
                    readingHintEnabled,
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
            
            ratingArea
            
        } else {
            
            showAnswerArea
        }
    }
    
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
            
            HStack(
                spacing: 8
            ) {
                
                ratingButton(
                    rating:
                            .again,
                    opacity:
                        0.95
                )
                
                ratingButton(
                    rating:
                            .hard,
                    opacity:
                        0.78
                )
                
                ratingButton(
                    rating:
                            .good,
                    opacity:
                        0.60
                )
                
                ratingButton(
                    rating:
                            .easy,
                    opacity:
                        0.42
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
            
            Text(
                intervalText(
                    for: rating
                )
            )
            .font(
                .subheadline
            )
            .fontWeight(
                .semibold
            )
            .frame(
                maxWidth:
                        .infinity
            )
            .frame(
                height: 48
            )
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
                for: rating
            )
        )
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
    
    // MARK: - Interval Text
    
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
                        for: rating
                    )
            )
    }
    
    private func accessibilityLabel(
        for rating: Rating
    ) -> String {
        
        let name: String
        
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
        
        return
            "\(name), next review \(intervalText(for: rating))"
    }
}
