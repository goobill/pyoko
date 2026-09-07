//
//  SentenceConfigurationView.swift
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
    private var configurations:
        [PyokoSentenceConfiguration]

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

                if let configuration {

                    sourceSection(
                        configuration
                    )

                    densitySection(
                        configuration
                    )

                    levelSection(
                        configuration
                    )

                    sentenceTypesSection(
                        configuration
                    )

                    directionSection(
                        configuration
                    )

                    displaySection(
                        configuration
                    )

                    countSection(
                        configuration
                    )

                    modelSection

                    startSection(
                        configuration
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

            createConfigurationIfNeeded()
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

    private var configuration:
        PyokoSentenceConfiguration? {

        configurations.first
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
        _ configuration:
            PyokoSentenceConfiguration
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
                            configuration
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
                    configuration
                        .source
                        .description
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )

                if configuration.source ==
                    .decks {

                    Divider()

                    deckSelection(
                        configuration
                    )
                }

                if configuration.source ==
                    .tags {

                    Divider()

                    tagSelection(
                        configuration
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
        _ configuration:
            PyokoSentenceConfiguration
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
                            configuration
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
                    configuration
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
        _ configuration:
            PyokoSentenceConfiguration
    ) -> some View {

        GroupBox(
            "Complexity"
        ) {

            Picker(
                "Level",
                selection:
                    levelBinding(
                        configuration
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
        _ configuration:
            PyokoSentenceConfiguration
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
                                configuration:
                                    configuration
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
        _ configuration:
            PyokoSentenceConfiguration
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
                            configuration
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
                            configuration
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
        _ configuration:
            PyokoSentenceConfiguration
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
                            configuration
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
        _ configuration:
            PyokoSentenceConfiguration
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
                            configuration
                        ),
                    in:
                        1...30
                ) {

                    Text(
                        "\(configuration.sentenceCount)"
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
        _ configuration:
            PyokoSentenceConfiguration
    ) -> some View {

        if canStart(
            configuration
        ) {

            NavigationLink {

                SentenceView(
                    configuration:
                        configuration
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
                    configuration
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
        _ configuration:
            PyokoSentenceConfiguration
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
        }
    }

    // MARK: - Tags

    private func tagSelection(
        _ configuration:
            PyokoSentenceConfiguration
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text(
                "Tags"
            )
            .font(
                .headline
            )

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
                            tagBinding(
                                tag,
                                configuration:
                                    configuration
                            )
                    )
                }
            }
        }
    }

    // MARK: - Creation

    private func createConfigurationIfNeeded() {

        do {

            let manager =
                SentenceManager(
                    modelContext:
                        modelContext
                )

            _ = try manager
                .ensureConfigurationExists()

        } catch {

            showError(
                error
            )
        }
    }

    // MARK: - Validation

    private func canStart(
        _ configuration:
            PyokoSentenceConfiguration
    ) -> Bool {

        guard
            modelAvailability.isAvailable,
            configuration.hasDirection,
            configuration.hasSentenceType
        else {
            return false
        }

        switch configuration.source {

        case .decks:
            return !(
                configuration
                    .selectedDecks
                ?? []
            )
            .isEmpty

        case .tags:
            return !(
                configuration
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
        _ configuration:
            PyokoSentenceConfiguration
    ) -> String? {

        guard modelAvailability.isAvailable else {
            return modelAvailability.message
        }

        if !configuration.hasDirection {
            return "Enable Recognition or Recall."
        }

        if !configuration.hasSentenceType {
            return "Select at least one sentence type."
        }

        if
            configuration.source == .decks,
            (configuration.selectedDecks ?? [])
                .isEmpty {

            return "Select at least one deck."
        }

        if
            configuration.source == .tags,
            (configuration.selectedTags ?? [])
                .isEmpty {

            return "Select at least one tag."
        }

        return nil
    }

    // MARK: - Bindings

    private func sourceBinding(
        _ configuration:
            PyokoSentenceConfiguration
    ) -> Binding<SentenceSource> {

        Binding(
            get: {
                configuration.source
            },
            set: {
                configuration.source =
                    $0

                save()
            }
        )
    }

    private func densityBinding(
        _ configuration:
            PyokoSentenceConfiguration
    ) -> Binding<SentenceDensity> {

        Binding(
            get: {
                configuration.density
            },
            set: {
                configuration.density =
                    $0

                save()
            }
        )
    }

    private func levelBinding(
        _ configuration:
            PyokoSentenceConfiguration
    ) -> Binding<SentenceLevel> {

        Binding(
            get: {
                configuration.level
            },
            set: {
                configuration.level =
                    $0

                save()
            }
        )
    }

    private func displayBinding(
        _ configuration:
            PyokoSentenceConfiguration
    ) -> Binding<SentenceDisplay> {

        Binding(
            get: {
                configuration.display
            },
            set: {
                configuration.display =
                    $0

                save()
            }
        )
    }

    private func countBinding(
        _ configuration:
            PyokoSentenceConfiguration
    ) -> Binding<Int> {

        Binding(
            get: {
                configuration.sentenceCount
            },
            set: {

                configuration.sentenceCount =
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
        _ configuration:
            PyokoSentenceConfiguration
    ) -> Binding<Bool> {

        Binding(
            get: {
                configuration
                    .includeRecognition
            },
            set: { enabled in

                guard
                    enabled
                    || configuration
                        .includeRecall
                else {
                    return
                }

                configuration
                    .includeRecognition =
                    enabled

                save()
            }
        )
    }

    private func recallBinding(
        _ configuration:
            PyokoSentenceConfiguration
    ) -> Binding<Bool> {

        Binding(
            get: {
                configuration
                    .includeRecall
            },
            set: { enabled in

                guard
                    enabled
                    || configuration
                        .includeRecognition
                else {
                    return
                }

                configuration
                    .includeRecall =
                    enabled

                save()
            }
        )
    }

    private func sentenceTypeBinding(
        _ type:
            SentenceType,
        configuration:
            PyokoSentenceConfiguration
    ) -> Binding<Bool> {

        Binding(
            get: {

                isSentenceTypeEnabled(
                    type,
                    configuration:
                        configuration
                )
            },
            set: { enabled in

                if !enabled {

                    guard
                        configuration
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
                    configuration:
                        configuration
                )

                save()
            }
        )
    }

    private func deckBinding(
        _ deck:
            PyokoDeck,
        configuration:
            PyokoSentenceConfiguration
    ) -> Binding<Bool> {

        Binding(
            get: {

                (
                    configuration
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
                    configuration
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

                configuration
                    .selectedDecks =
                    selected

                save()
            }
        )
    }

    private func tagBinding(
        _ tag:
            PyokoTag,
        configuration:
            PyokoSentenceConfiguration
    ) -> Binding<Bool> {

        Binding(
            get: {

                (
                    configuration
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
                    configuration
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

                configuration
                    .selectedTags =
                    selected

                save()
            }
        )
    }

    // MARK: - Sentence Types

    private func isSentenceTypeEnabled(
        _ type:
            SentenceType,
        configuration:
            PyokoSentenceConfiguration
    ) -> Bool {

        switch type {

        case .present:
            return configuration
                .includePresent

        case .past:
            return configuration
                .includePast

        case .future:
            return configuration
                .includeFuture

        case .connecting:
            return configuration
                .includeConnecting

        case .longer:
            return configuration
                .includeLonger
        }
    }

    private func setSentenceType(
        _ type:
            SentenceType,
        enabled:
            Bool,
        configuration:
            PyokoSentenceConfiguration
    ) {

        switch type {

        case .present:
            configuration
                .includePresent =
                enabled

        case .past:
            configuration
                .includePast =
                enabled

        case .future:
            configuration
                .includeFuture =
                enabled

        case .connecting:
            configuration
                .includeConnecting =
                enabled

        case .longer:
            configuration
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
