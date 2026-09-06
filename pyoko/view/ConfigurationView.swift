import SwiftUI
import SwiftData

struct ConfigurationView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Query
    private var configurations:
        [PyokoConfiguration]
    
    @Query(sort: \PyokoDeck.name)
    private var sources:
        [PyokoDeck]
    
    @Query(sort: \PyokoTag.name)
    private var tags:
        [PyokoTag]
    
    // MARK: - Appearance
    
    @AppStorage("appearancePreference")
    private var appearancePreferenceRawValue =
        AppearancePreference.system.rawValue
    
    // MARK: - Review
    
    @State
    private var dailyCardLimit = 20
    
    @State
    private var showRecognitionCards = true
    
    @State
    private var showRecallCards = true
    
    @State
    private var readingHintEnabled = true
    
    // MARK: - Display
    
    @State
    private var beforeAnswerDisplayMode:
        TargetDisplayMode = TargetDisplayMode.target
    
    @State
    private var afterAnswerDisplayMode:
        TargetDisplayMode = TargetDisplayMode.targetAndReading
    
    // MARK: - Filters
    
    @State
    private var selectedSourceIDs:
        Set<UUID> = []
    
    @State
    private var selectedTagIDs:
        Set<UUID> = []
    
    // MARK: - State
    
    @State
    private var hasLoadedConfiguration = false
    
    @State
    private var isLoadingConfiguration = false
    
    @State
    private var showingError = false
    
    @State
    private var errorMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        
        ScrollView {
            
            VStack(
                alignment: .leading,
                spacing: 20
            ) {
                
                autoSaveMessage
                
                studySection
                
                cardTypeSection
                
                hintSection
                
                displaySection
                
                previewSection
                
                deckSection
                
                tagSection
                
                appearanceSection
            }
            .padding()
            .frame(
                maxWidth: 760,
                alignment: .leading
            )
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )
        }
        .navigationTitle(
            "Configuration"
        )
        .onAppear {
            loadConfigurationIfNeeded()
        }
        .onChange(
            of: dailyCardLimit
        ) { _, _ in
            autoSaveConfiguration()
        }
        .onChange(
            of: showRecognitionCards
        ) { _, _ in
            autoSaveConfiguration()
        }
        .onChange(
            of: showRecallCards
        ) { _, _ in
            autoSaveConfiguration()
        }
        .onChange(
            of: readingHintEnabled
        ) { _, _ in
            autoSaveConfiguration()
        }
        .onChange(
            of: beforeAnswerDisplayMode
        ) { _, _ in
            autoSaveConfiguration()
        }
        .onChange(
            of: afterAnswerDisplayMode
        ) { _, _ in
            autoSaveConfiguration()
        }
        .onChange(
            of: selectedSourceIDs
        ) { _, _ in
            
            pruneUnavailableTags()
            
            autoSaveConfiguration()
        }
        .onChange(
            of: selectedTagIDs
        ) { _, _ in
            autoSaveConfiguration()
        }
        .alert(
            "Configuration Error",
            isPresented: $showingError
        ) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Autosave Message
    
    private var autoSaveMessage:
        some View {
        
        Label(
            "Changes are saved automatically",
            systemImage:
                "checkmark.circle"
        )
        .font(.caption)
        .foregroundStyle(
            .secondary
        )
    }
    
    // MARK: - Study
    
    private var studySection:
        some View {
        
        GroupBox("Study") {
            
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                
                Stepper(
                    value: $dailyCardLimit,
                    in: 1...100
                ) {
                    
                    HStack {
                        
                        Text(
                            "Daily Card Limit"
                        )
                        
                        Spacer()
                        
                        Text(
                            dailyCardLimit
                                .formatted()
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
                
                Text(
                    "The maximum number of cards added to a new daily review session."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
    
    // MARK: - Card Types
    
    private var cardTypeSection:
        some View {
        
        GroupBox(
            "Review Card Types"
        ) {
            
            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    
                    Toggle(
                        "Recognition",
                        isOn:
                            $showRecognitionCards
                    )
                    .disabled(
                        showRecognitionCards &&
                        !showRecallCards
                    )
                    
                    Text(
                        "Target → Source"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                    
                    Text(
                        "Example: 食べる → to eat"
                    )
                    .font(.caption)
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
                            $showRecallCards
                    )
                    .disabled(
                        showRecallCards &&
                        !showRecognitionCards
                    )
                    
                    Text(
                        "Source → Target"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                    
                    Text(
                        "Example: to eat → 食べる"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
                
                Text(
                    "At least one card type must remain enabled."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
    
    // MARK: - Hint
    
    private var hintSection:
        some View {
        
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
                        $readingHintEnabled
                )
                
                Text(
                    "When enabled, review cards with a reading can show a hint before the answer is revealed."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
    
    // MARK: - Display
    
    private var displaySection:
        some View {
        
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
                        $beforeAnswerDisplayMode
                ) {
                    
                    ForEach(
                        TargetDisplayMode
                            .allCases,
                        id: \.self
                    ) { mode in
                        
                        Text(
                            mode.title
                        )
                        .tag(mode)
                    }
                }
                
                Picker(
                    "After Answer",
                    selection:
                        $afterAnswerDisplayMode
                ) {
                    
                    ForEach(
                        TargetDisplayMode
                            .allCases,
                        id: \.self
                    ) { mode in
                        
                        Text(
                            mode.title
                        )
                        .tag(mode)
                    }
                }
                
                Text(
                    "Target shows the target-language text. Reading shows its optional reading. Target + Reading shows both. If no reading exists, Pyoko uses the target text."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
    
    // MARK: - Preview
    
    private var previewSection:
        some View {
        
        GroupBox("Example") {
            
            ExampleCardView(
                beforeAnswerDisplayMode:
                    beforeAnswerDisplayMode,
                afterAnswerDisplayMode:
                    afterAnswerDisplayMode
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
    
    // MARK: - Decks
    
    private var deckSection:
        some View {
        
        GroupBox("Decks") {
            
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                
                if sources.isEmpty {
                    
                    Text(
                        "No decks are installed."
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    
                    NavigationLink(
                        "Manage Decks"
                    ) {
                        DecksView()
                    }
                    
                } else {
                    
                    HStack {
                        
                        Text(
                            "\(selectedSourceIDs.count) of \(sources.count) selected"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                        
                        Spacer()
                        
                        Button(
                            "Select All"
                        ) {
                            
                            selectedSourceIDs =
                                Set(
                                    sources.map(\.id)
                                )
                        }
                    }
                    
                    Divider()
                    
                    ForEach(
                        sources
                    ) { source in
                        
                        SourceSelectionRow(
                            source: source,
                            isSelected:
                                selectedSourceIDs
                                    .contains(
                                        source.id
                                    )
                        ) {
                            toggleSource(
                                source
                            )
                        }
                    }
                    
                    Text(
                        "Select which decks should be included when a new review session is created."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
    
    // MARK: - Tags
    
    private var tagSection:
        some View {
        
        GroupBox("Tags") {
            
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                
                if selectedSourceIDs
                    .isEmpty {
                    
                    Text(
                        "Select a deck before choosing tags."
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    
                } else if availableTags
                    .isEmpty {
                    
                    Text(
                        "No tags are available for the selected decks."
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    
                } else {
                    
                    HStack {
                        
                        Button(
                            "Select All"
                        ) {
                            
                            selectedTagIDs =
                                Set(
                                    availableTags
                                        .map(\.id)
                                )
                        }
                        
                        Spacer()
                        
                        Button(
                            "Clear Filter"
                        ) {
                            
                            selectedTagIDs
                                .removeAll()
                        }
                    }
                    
                    Divider()
                    
                    ForEach(
                        availableTags
                    ) { tag in
                        
                        TagSelectionRow(
                            tag: tag,
                            isSelected:
                                selectedTagIDs
                                    .contains(
                                        tag.id
                                    )
                        ) {
                            toggleTag(tag)
                        }
                    }
                    
                    Text(
                        "No selected tags means all tags from the selected decks are included."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
    
    // MARK: - Appearance
    
    private var appearanceSection:
        some View {
        
        GroupBox("Appearance") {
            
            VStack(
                alignment: .leading,
                spacing: 8
            ) {
                
                Picker(
                    "Theme",
                    selection:
                        appearanceSelection
                ) {
                    
                    ForEach(
                        AppearancePreference
                            .allCases
                    ) { appearance in
                        
                        Text(
                            appearance.title
                        )
                        .tag(appearance)
                    }
                }
                
                #if os(macOS)
                .pickerStyle(.menu)
                #endif
                
                Text(
                    "System follows the appearance selected on your device."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
    
    // MARK: - Appearance Binding
    
    private var appearanceSelection:
        Binding<AppearancePreference> {
        
        Binding(
            get: {
                
                AppearancePreference(
                    rawValue:
                        appearancePreferenceRawValue
                ) ?? AppearancePreference.system
            },
            set: { appearance in
                
                appearancePreferenceRawValue =
                    appearance.rawValue
            }
        )
    }
    
    // MARK: - Available Tags
    
    private var availableTags:
        [PyokoTag] {
        
        guard
            !selectedSourceIDs
                .isEmpty
        else {
            return []
        }
        
        return tags.filter { tag in
            
            guard let cards =
                tag.cards
            else {
                return false
            }
            
            return cards.contains {
                card in
                
                guard
                    let sourceID =
                        card.deck?.id
                else {
                    return false
                }
                
                return selectedSourceIDs
                    .contains(
                        sourceID
                    )
            }
        }
    }
    
    // MARK: - Loading
    
    private func loadConfigurationIfNeeded() {
        
        guard
            !hasLoadedConfiguration
        else {
            return
        }
        
        isLoadingConfiguration =
            true
        
        if let configuration =
            configurations.first {
            
            dailyCardLimit =
                configuration.dailyCardLimit
            
            showRecognitionCards =
                configuration
                    .showRecognitionCards
            
            showRecallCards =
                configuration
                    .showRecallCards
            
            readingHintEnabled =
                configuration
                    .readingHintEnabled
            
            beforeAnswerDisplayMode =
                configuration
                    .beforeAnswerDisplayMode
            
            afterAnswerDisplayMode =
                configuration
                    .afterAnswerDisplayMode
            
            selectedSourceIDs =
                Set(
                    configuration
                        .sources
                        .map(\.id)
                )
            
            selectedTagIDs =
                Set(
                    configuration
                        .tags
                        .map(\.id)
                )
            
        } else {
            
            dailyCardLimit = 20
            
            showRecognitionCards =
                true
            
            showRecallCards =
                true
            
            readingHintEnabled =
                true
            
            beforeAnswerDisplayMode =
                TargetDisplayMode.target
            
            afterAnswerDisplayMode =
                TargetDisplayMode
                    .targetAndReading
            
            selectedSourceIDs =
                Set(
                    sources.map(\.id)
                )
            
            selectedTagIDs = []
        }
        
        pruneUnavailableTags()
        
        hasLoadedConfiguration =
            true
        
        isLoadingConfiguration =
            false
    }
    
    // MARK: - Deck Selection
    
    private func toggleSource(
        _ source:
            PyokoDeck
    ) {
        
        if selectedSourceIDs
            .contains(
                source.id
            ) {
            
            guard
                selectedSourceIDs.count > 1
            else {
                
                errorMessage =
                    "At least one deck must remain selected."
                
                showingError =
                    true
                
                return
            }
            
            selectedSourceIDs
                .remove(
                    source.id
                )
            
        } else {
            
            selectedSourceIDs
                .insert(
                    source.id
                )
        }
    }
    
    // MARK: - Tag Selection
    
    private func toggleTag(
        _ tag:
            PyokoTag
    ) {
        
        if selectedTagIDs
            .contains(
                tag.id
            ) {
            
            selectedTagIDs
                .remove(
                    tag.id
                )
            
        } else {
            
            selectedTagIDs
                .insert(
                    tag.id
                )
        }
    }
    
    private func pruneUnavailableTags() {
        
        let availableIDs =
            Set(
                availableTags
                    .map(\.id)
            )
        
        selectedTagIDs =
            selectedTagIDs
                .intersection(
                    availableIDs
                )
    }
    
    // MARK: - Auto Save
    
    private func autoSaveConfiguration() {
        
        guard
            hasLoadedConfiguration,
            !isLoadingConfiguration
        else {
            return
        }
        
        guard
            showRecognitionCards ||
            showRecallCards
        else {
            return
        }
        
        guard
            !selectedSourceIDs
                .isEmpty
        else {
            return
        }
        
        let configuration:
            PyokoConfiguration
        
        if let existing =
            configurations.first {
            
            configuration =
                existing
            
        } else {
            
            let newConfiguration =
                PyokoConfiguration()
            
            modelContext.insert(
                newConfiguration
            )
            
            configuration =
                newConfiguration
        }
        
        configuration.dailyCardLimit =
            dailyCardLimit
        
        configuration.showRecognitionCards =
            showRecognitionCards
        
        configuration.showRecallCards =
            showRecallCards
        
        configuration.readingHintEnabled =
            readingHintEnabled
        
        configuration.beforeAnswerDisplayMode =
            beforeAnswerDisplayMode
        
        configuration.afterAnswerDisplayMode =
            afterAnswerDisplayMode
        
        configuration.selectedSources =
            sources.filter {
                
                selectedSourceIDs
                    .contains(
                        $0.id
                    )
            }
        
        configuration.selectedTags =
            availableTags.filter {
                
                selectedTagIDs
                    .contains(
                        $0.id
                    )
            }
        
        do {
            
            try modelContext.save()
            
        } catch {
            
            errorMessage =
                error.localizedDescription
            
            showingError =
                true
        }
    }
}

// MARK: - Deck Row

private struct SourceSelectionRow:
    View {
    
    let source:
        PyokoDeck
    
    let isSelected:
        Bool
    
    let action:
        () -> Void
    
    var body: some View {
        
        Button(
            action: action
        ) {
            
            HStack {
                
                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    
                    Text(
                        source.name
                    )
                    .foregroundStyle(
                        .primary
                    )
                    
                    Text(
                        "\(source.vocabularyCount.formatted()) vocabulary"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
                
                Spacer()
                
                if isSelected {
                    
                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .foregroundStyle(
                        Color.accentColor
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
            }
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(
            .plain
        )
    }
}

// MARK: - Tag Row

private struct TagSelectionRow:
    View {
    
    let tag:
        PyokoTag
    
    let isSelected:
        Bool
    
    let action:
        () -> Void
    
    var body: some View {
        
        Button(
            action: action
        ) {
            
            HStack {
                
                Text(
                    tag.name
                )
                .foregroundStyle(
                    .primary
                )
                
                Spacer()
                
                if isSelected {
                    
                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .foregroundStyle(
                        Color.accentColor
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
            }
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(
            .plain
        )
    }
}
