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

    @Query
    private var quickConfigs:
        [PyokoQuickConfig]

    @Query
    private var reviewConfigs:
        [PyokoConfig]

    @State
    private var todayReviewCount =
        0

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
        .navigationTitle(
            "Quick Review"
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

    // MARK: - Config

    @ViewBuilder
    private func configView(
        _ storedConfig:
            PyokoQuickConfig
    ) -> some View {

        @Bindable
        var config =
            storedConfig

        ScrollView {

            VStack(
                spacing: 18
            ) {

                GroupBox(
                    "Vocabulary Source"
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

                    tagSection(
                        config
                    )
                }

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
                    }
                }

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

                GroupBox(
                    "Direction"
                ) {

                    VStack(
                        spacing: 12
                    ) {

                        Toggle(
                            "Recognition",
                            isOn:
                                recognitionBinding(
                                    config
                                )
                        )

                        Toggle(
                            "Recall",
                            isOn:
                                recallBinding(
                                    config
                                )
                        )

                        if config
                            .writingEnabled {

                            Text(
                                directionDescription(
                                    config
                                )
                            )
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .secondary
                            )
                            .frame(
                                maxWidth:
                                    .infinity,
                                alignment:
                                    .leading
                            )
                        }
                    }
                }

                GroupBox(
                    "Card Display"
                ) {

                    VStack(
                        spacing: 14
                    ) {

                        Picker(
                            "Before Answer",
                            selection:
                                Binding(
                                    get: {
                                        config
                                            .beforeAnswerDisplayMode
                                    },
                                    set: {
                                        config
                                            .beforeAnswerDisplayMode =
                                                $0

                                        save()
                                    }
                                )
                        ) {

                            ForEach(
                                TargetDisplayMode
                                    .allCases,
                                id: \.rawValue
                            ) { mode in

                                Text(
                                    mode.title
                                )
                                .tag(
                                    mode
                                )
                            }
                        }

                        Picker(
                            "After Answer",
                            selection:
                                Binding(
                                    get: {
                                        config
                                            .afterAnswerDisplayMode
                                    },
                                    set: {
                                        config
                                            .afterAnswerDisplayMode =
                                                $0

                                        save()
                                    }
                                )
                        ) {

                            ForEach(
                                TargetDisplayMode
                                    .allCases,
                                id: \.rawValue
                            ) { mode in

                                Text(
                                    mode.title
                                )
                                .tag(
                                    mode
                                )
                            }
                        }

                        Toggle(
                            "Reading Hint",
                            isOn:
                                Binding(
                                    get: {
                                        config
                                            .readingHintEnabled
                                    },
                                    set: {
                                        config
                                            .readingHintEnabled =
                                                $0

                                        save()
                                    }
                                )
                        )
                    }
                }

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
                            .frame(
                                maxWidth:
                                    .infinity
                            )
                        }
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
            .frame(
                maxWidth: 700
            )
            .padding()
            .frame(
                maxWidth:
                    .infinity
            )
        }
    }

    // MARK: - Writing Description

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

    private func directionDescription(
        _ config:
            PyokoQuickConfig
    ) -> String {

        if config.includeRecognition
            && config.includeRecall {

            return
                """
                Writing will mix Recognition and Recall cards during the session.
                """
        }

        if config.includeRecognition {

            return
                """
                Recognition: see the target word and write its source meaning.
                """
        }

        return
            """
            Recall: see the source meaning and write the target word.
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
        .disabled(
            unavailable
        )
    }

    private func sourceSubtitle(
        _ source: QuickSource
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
        _ deck: PyokoDeck,
        config: PyokoQuickConfig
    ) -> Bool {

        (config.selectedDecks ?? [])
            .contains {
                $0.id == deck.id
            }
    }

    private func setDeckSelected(
        _ deck: PyokoDeck,
        selected: Bool,
        config: PyokoQuickConfig
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

    private func tagSection(
        _ config:
            PyokoQuickConfig
    ) -> some View {

        GroupBox(
            "Selected Tags"
        ) {

            VStack(
                spacing: 10
            ) {

                if tags.isEmpty {

                    Text(
                        "No tags are available."
                    )
                    .foregroundStyle(
                        .secondary
                    )

                } else {

                    ForEach(
                        tags
                    ) { tag in

                        Toggle(
                            tag.name,
                            isOn:
                                Binding(
                                    get: {

                                        isTagSelected(
                                            tag,
                                            config:
                                                config
                                        )
                                    },
                                    set: {

                                        setTagSelected(
                                            tag,
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

    private func isTagSelected(
        _ tag: PyokoTag,
        config: PyokoQuickConfig
    ) -> Bool {

        (config.selectedTags ?? [])
            .contains {
                $0.id == tag.id
            }
    }

    private func setTagSelected(
        _ tag: PyokoTag,
        selected: Bool,
        config: PyokoQuickConfig
    ) {

        var selectedTags =
            config.selectedTags
            ?? []

        if selected {

            guard !selectedTags
                .contains(
                    where: {
                        $0.id
                        == tag.id
                    }
                )
            else {
                return
            }

            selectedTags.append(
                tag
            )

        } else {

            selectedTags.removeAll {
                $0.id == tag.id
            }
        }

        config.selectedTags =
            selectedTags

        save()
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

            return !(config
                .selectedTags
                ?? [])
                .isEmpty

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

            if (config.selectedTags
                ?? [])
                .isEmpty {

                return
                    "Select at least one tag."
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
