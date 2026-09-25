import SwiftUI
import SwiftData

struct QuickConfigView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query(
        sort: \PyokoDeck.name
    )
    private var decks:
        [PyokoDeck]

    @Query(
        sort: \PyokoTag.name
    )
    private var tags:
        [PyokoTag]

    @Query private var vocabularyCards: [PyokoCard]

    /// Use card-side relationships, just as the selector does. Stored tags can outlive their cards.
    private var availableTags: [PyokoTag] {
        let ids = Set(vocabularyCards.filter { $0.deck != nil }
            .flatMap { $0.tags ?? [] }.map(\.id))
        return tags.filter { ids.contains($0.id) }
    }

    private func hasMatchingTags(_ config: PyokoQuickConfig) -> Bool {
        let selected = Set((config.selectedTags ?? []).map(\.id))
        return availableTags.contains { selected.contains($0.id) }
    }

    @Query(sort: \PyokoQuickConfig.createdAt)
    private var quickConfigs:
        [PyokoQuickConfig]

    @Query(sort: \PyokoConfig.createdAt)
    private var reviewConfigs:
        [PyokoConfig]

    @State
    private var todayReviewCount =
        0

    @Query(filter: #Predicate<PyokoCard> { $0.reps > 0 })
    private var reviewedCards: [PyokoCard]

    private var hasPreviouslyReviewedVocabulary: Bool {
        let enabled = Set((reviewConfigs.first?.selectedDecks ?? (reviewConfigs.isEmpty ? decks : [])).map(\.id))
        return reviewedCards.contains { card in
            card.deck.map { enabled.contains($0.id) } ?? false
        }
    }

    @State
    private var errorMessage:
        String?

    var body: some View {

        Group {

            if let config =
                quickConfigs.first {

                configView(
                    config
                )

            } else {

                ProgressView()
                    .task {

                        createConfigIfNeeded()
                    }
            }
        }
        .pyokoSurface()
        .navigationTitle(
            "Quick Review Config"
        )
        .task {

            createConfigIfNeeded()

            refreshTodayReview()
        }
        .onAppear {

            refreshTodayReview()
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

    // MARK: - Config

    @ViewBuilder
    private func configView(
        _ storedConfig:
            PyokoQuickConfig
    ) -> some View {

        @Bindable
        var config =
            storedConfig

        ConfigWorkspace {


                #if os(macOS)
                GroupBox("Session") {
                    MacCountControl(title: "Cards", value: Binding(
                        get: { config.cardCount }, set: { config.cardCount = $0; save() }),
                        range: 1...100)
                        .accessibilityIdentifier("quick.count")
                        .accessibilityValue("\(config.cardCount)")
                }
                #else
                GroupBox(
                    "Session"
                ) {

                    VStack(
                        spacing: 12
                    ) {

                        HStack {

                            Text(
                                "Cards"
                            )

                            Spacer()

                            Text(
                                "\(config.cardCount)"
                            )
                            .foregroundStyle(
                                .secondary
                            )
                            .monospacedDigit()
                        }

                        Stepper(
                            "Card Count",
                            value:
                                Binding(
                                    get: {

                                        config
                                            .cardCount
                                    },
                                    set: {

                                        config
                                            .cardCount =
                                                $0

                                        save()
                                    }
                                ),
                            in: 1...100
                        )
                        .labelsHidden()
                        .accessibilityIdentifier("quick.count")
                        .accessibilityValue("\(config.cardCount)")
                    }
                }


                #endif
                GroupBox(
                    "Practice Mode"
                ) {

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Toggle(
                            "Writing",
                            isOn:
                                Binding(
                                    get: {

                                        config
                                            .writingEnabled
                                    },
                                    set: {

                                        config
                                            .writingEnabled =
                                                $0

                                        save()
                                    }
                                )
                        )
                        .accessibilityIdentifier("quick.writing")

                        Text(
                            writingDescription(
                                config
                            )
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .secondary
                        )
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                    }
                }

                CardConfigView(
                    recognition: recognitionBinding(config),
                    recall: recallBinding(config),
                    before: Binding(get: { config.beforeAnswerDisplayMode }, set: { config.beforeAnswerDisplayMode = $0; save() }),
                    after: Binding(get: { config.afterAnswerDisplayMode }, set: { config.afterAnswerDisplayMode = $0; save() }),
                    hiraganaOnly: Binding(get: { config.recognitionReadingOnlyEnabled }, set: { config.recognitionReadingOnlyEnabled = $0; save() }),
                    hint: Binding(get: { config.readingHintEnabled }, set: { config.readingHintEnabled = $0; save() })
                )
        } preview: {
                CardPreviewView(
                    quick: true, recognition: config.includeRecognition, recall: config.includeRecall,
                    before: config.beforeAnswerDisplayMode, after: config.afterAnswerDisplayMode,
                    hiraganaOnly: config.recognitionReadingOnlyEnabled, hint: config.readingHintEnabled, writing: config.writingEnabled
                )
        } vocabulary: {
                GroupBox(
                    "Vocabulary"
                ) {

                    VStack(
                        spacing: 6
                    ) {

                        ForEach(
                            QuickSource.allCases
                        ) { source in

                            sourceButton(
                                source:
                                    source,
                                config:
                                    config
                            )
                        }
                    }
                }

                if config.source
                    == .decks {

                    deckSection(
                        config
                    )
                }

                if config.source
                    == .tags {

                    TagSelectionView(
                        title:
                            "Selected Tags",
                        tags:
                            availableTags,
                        selectedTags:
                            tagBinding(
                                config
                            ),
                        emptySelectionMessage:
                            """
                            Select at least one tag to start Quick Review.
                            """
                    )
                }
        } footer: {
                GroupBox {

                    VStack(
                        spacing: 12
                    ) {

                        Text(
                            """
                            Quick Review is separate from your scheduled reviews. Correct and Incorrect results are only used during this Quick Review session and never change FSRS scheduling.
                            """
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .secondary
                        )
                        .multilineTextAlignment(
                            .center
                        )

                        NavigationLink {

                            QuickView(
                                config:
                                    config
                            )

                        } label: {

                            Text(
                                "Start Quick Review"
                            )
                            #if os(macOS)
                            .frame(minHeight: 36)
                            #endif
                            .frame(
                                maxWidth:
                                    .infinity
                            )
                        }
                        .accessibilityIdentifier("quick.start")
                        .buttonStyle(
                            .borderedProminent
                        )
                        .disabled(
                            !canStart(
                                config
                            )
                        )

                        if let validation =
                            validationMessage(
                                config
                            ) {

                            Text(
                                validation
                            )
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .secondary
                            )
                            .multilineTextAlignment(
                                .center
                            )
                        }
                    }
                    .frame(
                        maxWidth:
                            .infinity
                    )
                }
        }
    }

    // MARK: - Writing

    private func writingDescription(
        _ config:
            PyokoQuickConfig
    ) -> String {

        if config.writingEnabled {

            return
                """
                Write your answer before revealing the card. Pyoko then shows your response beside the correct answer so you can compare them yourself. After checking, mark the card Correct or Incorrect. Incorrect cards can be reviewed again at the end of the session.
                """
        }

        return
            """
            Think of the answer, reveal the card, then mark yourself Correct or Incorrect. Incorrect cards can be reviewed again at the end.
            """
    }

    // MARK: - Source

    private func sourceButton(
        source: QuickSource,
        config: PyokoQuickConfig
    ) -> some View {

        let unavailable =
            source == .todaysReview
            && todayReviewCount == 0

        return Button {

            config.source =
                source

            save()

        } label: {

            HStack(
                spacing: 12
            ) {

                if config.source
                    == source {

                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .foregroundStyle(
                        .tint
                    )

                } else {

                    Image(
                        systemName:
                            "circle"
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text(
                        source.title
                    )
                    .foregroundStyle(
                        .primary
                    )

                    Text(
                        sourceSubtitle(
                            source
                        )
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                Spacer()
            }
            .contentShape(
                Rectangle()
            )
            .padding(
                .vertical,
                5
            )
        }
        .buttonStyle(
            .plain
        )
        .accessibilityIdentifier("quick.source.\(source.rawValue)")
        .accessibilityValue(config.source == source ? "Selected" : "Not selected")
        .disabled(
            unavailable
        )
    }

    private func sourceSubtitle(
        _ source:
            QuickSource
    ) -> String {

        guard source
            == .todaysReview
        else {

            return source.subtitle
        }

        guard todayReviewCount > 0
        else {

            return
                "No reviewed vocabulary available today."
        }

        if todayReviewCount == 1 {

            return
                "1 reviewed word available today."
        }

        return
            "\(todayReviewCount) reviewed words available today."
    }

    // MARK: - Decks

    private func deckSection(
        _ config:
            PyokoQuickConfig
    ) -> some View {

        GroupBox(
            "Selected Decks"
        ) {

            VStack(
                spacing: 10
            ) {

                if decks.isEmpty {

                    Text(
                        "No decks are installed."
                    )
                    .foregroundStyle(
                        .secondary
                    )

                } else {

                    ForEach(
                        decks
                    ) { deck in

                        Toggle(
                            deck.name,
                            isOn:
                                Binding(
                                    get: {

                                        isDeckSelected(
                                            deck,
                                            config:
                                                config
                                        )
                                    },
                                    set: {

                                        setDeckSelected(
                                            deck,
                                            selected:
                                                $0,
                                            config:
                                                config
                                        )
                                    }
                                )
                        )
                    }
                }
            }
        }
    }

    private func isDeckSelected(
        _ deck:
            PyokoDeck,
        config:
            PyokoQuickConfig
    ) -> Bool {

        (config.selectedDecks ?? [])
            .contains {

                $0.id == deck.id
            }
    }

    private func setDeckSelected(
        _ deck:
            PyokoDeck,
        selected: Bool,
        config:
            PyokoQuickConfig
    ) {

        var selectedDecks =
            config.selectedDecks
            ?? []

        if selected {

            guard !selectedDecks
                .contains(
                    where: {

                        $0.id
                        == deck.id
                    }
                )
            else {
                return
            }

            selectedDecks.append(
                deck
            )

        } else {

            selectedDecks.removeAll {

                $0.id == deck.id
            }
        }

        config.selectedDecks =
            selectedDecks

        save()
    }

    // MARK: - Tags

    private func tagBinding(
        _ config:
            PyokoQuickConfig
    ) -> Binding<[PyokoTag]> {

        Binding(
            get: {

                config.selectedTags
                ?? []
            },
            set: {

                config.selectedTags =
                    $0

                save()
            }
        )
    }

    // MARK: - Direction

    private func recognitionBinding(
        _ config:
            PyokoQuickConfig
    ) -> Binding<Bool> {

        Binding(
            get: {

                config
                    .includeRecognition
            },
            set: { enabled in

                if !enabled
                    && !config
                        .includeRecall {

                    return
                }

                config
                    .includeRecognition =
                        enabled

                save()
            }
        )
    }

    private func recallBinding(
        _ config:
            PyokoQuickConfig
    ) -> Binding<Bool> {

        Binding(
            get: {

                config
                    .includeRecall
            },
            set: { enabled in

                if !enabled
                    && !config
                        .includeRecognition {

                    return
                }

                config
                    .includeRecall =
                        enabled

                save()
            }
        )
    }

    // MARK: - Validation

    private func canStart(
        _ config:
            PyokoQuickConfig
    ) -> Bool {

        guard config.hasDirection
        else {
            return false
        }

        switch config.source {

        case .reviewed:
            return hasPreviouslyReviewedVocabulary

        case .random:

            if let reviewConfig =
                reviewConfigs.first {

                return !(reviewConfig
                    .selectedDecks
                    ?? [])
                    .isEmpty
            }

            return !decks.isEmpty

        case .decks:

            return !(config
                .selectedDecks
                ?? [])
                .isEmpty

        case .tags:

            return hasMatchingTags(config)

        case .todaysReview:

            return todayReviewCount
                > 0
        }
    }

    private func validationMessage(
        _ config:
            PyokoQuickConfig
    ) -> String? {

        guard config.hasDirection
        else {

            return
                "Enable Recognition or Recall."
        }

        switch config.source {

        case .reviewed:
            if !hasPreviouslyReviewedVocabulary {
                return "Grade a card in scheduled Review and keep its deck enabled to practise previously reviewed vocabulary."
            }

        case .random:

            if let reviewConfig =
                reviewConfigs.first,
               (reviewConfig.selectedDecks
                ?? [])
                .isEmpty {

                return
                    "Enable at least one deck in your main review config."
            }

            if reviewConfigs.isEmpty
                && decks.isEmpty {

                return
                    "Install or import a deck first."
            }

        case .decks:

            if (config.selectedDecks
                ?? [])
                .isEmpty {

                return
                    "Select at least one deck."
            }

        case .tags:

            if !hasMatchingTags(config) {

                return
                    "Select a tag with vocabulary in an installed deck. A saved tag may no longer have any cards."
            }

        case .todaysReview:

            if todayReviewCount == 0 {

                return
                    "Review some vocabulary first before using Today's Review."
            }
        }

        return nil
    }

    // MARK: - Config Creation

    private func createConfigIfNeeded() {

        guard quickConfigs.isEmpty
        else {
            return
        }

        let config =
            PyokoQuickConfig(
                selectedDecks:
                    decks,
                selectedTags:
                    tags
            )

        modelContext.insert(
            config
        )

        save()
    }

    // MARK: - Today's Review

    private func refreshTodayReview() {

        do {

            let provider =
                TodayReviewProvider(
                    modelContext:
                        modelContext
                )

            todayReviewCount =
                try provider
                    .vocabularyCount()

        } catch {

            todayReviewCount =
                0

            print(
                "Failed to load today's reviewed vocabulary: \(error)"
            )
        }
    }

    // MARK: - Save

    private func save() {

        do {

            try modelContext.save()

        } catch {

            errorMessage =
                error.localizedDescription
        }
    }
}
