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

    @AppStorage(
        "appearancePreference"
    )
    private var appearanceRawValue =
        AppearancePreference
            .system
            .rawValue

    @State
    private var showingError =
        false

    @State
    private var errorMessage =
        ""

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                if let config {

                    dailyReviewSection(
                        config
                    )

                    cardTypesSection(
                        config
                    )

                    targetDisplaySection(
                        config
                    )

                    readingHintSection(
                        config
                    )

                    cardPreviewSection(
                        config
                    )

                    appearanceSection

                    decksSection(
                        config
                    )

                    tagsSection(
                        config
                    )

                    appVersionFooter

                } else {

                    ProgressView()
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(
                            .top,
                            60
                        )
                }
            }
            .frame(
                maxWidth: 700,
                alignment: .leading
            )
            .frame(
                maxWidth: .infinity
            )
            .padding(
                20
            )
        }
        .navigationTitle(
            "Config"
        )
        .onAppear {

            createConfigIfNeeded()
        }
        .alert(
            "Config Error",
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
    }

    // MARK: - Manager

    private var deckManager:
        DeckManager {

        DeckManager(
            modelContext:
                modelContext
        )
    }

    // MARK: - Config

    private var config:
        PyokoConfig? {

        configs.first
    }

    private func createConfigIfNeeded() {

        do {

            _ = try deckManager
                .ensureReviewConfigExists()

        } catch {

            showError(
                error
            )
        }
    }

    // MARK: - Daily Review

    private func dailyReviewSection(
        _ config:
            PyokoConfig
    ) -> some View {

        GroupBox(
            "Daily Review"
        ) {

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                HStack {

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {

                        Text(
                            "Daily Card Limit"
                        )

                        Text(
                            "Maximum number of cards in each daily review."
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }

                    Spacer()

                    Stepper(
                        value:
                            dailyCardLimitBinding(
                                config
                            ),
                        in:
                            1...100
                    ) {

                        Text(
                            "\(config.dailyCardLimit)"
                        )
                        .monospacedDigit()
                    }
                    .fixedSize()
                }

                Divider()

                HStack {

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {

                        Text(
                            "Minimum New Cards"
                        )

                        if config
                            .minimumNewCards == 0 {

                            Text(
                                "New cards are not guaranteed."
                            )
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .secondary
                            )

                        } else {

                            Text(
                                "Reserve at least \(config.minimumNewCards) places for new cards."
                            )
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .secondary
                            )
                        }
                    }

                    Spacer()

                    Stepper(
                        value:
                            minimumNewCardsBinding(
                                config
                            ),
                        in:
                            0...config.dailyCardLimit
                    ) {

                        Text(
                            "\(config.minimumNewCards)"
                        )
                        .monospacedDigit()
                    }
                    .fixedSize()
                }

                Text(
                    "The daily card limit is never exceeded. New cards can still fill unused review capacity."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Card Types

    private func cardTypesSection(
        _ config:
            PyokoConfig
    ) -> some View {

        GroupBox(
            "Card Types"
        ) {

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                Toggle(
                    "Recognition",
                    isOn:
                        recognitionBinding(
                            config
                        )
                )

                Text(
                    "Target → Source"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )

                Divider()

                Toggle(
                    "Recall",
                    isOn:
                        recallBinding(
                            config
                        )
                )

                Text(
                    "Source → Target"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )

                Text(
                    "At least one card type must remain enabled."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Target Display

    private func targetDisplaySection(
        _ config:
            PyokoConfig
    ) -> some View {

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
                        beforeAnswerDisplayBinding(
                            config
                        )
                ) {

                    ForEach(
                        TargetDisplayMode.allCases,
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
                        afterAnswerDisplayBinding(
                            config
                        )
                ) {

                    ForEach(
                        TargetDisplayMode.allCases,
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

                Text(
                    "Choose whether the target, reading, or both are shown before and after revealing an answer."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Reading Hint

    private func readingHintSection(
        _ config:
            PyokoConfig
    ) -> some View {

        GroupBox(
            "Reading Hint"
        ) {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                Toggle(
                    "Enable Reading Hint",
                    isOn:
                        readingHintBinding(
                            config
                        )
                )

                Text(
                    "When a card has a reading, Hint can reveal it without showing the full answer."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Card Preview

    private func cardPreviewSection(
        _ config:
            PyokoConfig
    ) -> some View {

        GroupBox(
            "Card Preview"
        ) {

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                Text(
                    "Preview the current display and hint settings."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )

                ExampleCardView(
                    beforeAnswerDisplayMode:
                        config
                            .beforeAnswerDisplayMode,
                    afterAnswerDisplayMode:
                        config
                            .afterAnswerDisplayMode,
                    readingHintEnabled:
                        config
                            .readingHintEnabled
                )
            }
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Appearance

    private var appearanceSection:
        some View {

        GroupBox(
            "Appearance"
        ) {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                Picker(
                    "Theme",
                    selection:
                        appearanceBinding
                ) {

                    ForEach(
                        AppearancePreference
                            .allCases,
                        id: \.rawValue
                    ) { appearance in

                        Text(
                            appearance
                                .rawValue
                                .capitalized
                        )
                        .tag(
                            appearance
                        )
                    }
                }

                Text(
                    "Choose whether Pyoko follows the system appearance or always uses Light or Dark mode."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Decks

    private func decksSection(
        _ config:
            PyokoConfig
    ) -> some View {

        GroupBox(
            "Decks"
        ) {

            VStack(
                alignment: .leading,
                spacing: 12
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
                            isOn:
                                deckBinding(
                                    deck,
                                    config:
                                        config
                                )
                        ) {

                            VStack(
                                alignment: .leading,
                                spacing: 2
                            ) {

                                Text(
                                    deck.name
                                )

                                Text(
                                    "\(deck.vocabularyCount.formatted()) vocabulary"
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
                }

                Text(
                    "These switches are linked with Deck Management. Disabling a deck keeps it installed but excludes it from future review sessions."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Tags

    private func tagsSection(
        _ config:
            PyokoConfig
    ) -> some View {

        GroupBox(
            "Tags"
        ) {

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                if availableTags.isEmpty {

                    Text(
                        "No tags are available for the currently enabled decks."
                    )
                    .foregroundStyle(
                        .secondary
                    )

                } else {

                    ForEach(
                        availableTags
                    ) { tag in

                        Toggle(
                            tag.name,
                            isOn:
                                tagBinding(
                                    tag,
                                    config:
                                        config
                                )
                        )
                    }
                }

                Text(
                    "If no tags are selected, all tags from enabled decks are included."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Available Tags

    private var availableTags:
        [PyokoTag] {

        guard
            let config
        else {
            return []
        }

        var tagsByID:
            [UUID: PyokoTag] = [:]

        for deck in
            config.selectedDecks ??
            [] {

            for card in
                deck.cards ??
                [] {

                for tag in
                    card.tags ??
                    [] {

                    tagsByID[
                        tag.id
                    ] = tag
                }
            }
        }

        return tagsByID
            .values
            .sorted {

                $0.name
                    .localizedCaseInsensitiveCompare(
                        $1.name
                    ) ==
                    .orderedAscending
            }
    }

    // MARK: - Deck Binding

    private func deckBinding(
        _ deck: PyokoDeck,
        config:
            PyokoConfig
    ) -> Binding<Bool> {

        Binding(
            get: {

                deckManager
                    .isEnabledForReview(
                        deck,
                        config:
                            config
                    )
            },
            set: { enabled in

                do {

                    try deckManager
                        .setEnabledForReview(
                            deck,
                            enabled:
                                enabled,
                            config:
                                config
                        )

                } catch {

                    showError(
                        error
                    )
                }
            }
        )
    }

    // MARK: - Tag Binding

    private func tagBinding(
        _ tag: PyokoTag,
        config:
            PyokoConfig
    ) -> Binding<Bool> {

        Binding(
            get: {

                (
                    config
                        .selectedTags ??
                    []
                )
                .contains {

                    $0.id ==
                        tag.id
                }
            },
            set: { enabled in

                var selectedTags =
                    config
                        .selectedTags ??
                    []

                if enabled {

                    let alreadySelected =
                        selectedTags
                            .contains {

                                $0.id ==
                                    tag.id
                            }

                    if !alreadySelected {

                        selectedTags.append(
                            tag
                        )
                    }

                } else {

                    selectedTags.removeAll {

                        $0.id ==
                            tag.id
                    }
                }

                config.selectedTags =
                    selectedTags

                save()
            }
        )
    }

    // MARK: - Daily Card Limit Binding

    private func dailyCardLimitBinding(
        _ config:
            PyokoConfig
    ) -> Binding<Int> {

        Binding(
            get: {

                config
                    .dailyCardLimit
            },
            set: { newValue in

                let value =
                    min(
                        max(
                            newValue,
                            1
                        ),
                        100
                    )

                config.dailyCardLimit =
                    value

                config.minimumNewCards =
                    min(
                        config
                            .minimumNewCards,
                        value
                    )

                save()
            }
        )
    }

    // MARK: - Minimum New Cards Binding

    private func minimumNewCardsBinding(
        _ config:
            PyokoConfig
    ) -> Binding<Int> {

        Binding(
            get: {

                config
                    .minimumNewCards
            },
            set: { newValue in

                config.minimumNewCards =
                    min(
                        max(
                            newValue,
                            0
                        ),
                        config
                            .dailyCardLimit
                    )

                save()
            }
        )
    }

    // MARK: - Recognition Binding

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

                /*
                 Don't allow both Recognition
                 and Recall to be disabled.
                 */

                guard
                    enabled ||
                    config
                        .showRecallCards
                else {
                    return
                }

                config.showRecognitionCards =
                    enabled

                save()
            }
        )
    }

    // MARK: - Recall Binding

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

                guard
                    enabled ||
                    config
                        .showRecognitionCards
                else {
                    return
                }

                config.showRecallCards =
                    enabled

                save()
            }
        )
    }

    // MARK: - Before Answer Binding

    private func beforeAnswerDisplayBinding(
        _ config:
            PyokoConfig
    ) -> Binding<TargetDisplayMode> {

        Binding(
            get: {

                config
                    .beforeAnswerDisplayMode
            },
            set: { value in

                config.beforeAnswerDisplayMode =
                    value

                save()
            }
        )
    }

    // MARK: - After Answer Binding

    private func afterAnswerDisplayBinding(
        _ config:
            PyokoConfig
    ) -> Binding<TargetDisplayMode> {

        Binding(
            get: {

                config
                    .afterAnswerDisplayMode
            },
            set: { value in

                config.afterAnswerDisplayMode =
                    value

                save()
            }
        )
    }

    // MARK: - Reading Hint Binding

    private func readingHintBinding(
        _ config:
            PyokoConfig
    ) -> Binding<Bool> {

        Binding(
            get: {

                config
                    .readingHintEnabled
            },
            set: { enabled in

                config.readingHintEnabled =
                    enabled

                save()
            }
        )
    }

    // MARK: - Appearance

    private var appearanceBinding:
        Binding<AppearancePreference> {

        Binding(
            get: {

                AppearancePreference(
                    rawValue:
                        appearanceRawValue
                ) ??
                AppearancePreference
                    .system
            },
            set: { appearance in

                appearanceRawValue =
                    appearance.rawValue
            }
        )
    }

    // MARK: - Version

    private var appVersionFooter:
        some View {

        Text(
            appVersionText
        )
        .font(
            .caption
        )
        .foregroundStyle(
            .tertiary
        )
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .top,
            6
        )
        .padding(
            .bottom,
            12
        )
    }

    private var appVersionText:
        String {

        let version =
            Bundle.main.object(
                forInfoDictionaryKey:
                    "CFBundleShortVersionString"
            ) as? String

        let build =
            Bundle.main.object(
                forInfoDictionaryKey:
                    "CFBundleVersion"
            ) as? String

        switch (
            version,
            build
        ) {

        case let (
            version?,
            build?
        ):

            return
                "Version \(version) (\(build))"

        case let (
            version?,
            nil
        ):

            return
                "Version \(version)"

        default:

            return "Version"
        }
    }

    // MARK: - Save

    private func save() {

        do {

            try modelContext.save()

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
