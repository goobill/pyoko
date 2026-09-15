import SwiftUI
import SwiftData

struct ConfigView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \PyokoConfig.createdAt)
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
        .pyokoSurface()
        .navigationTitle(
            "Review Config"
        )
        .task {

            createConfigIfNeeded()
        }
        .alert(
            "Review Config",
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

                // MARK: Daily Review

                GroupBox(
                    "Session"
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

                                        config
                                            .minimumNewCards
                                    },
                                    set: {

                                        config
                                            .minimumNewCards =
                                                $0

                                        save()
                                    }
                                ),
                            in:
                                0...config
                                    .dailyCardLimit
                        )
                        .labelsHidden()
                    }
                }

                CardConfigView(
                    recognition: recognitionBinding(config),
                    recall: recallBinding(config),
                    before: Binding(get: { config.beforeAnswerDisplayMode }, set: { config.beforeAnswerDisplayMode = $0; save() }),
                    after: Binding(get: { config.afterAnswerDisplayMode }, set: { config.afterAnswerDisplayMode = $0; save() }),
                    hiraganaOnly: Binding(get: { config.readingOnlyAnswer }, set: { config.readingOnlyAnswer = $0; save() }),
                    hint: Binding(get: { config.readingHintEnabled }, set: { config.readingHintEnabled = $0; save() })
                )
                CardPreviewView(
                    quick: false, recognition: config.showRecognitionCards, recall: config.showRecallCards,
                    before: config.beforeAnswerDisplayMode, after: config.afterAnswerDisplayMode,
                    hiraganaOnly: config.readingOnlyAnswer, hint: config.readingHintEnabled
                )

                // MARK: Decks

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

                // MARK: Tags

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

                            HStack(
                                spacing: 12
                            ) {

                                Text(
                                    tagSelectionText(
                                        available:
                                            available,
                                        config:
                                            config
                                    )
                                )
                                .font(
                                    .caption
                                )
                                .foregroundStyle(
                                    .secondary
                                )

                                Spacer()

                                Button(
                                    "Select All"
                                ) {

                                    selectAllTags(
                                        available:
                                            available,
                                        config:
                                            config
                                    )
                                }
                                .buttonStyle(
                                    .borderless
                                )
                                .disabled(
                                    areAllTagsSelected(
                                        available:
                                            available,
                                        config:
                                            config
                                    )
                                )

                                Button(
                                    "Deselect All"
                                ) {

                                    deselectAllTags(
                                        available:
                                            available,
                                        config:
                                            config
                                    )
                                }
                                .buttonStyle(
                                    .borderless
                                )
                                .disabled(
                                    selectedAvailableTagCount(
                                        available:
                                            available,
                                        config:
                                            config
                                    )
                                    == 0
                                )
                            }

                            Divider()

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

                            if (config.selectedTags ?? [])
                                .isEmpty {

                                Text(
                                    """
                                    No tags selected means no tag filter. Cards from all tags in the enabled decks remain eligible.
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
        }.accessibilityIdentifier("config.scroll")
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
        _ deck:
            PyokoDeck,
        config:
            PyokoConfig
    ) -> Bool {

        (config.selectedDecks ?? [])
            .contains {

                $0.id == deck.id
            }
    }

    private func setDeckSelected(
        _ deck:
            PyokoDeck,
        selected:
            Bool,
        config:
            PyokoConfig
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

                $0.id
                    == deck.id
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
        config:
            PyokoConfig
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

            availableIDs
                .contains(
                    $0.id
                )
        }
    }

    private func isTagSelected(
        _ tag:
            PyokoTag,
        config:
            PyokoConfig
    ) -> Bool {

        (config.selectedTags ?? [])
            .contains {

                $0.id == tag.id
            }
    }

    private func setTagSelected(
        _ tag:
            PyokoTag,
        selected:
            Bool,
        config:
            PyokoConfig
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

                $0.id
                    == tag.id
            }
        }

        config.selectedTags =
            selectedTags

        save()
    }

    // MARK: Tag Bulk Selection

    private func selectedAvailableTagCount(
        available:
            [PyokoTag],
        config:
            PyokoConfig
    ) -> Int {

        let selectedIDs =
            Set(
                (config.selectedTags ?? [])
                    .map(
                        \.id
                    )
            )

        return available
            .filter {

                selectedIDs
                    .contains(
                        $0.id
                    )
            }
            .count
    }

    private func areAllTagsSelected(
        available:
            [PyokoTag],
        config:
            PyokoConfig
    ) -> Bool {

        guard !available.isEmpty
        else {
            return false
        }

        return selectedAvailableTagCount(
            available:
                available,
            config:
                config
        )
        == available.count
    }

    private func tagSelectionText(
        available:
            [PyokoTag],
        config:
            PyokoConfig
    ) -> String {

        let selected =
            selectedAvailableTagCount(
                available:
                    available,
                config:
                    config
            )

        return
            "\(selected) of \(available.count) selected"
    }

    private func selectAllTags(
        available:
            [PyokoTag],
        config:
            PyokoConfig
    ) {

        var selected =
            config.selectedTags
            ?? []

        let selectedIDs =
            Set(
                selected.map(
                    \.id
                )
            )

        for tag in available {

            if !selectedIDs
                .contains(
                    tag.id
                ) {

                selected.append(
                    tag
                )
            }
        }

        config.selectedTags =
            selected

        save()
    }

    private func deselectAllTags(
        available:
            [PyokoTag],
        config:
            PyokoConfig
    ) {

        let availableIDs =
            Set(
                available.map(
                    \.id
                )
            )

        config.selectedTags =
            (config.selectedTags ?? [])
                .filter {

                    !availableIDs
                        .contains(
                            $0.id
                        )
                }

        save()
    }

    private func removeUnavailableTags(
        config:
            PyokoConfig
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
