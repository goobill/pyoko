//
//  SentenceConfigView.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

import SwiftUI
import SwiftData

struct SentenceConfigView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query
    private var configs:
        [PyokoSentenceConfig]

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

                    sourceSection(
                        config
                    )

                    densitySection(
                        config
                    )

                    levelSection(
                        config
                    )

                    sentenceTypesSection(
                        config
                    )

                    directionSection(
                        config
                    )

                    displaySection(
                        config
                    )

                    countSection(
                        config
                    )

                    modelSection

                    startSection(
                        config
                    )

                } else {

                    ProgressView()
                        .frame(
                            maxWidth:
                                .infinity
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
                maxWidth:
                    .infinity
            )
            .padding(
                20
            )
        }
        .navigationTitle(
            "Practice Sentences"
        )
        .onAppear {

            createConfigIfNeeded()
        }
        .alert(
            "Sentence Practice Error",
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

    private var config:
        PyokoSentenceConfig? {

        configs.first
    }

    private var generator:
        SentenceGenerator {

        SentenceGenerator()
    }

    private var modelAvailability:
        SentenceModelAvailability {

        generator.availability
    }

    // MARK: - Vocabulary Source

    private func sourceSection(
        _ config:
            PyokoSentenceConfig
    ) -> some View {

        GroupBox(
            "Vocabulary"
        ) {

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

                Picker(
                    "Source",
                    selection:
                        sourceBinding(
                            config
                        )
                ) {

                    ForEach(
                        SentenceSource.allCases
                    ) { source in

                        Text(
                            source.title
                        )
                        .tag(
                            source
                        )
                    }
                }

                Text(
                    config
                        .source
                        .description
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )

                if config.source ==
                    .decks {

                    Divider()

                    deckSelection(
                        config
                    )
                }

                if config.source ==
                    .tags {

                    Divider()

                    tagSelection(
                        config
                    )
                }
            }
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Density

    private func densitySection(
        _ config:
            PyokoSentenceConfig
    ) -> some View {

        GroupBox(
            "Vocabulary per Sentence"
        ) {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                Picker(
                    "Density",
                    selection:
                        densityBinding(
                            config
                        )
                ) {

                    ForEach(
                        SentenceDensity.allCases
                    ) { density in

                        Text(
                            density.title
                        )
                        .tag(
                            density
                        )
                    }
                }
                .pickerStyle(
                    .segmented
                )

                Text(
                    config
                        .density
                        .description
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

    // MARK: - Level

    private func levelSection(
        _ config:
            PyokoSentenceConfig
    ) -> some View {

        GroupBox(
            "Complexity"
        ) {

            Picker(
                "Level",
                selection:
                    levelBinding(
                        config
                    )
            ) {

                ForEach(
                    SentenceLevel.allCases
                ) { level in

                    Text(
                        level.title
                    )
                    .tag(
                        level
                    )
                }
            }
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Sentence Types

    private func sentenceTypesSection(
        _ config:
            PyokoSentenceConfig
    ) -> some View {

        GroupBox(
            "Sentence Types"
        ) {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                ForEach(
                    SentenceType.allCases
                ) { type in

                    Toggle(
                        type.title,
                        isOn:
                            sentenceTypeBinding(
                                type,
                                config:
                                    config
                            )
                    )
                }

                Text(
                    "At least one sentence type must remain enabled."
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

    // MARK: - Direction

    private func directionSection(
        _ config:
            PyokoSentenceConfig
    ) -> some View {

        GroupBox(
            "Practice Direction"
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
                    "Japanese → English"
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
                    "English → Japanese"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )

                Text(
                    "At least one direction must remain enabled."
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

    // MARK: - Display

    private func displaySection(
        _ config:
            PyokoSentenceConfig
    ) -> some View {

        GroupBox(
            "Japanese Display"
        ) {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                Picker(
                    "Display",
                    selection:
                        displayBinding(
                            config
                        )
                ) {

                    ForEach(
                        SentenceDisplay.allCases
                    ) { display in

                        Text(
                            display.title
                        )
                        .tag(
                            display
                        )
                    }
                }
                .pickerStyle(
                    .segmented
                )

                Text(
                    "This only changes presentation. Every generated sentence still stores both Japanese and hiragana."
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

    // MARK: - Count

    private func countSection(
        _ config:
            PyokoSentenceConfig
    ) -> some View {

        GroupBox(
            "Session"
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text(
                        "Number of Sentences"
                    )

                    Text(
                        "How many exercises to practise."
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
                        countBinding(
                            config
                        ),
                    in:
                        1...30
                ) {

                    Text(
                        "\(config.sentenceCount)"
                    )
                    .monospacedDigit()
                }
                .fixedSize()
            }
            .padding(
                .vertical,
                6
            )
        }
    }

    // MARK: - Model

    private var modelSection:
        some View {

        GroupBox(
            "On-device Model"
        ) {

            HStack(
                alignment: .top,
                spacing: 10
            ) {

                Image(
                    systemName:
                        modelAvailability
                            .isAvailable
                        ? "checkmark.circle.fill"
                        : "exclamationmark.circle"
                )
                .foregroundStyle(
                    modelAvailability
                        .isAvailable
                    ? Color.accentColor
                    : Color.secondary
                )

                Text(
                    modelAvailability.message
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

    // MARK: - Start

    @ViewBuilder
    private func startSection(
        _ config:
            PyokoSentenceConfig
    ) -> some View {

        if canStart(
            config
        ) {

            NavigationLink {

                SentenceView(
                    config:
                        config
                )

            } label: {

                Text(
                    "Start Practice"
                )
                .fontWeight(
                    .semibold
                )
                .frame(
                    maxWidth:
                        .infinity
                )
            }
            .buttonStyle(
                .borderedProminent
            )
            .controlSize(
                .large
            )

        } else {

            Button(
                "Start Practice"
            ) {}
            .buttonStyle(
                .borderedProminent
            )
            .controlSize(
                .large
            )
            .frame(
                maxWidth:
                    .infinity
            )
            .disabled(
                true
            )

            if let validationMessage =
                validationMessage(
                    config
                ) {

                Text(
                    validationMessage
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

    // MARK: - Decks

    private func deckSelection(
        _ config:
            PyokoSentenceConfig
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text(
                "Decks"
            )
            .font(
                .headline
            )

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
        }
    }

    // MARK: - Tags

    private func tagSelection(
        _ config:
            PyokoSentenceConfig
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack(
                spacing: 12
            ) {

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text(
                        "Tags"
                    )
                    .font(
                        .headline
                    )

                    if !tags.isEmpty {

                        Text(
                            tagSelectionText(
                                config
                            )
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

                if !tags.isEmpty {

                    Button(
                        "Select All"
                    ) {

                        selectAllTags(
                            config
                        )
                    }
                    .buttonStyle(
                        .borderless
                    )
                    .disabled(
                        areAllTagsSelected(
                            config
                        )
                    )

                    Button(
                        "Deselect All"
                    ) {

                        deselectAllTags(
                            config
                        )
                    }
                    .buttonStyle(
                        .borderless
                    )
                    .disabled(
                        selectedTagCount(
                            config
                        )
                        == 0
                    )
                }
            }

            if tags.isEmpty {

                Text(
                    "No tags are available."
                )
                .foregroundStyle(
                    .secondary
                )

            } else {

                Divider()

                ForEach(
                    tags
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

                if (config.selectedTags ?? [])
                    .isEmpty {

                    Text(
                        "Select at least one tag to practise sentences using Selected Tags."
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

    // MARK: - Creation

    private func createConfigIfNeeded() {

        do {

            let manager =
                SentenceManager(
                    modelContext:
                        modelContext
                )

            _ = try manager
                .ensureConfigExists()

        } catch {

            showError(
                error
            )
        }
    }

    // MARK: - Validation

    private func canStart(
        _ config:
            PyokoSentenceConfig
    ) -> Bool {

        guard
            modelAvailability.isAvailable,
            config.hasDirection,
            config.hasSentenceType
        else {

            return false
        }

        switch config.source {

        case .decks:

            return !(
                config
                    .selectedDecks
                ?? []
            )
            .isEmpty

        case .tags:

            return !(
                config
                    .selectedTags
                ?? []
            )
            .isEmpty

        case .random,
             .todaysReview:

            return true
        }
    }

    private func validationMessage(
        _ config:
            PyokoSentenceConfig
    ) -> String? {

        guard modelAvailability
            .isAvailable
        else {

            return modelAvailability
                .message
        }

        if !config.hasDirection {

            return
                "Enable Recognition or Recall."
        }

        if !config.hasSentenceType {

            return
                "Select at least one sentence type."
        }

        if config.source == .decks,
           (config.selectedDecks ?? [])
            .isEmpty {

            return
                "Select at least one deck."
        }

        if config.source == .tags,
           (config.selectedTags ?? [])
            .isEmpty {

            return
                "Select at least one tag."
        }

        return nil
    }

    // MARK: - Bindings

    private func sourceBinding(
        _ config:
            PyokoSentenceConfig
    ) -> Binding<SentenceSource> {

        Binding(
            get: {

                config.source
            },
            set: {

                config.source =
                    $0

                save()
            }
        )
    }

    private func densityBinding(
        _ config:
            PyokoSentenceConfig
    ) -> Binding<SentenceDensity> {

        Binding(
            get: {

                config.density
            },
            set: {

                config.density =
                    $0

                save()
            }
        )
    }

    private func levelBinding(
        _ config:
            PyokoSentenceConfig
    ) -> Binding<SentenceLevel> {

        Binding(
            get: {

                config.level
            },
            set: {

                config.level =
                    $0

                save()
            }
        )
    }

    private func displayBinding(
        _ config:
            PyokoSentenceConfig
    ) -> Binding<SentenceDisplay> {

        Binding(
            get: {

                config.display
            },
            set: {

                config.display =
                    $0

                save()
            }
        )
    }

    private func countBinding(
        _ config:
            PyokoSentenceConfig
    ) -> Binding<Int> {

        Binding(
            get: {

                config.sentenceCount
            },
            set: {

                config.sentenceCount =
                    min(
                        max(
                            $0,
                            1
                        ),
                        30
                    )

                save()
            }
        )
    }

    private func recognitionBinding(
        _ config:
            PyokoSentenceConfig
    ) -> Binding<Bool> {

        Binding(
            get: {

                config
                    .includeRecognition
            },
            set: { enabled in

                guard
                    enabled
                    || config
                        .includeRecall
                else {

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
            PyokoSentenceConfig
    ) -> Binding<Bool> {

        Binding(
            get: {

                config
                    .includeRecall
            },
            set: { enabled in

                guard
                    enabled
                    || config
                        .includeRecognition
                else {

                    return
                }

                config
                    .includeRecall =
                        enabled

                save()
            }
        )
    }

    private func sentenceTypeBinding(
        _ type:
            SentenceType,
        config:
            PyokoSentenceConfig
    ) -> Binding<Bool> {

        Binding(
            get: {

                isSentenceTypeEnabled(
                    type,
                    config:
                        config
                )
            },
            set: { enabled in

                if !enabled {

                    guard
                        config
                            .selectedSentenceTypes
                            .count > 1
                    else {

                        return
                    }
                }

                setSentenceType(
                    type,
                    enabled:
                        enabled,
                    config:
                        config
                )

                save()
            }
        )
    }

    private func deckBinding(
        _ deck:
            PyokoDeck,
        config:
            PyokoSentenceConfig
    ) -> Binding<Bool> {

        Binding(
            get: {

                (
                    config
                        .selectedDecks
                    ?? []
                )
                .contains {

                    $0.id ==
                        deck.id
                }
            },
            set: { enabled in

                var selected =
                    config
                        .selectedDecks
                    ?? []

                if enabled {

                    if !selected.contains(
                        where: {

                            $0.id ==
                                deck.id
                        }
                    ) {

                        selected.append(
                            deck
                        )
                    }

                } else {

                    selected.removeAll {

                        $0.id ==
                            deck.id
                    }
                }

                config
                    .selectedDecks =
                        selected

                save()
            }
        )
    }

    private func tagBinding(
        _ tag:
            PyokoTag,
        config:
            PyokoSentenceConfig
    ) -> Binding<Bool> {

        Binding(
            get: {

                (
                    config
                        .selectedTags
                    ?? []
                )
                .contains {

                    $0.id ==
                        tag.id
                }
            },
            set: { enabled in

                var selected =
                    config
                        .selectedTags
                    ?? []

                if enabled {

                    if !selected.contains(
                        where: {

                            $0.id ==
                                tag.id
                        }
                    ) {

                        selected.append(
                            tag
                        )
                    }

                } else {

                    selected.removeAll {

                        $0.id ==
                            tag.id
                    }
                }

                config
                    .selectedTags =
                        selected

                save()
            }
        )
    }

    // MARK: - Tag Bulk Selection

    private func selectedTagCount(
        _ config:
            PyokoSentenceConfig
    ) -> Int {

        let selectedIDs =
            Set(
                (config.selectedTags ?? [])
                    .map(
                        \.id
                    )
            )

        return tags
            .filter {

                selectedIDs
                    .contains(
                        $0.id
                    )
            }
            .count
    }

    private func areAllTagsSelected(
        _ config:
            PyokoSentenceConfig
    ) -> Bool {

        guard !tags.isEmpty
        else {

            return false
        }

        return selectedTagCount(
            config
        )
        == tags.count
    }

    private func tagSelectionText(
        _ config:
            PyokoSentenceConfig
    ) -> String {

        "\(selectedTagCount(config)) of \(tags.count) selected"
    }

    private func selectAllTags(
        _ config:
            PyokoSentenceConfig
    ) {

        config.selectedTags =
            tags

        save()
    }

    private func deselectAllTags(
        _ config:
            PyokoSentenceConfig
    ) {

        config.selectedTags =
            []

        save()
    }

    // MARK: - Sentence Types

    private func isSentenceTypeEnabled(
        _ type:
            SentenceType,
        config:
            PyokoSentenceConfig
    ) -> Bool {

        switch type {

        case .present:

            return config
                .includePresent

        case .past:

            return config
                .includePast

        case .future:

            return config
                .includeFuture

        case .connecting:

            return config
                .includeConnecting

        case .longer:

            return config
                .includeLonger
        }
    }

    private func setSentenceType(
        _ type:
            SentenceType,
        enabled:
            Bool,
        config:
            PyokoSentenceConfig
    ) {

        switch type {

        case .present:

            config
                .includePresent =
                    enabled

        case .past:

            config
                .includePast =
                    enabled

        case .future:

            config
                .includeFuture =
                    enabled

        case .connecting:

            config
                .includeConnecting =
                    enabled

        case .longer:

            config
                .includeLonger =
                    enabled
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

    private func showError(
        _ error:
            Error
    ) {

        errorMessage =
            error.localizedDescription

        showingError =
            true
    }
}
