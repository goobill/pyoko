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

    @Query(
        sort: \PyokoTag.name
    )
    private var tags:
        [PyokoTag]

    @AppStorage(
        "appearancePreference"
    )
    private var appearanceRawValue =
        AppearancePreference
            .system
            .rawValue

    @State
    private var configuration:
        PyokoConfiguration?

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                reviewLimitsSection

                cardTypesSection

                displaySection

                readingHintSection

                exampleSection

                appearanceSection

                decksSection

                tagsSection
                
                appVersionFooter
            }
            .frame(
                maxWidth: 700
            )
            .padding()
            .frame(
                maxWidth: .infinity
            )
        }
        .navigationTitle(
            "Configuration"
        )
        .task {

            createConfigurationIfNeeded()
        }
    }

    // MARK: - Daily Review

    private var reviewLimitsSection:
        some View {

        GroupBox(
            "Daily Review"
        ) {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                if let configuration {

                    HStack(
                        alignment: .top,
                        spacing: 20
                    ) {

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {

                            Text(
                                "Daily Card Limit"
                            )
                            .fontWeight(
                                .medium
                            )

                            Text(
                                "The maximum number of cards included in a daily review session."
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
                            in: 1...100
                        ) {

                            Text(
                                "\(configuration.dailyCardLimit)"
                            )
                            .monospacedDigit()
                        }
                        .fixedSize()
                    }

                    Divider()

                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {

                        HStack(
                            alignment: .top,
                            spacing: 20
                        ) {

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text(
                                    "Minimum New Cards"
                                )
                                .fontWeight(
                                    .medium
                                )

                                Text(
                                    "Reserve at least this many places in each daily session for new cards when enough eligible new cards are available. Set this to 0 if you do not want to guarantee any new cards."
                                )
                                .font(
                                    .caption
                                )
                                .foregroundStyle(
                                    .secondary
                                )
                                .fixedSize(
                                    horizontal:
                                        false,
                                    vertical:
                                        true
                                )
                            }

                            Spacer()

                            Stepper(
                                value:
                                    minimumNewCardsBinding(
                                        configuration
                                    ),
                                in:
                                    0...configuration
                                        .dailyCardLimit
                            ) {

                                Text(
                                    "\(configuration.minimumNewCards)"
                                )
                                .monospacedDigit()
                            }
                            .fixedSize()
                        }

                        if configuration
                            .minimumNewCards == 0 {

                            Label(
                                "No new cards are guaranteed. Review cards may use the full daily limit.",
                                systemImage:
                                    "info.circle"
                            )
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .secondary
                            )

                        } else {

                            Label(
                                "At least \(configuration.minimumNewCards) places are reserved for new cards when enough are available.",
                                systemImage:
                                    "info.circle"
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
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Card Types

    private var cardTypesSection:
        some View {

        GroupBox(
            "Card Types"
        ) {

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

                if let configuration {

                    VStack(
                        alignment: .leading,
                        spacing: 4
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

                        Text(
                            "Example: 食べる → to eat"
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }

                    Divider()

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

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
                            "Example: to eat → 食べる"
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }

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
            }
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Target Display

    private var displaySection:
        some View {

        GroupBox(
            "Target Display"
        ) {

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                if let configuration {

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Text(
                            "Before Answer"
                        )
                        .fontWeight(
                            .medium
                        )

                        Picker(
                            "Before Answer",
                            selection:
                                beforeAnswerBinding(
                                    configuration
                                )
                        ) {

                            ForEach(
                                TargetDisplayMode
                                    .allCases,
                                id: \.self
                            ) { mode in

                                Text(
                                    mode.title
                                )
                                .tag(
                                    mode
                                )
                            }
                        }
                        .labelsHidden()

                        Text(
                            "Controls how target-language text is displayed before the answer is revealed."
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }

                    Divider()

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Text(
                            "After Answer"
                        )
                        .fontWeight(
                            .medium
                        )

                        Picker(
                            "After Answer",
                            selection:
                                afterAnswerBinding(
                                    configuration
                                )
                        ) {

                            ForEach(
                                TargetDisplayMode
                                    .allCases,
                                id: \.self
                            ) { mode in

                                Text(
                                    mode.title
                                )
                                .tag(
                                    mode
                                )
                            }
                        }
                        .labelsHidden()

                        Text(
                            "Controls how target-language text is displayed after the answer is revealed."
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
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Reading Hint

    private var readingHintSection:
        some View {

        GroupBox(
            "Reading Hint"
        ) {

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                if let configuration {

                    Toggle(
                        "Enable Reading Hint",
                        isOn:
                            readingHintBinding(
                                configuration
                            )
                    )

                    Text(
                        "When a card has a reading, show a hint button that can reveal the reading before the full answer."
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Example

    private var exampleSection:
        some View {

        GroupBox(
            "Card Preview"
        ) {

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                if let configuration {

                    Text(
                        "Preview how your current display and reading-hint settings will look during review."
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
                            .allCases
                    ) { appearance in

                        Label(
                            appearance.title,
                            systemImage:
                                appearance
                                    .systemImage
                        )
                        .tag(
                            appearance
                        )
                    }
                }

                Text(
                    "Choose whether Pyoko follows your device appearance or always uses Light or Dark mode."
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

    private var decksSection:
        some View {

        GroupBox(
            "Decks"
        ) {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                if decks.isEmpty {

                    Text(
                        "No decks are installed."
                    )
                    .foregroundStyle(
                        .secondary
                    )

                } else if let configuration {

                    ForEach(
                        decks
                    ) { deck in

                        Toggle(
                            deck.name,
                            isOn:
                                deckBinding(
                                    deck,
                                    configuration:
                                        configuration
                                )
                        )
                    }
                }

                Text(
                    "Only cards from selected decks are included in review sessions. Newly imported decks are automatically selected."
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

    private var tagsSection:
        some View {

        GroupBox(
            "Tags"
        ) {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                if availableTags.isEmpty {

                    Text(
                        "No tags are available for the selected decks."
                    )
                    .foregroundStyle(
                        .secondary
                    )

                } else if let configuration {

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
                    "Selecting no tags means all tags are included."
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
    
    // MARK: - App Version

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

            return "Version \(version) (\(build))"

        case let (
            version?,
            nil
        ):

            return "Version \(version)"

        default:

            return "Version"
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

        let selectedDeckIDs =
            Set(
                (
                    configuration
                        .selectedDecks ??
                    []
                )
                .map(
                    \.id
                )
            )

        guard
            !selectedDeckIDs.isEmpty
        else {
            return []
        }

        let tagIDs =
            Set(
                decks
                    .filter {

                        selectedDeckIDs
                            .contains(
                                $0.id
                            )
                    }
                    .flatMap {

                        $0.cards ??
                        []
                    }
                    .flatMap {

                        $0.tags ??
                        []
                    }
                    .map(
                        \.id
                    )
            )

        return tags.filter {

            tagIDs.contains(
                $0.id
            )
        }
    }

    // MARK: - Configuration Creation

    private func createConfigurationIfNeeded() {

        if let existing =
            configurations.first {

            configuration =
                existing

            clampMinimumNewCards(
                existing
            )

            return
        }

        let newConfiguration =
            PyokoConfiguration(
                dailyCardLimit: 20,
                minimumNewCards: 0,
                beforeAnswerDisplayMode:
                    TargetDisplayMode.target,
                afterAnswerDisplayMode:
                    TargetDisplayMode.reading,
                showRecognitionCards:
                    true,
                showRecallCards:
                    true,
                readingHintEnabled:
                    true,
                selectedDecks:
                    decks,
                selectedTags:
                    []
            )

        modelContext.insert(
            newConfiguration
        )

        configuration =
            newConfiguration

        save()
    }

    // MARK: - Appearance Binding

    private var appearanceBinding:
        Binding<AppearancePreference> {

        Binding(
            get: {

                AppearancePreference(
                    rawValue:
                        appearanceRawValue
                ) ??
                AppearancePreference.system
            },
            set: { newValue in

                appearanceRawValue =
                    newValue.rawValue
            }
        )
    }

    // MARK: - Daily Limit

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

                configuration
                    .dailyCardLimit =
                        newValue

                clampMinimumNewCards(
                    configuration
                )

                save()
            }
        )
    }

    // MARK: - Minimum New Cards

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

                configuration
                    .minimumNewCards =
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

    // MARK: - Card Types

    private func recognitionBinding(
        _ configuration:
            PyokoConfiguration
    ) -> Binding<Bool> {

        Binding(
            get: {

                configuration
                    .showRecognitionCards
            },
            set: { newValue in

                guard
                    newValue ||
                    configuration
                        .showRecallCards
                else {
                    return
                }

                configuration
                    .showRecognitionCards =
                        newValue

                save()
            }
        )
    }

    private func recallBinding(
        _ configuration:
            PyokoConfiguration
    ) -> Binding<Bool> {

        Binding(
            get: {

                configuration
                    .showRecallCards
            },
            set: { newValue in

                guard
                    newValue ||
                    configuration
                        .showRecognitionCards
                else {
                    return
                }

                configuration
                    .showRecallCards =
                        newValue

                save()
            }
        )
    }

    // MARK: - Reading Hint

    private func readingHintBinding(
        _ configuration:
            PyokoConfiguration
    ) -> Binding<Bool> {

        Binding(
            get: {

                configuration
                    .readingHintEnabled
            },
            set: { newValue in

                configuration
                    .readingHintEnabled =
                        newValue

                save()
            }
        )
    }

    // MARK: - Display

    private func beforeAnswerBinding(
        _ configuration:
            PyokoConfiguration
    ) -> Binding<TargetDisplayMode> {

        Binding(
            get: {

                configuration
                    .beforeAnswerDisplayMode
            },
            set: { newValue in

                configuration
                    .beforeAnswerDisplayMode =
                        newValue

                save()
            }
        )
    }

    private func afterAnswerBinding(
        _ configuration:
            PyokoConfiguration
    ) -> Binding<TargetDisplayMode> {

        Binding(
            get: {

                configuration
                    .afterAnswerDisplayMode
            },
            set: { newValue in

                configuration
                    .afterAnswerDisplayMode =
                        newValue

                save()
            }
        )
    }

    // MARK: - Deck Binding

    private func deckBinding(
        _ deck: PyokoDeck,
        configuration:
            PyokoConfiguration
    ) -> Binding<Bool> {

        Binding(
            get: {

                (
                    configuration
                        .selectedDecks ??
                    []
                )
                .contains {

                    $0.id ==
                        deck.id
                }
            },
            set: { isSelected in

                var selectedDecks =
                    configuration
                        .selectedDecks ??
                    []

                if isSelected {

                    guard
                        !selectedDecks
                            .contains(
                                where: {

                                    $0.id ==
                                        deck.id
                                }
                            )
                    else {
                        return
                    }

                    selectedDecks
                        .append(
                            deck
                        )

                } else {

                    selectedDecks
                        .removeAll {

                            $0.id ==
                                deck.id
                        }
                }

                configuration
                    .selectedDecks =
                        selectedDecks

                removeUnavailableTags(
                    configuration
                )

                save()
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
            set: { isSelected in

                var selectedTags =
                    configuration
                        .selectedTags ??
                    []

                if isSelected {

                    guard
                        !selectedTags
                            .contains(
                                where: {

                                    $0.id ==
                                        tag.id
                                }
                            )
                    else {
                        return
                    }

                    selectedTags
                        .append(
                            tag
                        )

                } else {

                    selectedTags
                        .removeAll {

                            $0.id ==
                                tag.id
                        }
                }

                configuration
                    .selectedTags =
                        selectedTags

                save()
            }
        )
    }

    // MARK: - Validation

    private func clampMinimumNewCards(
        _ configuration:
            PyokoConfiguration
    ) {

        configuration
            .minimumNewCards =
                min(
                    max(
                        configuration
                            .minimumNewCards,
                        0
                    ),
                    max(
                        configuration
                            .dailyCardLimit,
                        1
                    )
                )
    }

    private func removeUnavailableTags(
        _ configuration:
            PyokoConfiguration
    ) {

        let availableTagIDs =
            Set(
                availableTags.map(
                    \.id
                )
            )

        configuration
            .selectedTags =
                (
                    configuration
                        .selectedTags ??
                    []
                )
                .filter {

                    availableTagIDs
                        .contains(
                            $0.id
                        )
                }
    }

    // MARK: - Save

    private func save() {

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to save configuration: \(error)"
            )
        }
    }
}
