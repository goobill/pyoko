import SwiftUI
import SwiftData

struct ConfigurationView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query
    private var configurations:
        [PyokoConfiguration]

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

                if let configuration {

                    dailyReviewSection(
                        configuration
                    )

                    cardTypesSection(
                        configuration
                    )

                    targetDisplaySection(
                        configuration
                    )

                    readingHintSection(
                        configuration
                    )

                    cardPreviewSection(
                        configuration
                    )

                    appearanceSection

                    decksSection(
                        configuration
                    )

                    tagsSection(
                        configuration
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
            "Configuration"
        )
        .onAppear {

            createConfigurationIfNeeded()
        }
        .alert(
            "Configuration Error",
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

    // MARK: - Configuration

    private var configuration:
        PyokoConfiguration? {

        configurations.first
    }

    private func createConfigurationIfNeeded() {

        do {

            _ = try deckManager
                .ensureReviewConfigurationExists()

        } catch {

            showError(
                error
            )
        }
    }

    // MARK: - Daily Review

    private func dailyReviewSection(
        _ configuration:
            PyokoConfiguration
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
                                configuration
                            ),
                        in:
                            1...100
                    ) {

                        Text(
                            "\(configuration.dailyCardLimit)"
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

                        if configuration
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
                                "Reserve at least \(configuration.minimumNewCards) places for new cards."
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
                                configuration
                            ),
                        in:
                            0...configuration.dailyCardLimit
                    ) {

                        Text(
                            "\(configuration.minimumNewCards)"
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
        _ configuration:
            PyokoConfiguration
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
                            configuration
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
                            configuration
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
        _ configuration:
            PyokoConfiguration
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
                            configuration
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
                            configuration
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
        _ configuration:
            PyokoConfiguration
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
                            configuration
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
        _ configuration:
            PyokoConfiguration
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
                        configuration
                            .beforeAnswerDisplayMode,
                    afterAnswerDisplayMode:
                        configuration
                            .afterAnswerDisplayMode,
                    readingHintEnabled:
                        configuration
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
        _ configuration:
            PyokoConfiguration
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
                                    configuration:
                                        configuration
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
        _ configuration:
            PyokoConfiguration
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
                                    configuration:
                                        configuration
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
            let configuration
        else {
            return []
        }

        var tagsByID:
            [UUID: PyokoTag] = [:]

        for deck in
            configuration.selectedDecks ??
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
        configuration:
            PyokoConfiguration
    ) -> Binding<Bool> {

        Binding(
            get: {

                deckManager
                    .isEnabledForReview(
                        deck,
                        configuration:
                            configuration
                    )
            },
            set: { enabled in

                do {

                    try deckManager
                        .setEnabledForReview(
                            deck,
                            enabled:
                                enabled,
                            configuration:
                                configuration
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
        configuration:
            PyokoConfiguration
    ) -> Binding<Bool> {

        Binding(
            get: {

                (
                    configuration
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
                    configuration
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

                configuration.selectedTags =
                    selectedTags

                save()
            }
        )
    }

    // MARK: - Daily Card Limit Binding

    private func dailyCardLimitBinding(
        _ configuration:
            PyokoConfiguration
    ) -> Binding<Int> {

        Binding(
            get: {

                configuration
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

                configuration.dailyCardLimit =
                    value

                configuration.minimumNewCards =
                    min(
                        configuration
                            .minimumNewCards,
                        value
                    )

                save()
            }
        )
    }

    // MARK: - Minimum New Cards Binding

    private func minimumNewCardsBinding(
        _ configuration:
            PyokoConfiguration
    ) -> Binding<Int> {

        Binding(
            get: {

                configuration
                    .minimumNewCards
            },
            set: { newValue in

                configuration.minimumNewCards =
                    min(
                        max(
                            newValue,
                            0
                        ),
                        configuration
                            .dailyCardLimit
                    )

                save()
            }
        )
    }

    // MARK: - Recognition Binding

    private func recognitionBinding(
        _ configuration:
            PyokoConfiguration
    ) -> Binding<Bool> {

        Binding(
            get: {

                configuration
                    .showRecognitionCards
            },
            set: { enabled in

                /*
                 Don't allow both Recognition
                 and Recall to be disabled.
                 */

                guard
                    enabled ||
                    configuration
                        .showRecallCards
                else {
                    return
                }

                configuration.showRecognitionCards =
                    enabled

                save()
            }
        )
    }

    // MARK: - Recall Binding

    private func recallBinding(
        _ configuration:
            PyokoConfiguration
    ) -> Binding<Bool> {

        Binding(
            get: {

                configuration
                    .showRecallCards
            },
            set: { enabled in

                guard
                    enabled ||
                    configuration
                        .showRecognitionCards
                else {
                    return
                }

                configuration.showRecallCards =
                    enabled

                save()
            }
        )
    }

    // MARK: - Before Answer Binding

    private func beforeAnswerDisplayBinding(
        _ configuration:
            PyokoConfiguration
    ) -> Binding<TargetDisplayMode> {

        Binding(
            get: {

                configuration
                    .beforeAnswerDisplayMode
            },
            set: { value in

                configuration.beforeAnswerDisplayMode =
                    value

                save()
            }
        )
    }

    // MARK: - After Answer Binding

    private func afterAnswerDisplayBinding(
        _ configuration:
            PyokoConfiguration
    ) -> Binding<TargetDisplayMode> {

        Binding(
            get: {

                configuration
                    .afterAnswerDisplayMode
            },
            set: { value in

                configuration.afterAnswerDisplayMode =
                    value

                save()
            }
        )
    }

    // MARK: - Reading Hint Binding

    private func readingHintBinding(
        _ configuration:
            PyokoConfiguration
    ) -> Binding<Bool> {

        Binding(
            get: {

                configuration
                    .readingHintEnabled
            },
            set: { enabled in

                configuration.readingHintEnabled =
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
