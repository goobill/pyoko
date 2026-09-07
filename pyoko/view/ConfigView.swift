import SwiftUI
import SwiftData

struct ConfigView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query
    private var configs:
        [PyokoConfig]

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

    @AppStorage(
        "appearancePreference"
    )
    private var appearancePreference =
        "system"

    @State
    private var errorMessage:
        String?

    var body: some View {

        Group {

            if let config =
                configs.first {

                configContent(
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
            "Config"
        )
        .task {

            createConfigIfNeeded()
        }
        .alert(
            "Config",
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
                errorMessage ?? ""
            )
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func configContent(
        _ storedConfig:
            PyokoConfig
    ) -> some View {

        @Bindable
        var config =
            storedConfig

        ScrollView {

            VStack(
                spacing: 18
            ) {

                GroupBox(
                    "Daily Review"
                ) {

                    VStack(
                        spacing: 14
                    ) {

                        HStack {

                            Text(
                                "Daily Card Limit"
                            )

                            Spacer()

                            Text(
                                "\(config.dailyCardLimit)"
                            )
                            .foregroundStyle(
                                .secondary
                            )
                            .monospacedDigit()
                        }

                        Stepper(
                            "Daily Card Limit",
                            value:
                                Binding(
                                    get: {
                                        config
                                            .dailyCardLimit
                                    },
                                    set: { value in

                                        config
                                            .dailyCardLimit =
                                                value

                                        if config
                                            .minimumNewCards
                                            > value {

                                            config
                                                .minimumNewCards =
                                                    value
                                        }

                                        save()
                                    }
                                ),
                            in: 1...100
                        )
                        .labelsHidden()

                        Divider()

                        HStack {

                            Text(
                                "Minimum New Cards"
                            )

                            Spacer()

                            Text(
                                "\(config.minimumNewCards)"
                            )
                            .foregroundStyle(
                                .secondary
                            )
                            .monospacedDigit()
                        }

                        Stepper(
                            "Minimum New Cards",
                            value:
                                Binding(
                                    get: {
                                        config.minimumNewCards
                                    },
                                    set: {
                                        config.minimumNewCards =
                                            $0

                                        save()
                                    }
                                ),
                            in: 0...config.dailyCardLimit
                        )
                        .labelsHidden()
                    }
                }

                GroupBox(
                    "Card Types"
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
                    }
                }

                GroupBox(
                    "Target Display"
                ) {

                    VStack(
                        alignment: .leading,
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

                            displayOptions
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

                            displayOptions
                        }

                        Divider()

                        Toggle(
                            "Reading-only Recognition Answer",
                            isOn:
                                Binding(
                                    get: {
                                        config
                                            .readingOnlyAnswer
                                    },
                                    set: {
                                        config
                                            .readingOnlyAnswer =
                                                $0

                                        save()
                                    }
                                )
                        )

                        Text(
                            """
                            Recognition cards with a reading become Target → Reading. For example, 食べる → たべる. The source meaning is not shown. Recall cards are unchanged.
                            """
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
                    "Reading Hint"
                ) {

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Toggle(
                            "Show Reading Hint",
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

                        if config
                            .readingOnlyAnswer {

                            Text(
                                """
                                The Hint button is hidden on Reading-only Recognition cards because the reading is the answer.
                                """
                            )
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .secondary
                            )
                        }
                    }
                }

                GroupBox(
                    "Card Preview"
                ) {

                    ExampleCardView(
                        beforeAnswerDisplayMode:
                            config
                                .beforeAnswerDisplayMode,
                        afterAnswerDisplayMode:
                            config
                                .afterAnswerDisplayMode,
                        readingHintEnabled:
                            config
                                .readingHintEnabled,
                        readingOnlyAnswer:
                            config
                                .readingOnlyAnswer
                    )
                }

                GroupBox(
                    "Appearance"
                ) {

                    Picker(
                        "Appearance",
                        selection:
                            $appearancePreference
                    ) {

                        Text(
                            "System"
                        )
                        .tag(
                            "system"
                        )

                        Text(
                            "Light"
                        )
                        .tag(
                            "light"
                        )

                        Text(
                            "Dark"
                        )
                        .tag(
                            "dark"
                        )
                    }
                }

                GroupBox(
                    "Decks"
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

                GroupBox(
                    "Tags"
                ) {

                    let available =
                        availableTags(
                            config:
                                config
                        )

                    VStack(
                        spacing: 10
                    ) {

                        if available.isEmpty {

                            Text(
                                "No tags are available in the enabled decks."
                            )
                            .foregroundStyle(
                                .secondary
                            )

                        } else {

                            ForEach(
                                available
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

                versionFooter
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

    // MARK: - Display

    @ViewBuilder
    private var displayOptions:
        some View {

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

    // MARK: - Direction

    private func recognitionBinding(
        _ config:
            PyokoConfig
    ) -> Binding<Bool> {

        Binding(
            get: {

                config
                    .showRecognitionCards
            },
            set: { enabled in

                if !enabled
                    && !config
                        .showRecallCards {

                    return
                }

                config
                    .showRecognitionCards =
                        enabled

                save()
            }
        )
    }

    private func recallBinding(
        _ config:
            PyokoConfig
    ) -> Binding<Bool> {

        Binding(
            get: {

                config
                    .showRecallCards
            },
            set: { enabled in

                if !enabled
                    && !config
                        .showRecognitionCards {

                    return
                }

                config
                    .showRecallCards =
                        enabled

                save()
            }
        )
    }

    // MARK: - Decks

    private func isDeckSelected(
        _ deck: PyokoDeck,
        config: PyokoConfig
    ) -> Bool {

        (config.selectedDecks ?? [])
            .contains {
                $0.id == deck.id
            }
    }

    private func setDeckSelected(
        _ deck: PyokoDeck,
        selected: Bool,
        config: PyokoConfig
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

        removeUnavailableTags(
            config:
                config
        )

        save()
    }

    // MARK: - Tags

    private func availableTags(
        config: PyokoConfig
    ) -> [PyokoTag] {

        let selectedDeckIDs =
            Set(
                (config.selectedDecks ?? [])
                    .map(
                        \.id
                    )
            )

        let availableIDs =
            Set(
                decks
                    .filter {
                        selectedDeckIDs
                            .contains(
                                $0.id
                            )
                    }
                    .flatMap {
                        $0.cards ?? []
                    }
                    .flatMap {
                        $0.tags ?? []
                    }
                    .map(
                        \.id
                    )
            )

        return tags.filter {
            availableIDs.contains(
                $0.id
            )
        }
    }

    private func isTagSelected(
        _ tag: PyokoTag,
        config: PyokoConfig
    ) -> Bool {

        (config.selectedTags ?? [])
            .contains {
                $0.id == tag.id
            }
    }

    private func setTagSelected(
        _ tag: PyokoTag,
        selected: Bool,
        config: PyokoConfig
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

    private func removeUnavailableTags(
        config: PyokoConfig
    ) {

        let availableIDs =
            Set(
                availableTags(
                    config:
                        config
                )
                .map(
                    \.id
                )
            )

        config.selectedTags =
            (config.selectedTags ?? [])
                .filter {
                    availableIDs
                        .contains(
                            $0.id
                        )
                }
    }

    // MARK: - Config

    private func createConfigIfNeeded() {

        guard configs.isEmpty
        else {
            return
        }

        let config =
            PyokoConfig(
                selectedDecks:
                    decks,
                selectedTags:
                    []
            )

        modelContext.insert(
            config
        )

        save()
    }

    // MARK: - Version

    private var versionFooter:
        some View {

        let version =
            Bundle.main
                .object(
                    forInfoDictionaryKey:
                        "CFBundleShortVersionString"
                ) as? String
            ?? "-"

        let build =
            Bundle.main
                .object(
                    forInfoDictionaryKey:
                        "CFBundleVersion"
                ) as? String
            ?? "-"

        return Text(
            "Version \(version) (\(build))"
        )
        .font(
            .caption
        )
        .foregroundStyle(
            .secondary
        )
        .padding(
            .vertical,
            10
        )
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
