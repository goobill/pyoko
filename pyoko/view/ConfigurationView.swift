import SwiftUI
import SwiftData

struct ConfigurationView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Environment(\.dismiss)
    private var dismiss
    
    @Query
    private var configurations:
        [PyokoConfiguration]
    
    @Query(sort: \PyokoDataSource.name)
    private var sources:
        [PyokoDataSource]
    
    @Query(sort: \PyokoTag.name)
    private var tags:
        [PyokoTag]
    
    // MARK: - Review
    
    @State
    private var dailyCardLimit = 20
    
    @State
    private var showRecognitionCards = true
    
    @State
    private var showRecallCards = true
    
    // MARK: - Display
    
    @State
    private var beforeAnswerDisplayMode:
        TargetDisplayMode = .target
    
    @State
    private var afterAnswerDisplayMode:
        TargetDisplayMode = .targetAndReading
    
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
    private var showingError = false
    
    @State
    private var errorMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        
        configurationContent
            .navigationTitle(
                "Configuration"
            )
            .toolbar {
                
                ToolbarItem(
                    placement: .primaryAction
                ) {
                    
                    Button("Save") {
                        saveConfiguration()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                loadConfigurationIfNeeded()
            }
            .onChange(
                of: selectedSourceIDs
            ) { _, _ in
                
                pruneUnavailableTags()
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
    
    // MARK: - Platform Content
    
    @ViewBuilder
    private var configurationContent:
        some View {
        
        #if os(macOS)
        
        macOSContent
        
        #else
        
        iOSContent
        
        #endif
    }
    
    // MARK: - iOS
    
    #if os(iOS)
    
    private var iOSContent:
        some View {
        
        Form {
            
            studySection
            
            cardTypeSection
            
            displaySection
            
            previewSection
            
            sourceSection
            
            tagSection
        }
    }
    
    // MARK: Study
    
    private var studySection:
        some View {
        
        Section {
            
            Stepper(
                value: $dailyCardLimit,
                in: 1...100
            ) {
                
                HStack {
                    
                    Text("Daily Card Limit")
                    
                    Spacer()
                    
                    Text(
                        dailyCardLimit.formatted()
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
            
        } header: {
            
            Text("Study")
            
        } footer: {
            
            Text(
                "The maximum number of cards added to a new daily review session."
            )
        }
    }
    
    // MARK: Card Types
    
    private var cardTypeSection:
        some View {
        
        Section {
            
            Toggle(
                "Recognition",
                isOn:
                    $showRecognitionCards
            )
            
            Text(
                "Target → Source"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Toggle(
                "Recall",
                isOn:
                    $showRecallCards
            )
            
            Text(
                "Source → Target"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            
        } header: {
            
            Text("Review Card Types")
            
        } footer: {
            
            Text(
                "Choose which types of cards appear during reviews. At least one card type must be enabled."
            )
        }
    }
    
    // MARK: Display
    
    private var displaySection:
        some View {
        
        Section {
            
            Picker(
                "Before Answer",
                selection:
                    $beforeAnswerDisplayMode
            ) {
                
                ForEach(
                    TargetDisplayMode.allCases,
                    id: \.self
                ) { mode in
                    
                    Text(mode.title)
                        .tag(mode)
                }
            }
            
            Picker(
                "After Answer",
                selection:
                    $afterAnswerDisplayMode
            ) {
                
                ForEach(
                    TargetDisplayMode.allCases,
                    id: \.self
                ) { mode in
                    
                    Text(mode.title)
                        .tag(mode)
                }
            }
            
        } header: {
            
            Text("Target Display")
            
        } footer: {
            
            Text(
                "Target shows the target-language text. Reading shows the optional reading. Target + Reading shows both. If no reading exists, Pyoko displays the target text instead."
            )
        }
    }
    
    // MARK: Preview
    
    private var previewSection:
        some View {
        
        Section("Example") {
            
            ExampleCardView(
                beforeAnswerDisplayMode:
                    beforeAnswerDisplayMode,
                afterAnswerDisplayMode:
                    afterAnswerDisplayMode
            )
        }
    }
    
    // MARK: Sources
    
    private var sourceSection:
        some View {
        
        Section {
            
            if sources.isEmpty {
                
                Text(
                    "No data sources are installed."
                )
                .foregroundStyle(.secondary)
                
                NavigationLink(
                    "Manage Sources"
                ) {
                    SourceDataView()
                }
                
            } else {
                
                HStack {
                    
                    Button("Select All") {
                        
                        selectedSourceIDs =
                            Set(
                                sources.map(\.id)
                            )
                    }
                    .buttonStyle(.borderless)
                    
                    Spacer()
                    
                    Button("Clear") {
                        
                        selectedSourceIDs
                            .removeAll()
                    }
                    .buttonStyle(.borderless)
                }
                
                ForEach(sources) { source in
                    
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
            }
            
        } header: {
            
            Text("Sources")
            
        } footer: {
            
            Text(
                "Select the vocabulary sources that should be included in reviews."
            )
        }
    }
    
    // MARK: Tags
    
    private var tagSection:
        some View {
        
        Section {
            
            if selectedSourceIDs.isEmpty {
                
                Text(
                    "Select at least one source to choose tags."
                )
                .foregroundStyle(.secondary)
                
            } else if availableTags.isEmpty {
                
                Text(
                    "No tags are available for the selected sources."
                )
                .foregroundStyle(.secondary)
                
            } else {
                
                HStack {
                    
                    Button("Select All") {
                        
                        selectedTagIDs =
                            Set(
                                availableTags
                                    .map(\.id)
                            )
                    }
                    .buttonStyle(.borderless)
                    
                    Spacer()
                    
                    Button(
                        "Clear Filter"
                    ) {
                        
                        selectedTagIDs
                            .removeAll()
                    }
                    .buttonStyle(.borderless)
                }
                
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
            }
            
        } header: {
            
            Text("Tags")
            
        } footer: {
            
            Text(
                "Leaving all tags unselected includes every tag from the selected sources."
            )
        }
    }
    
    #endif
    
    // MARK: - macOS
    
    #if os(macOS)
    
    private var macOSContent:
        some View {
        
        ScrollView {
            
            VStack(
                alignment: .leading,
                spacing: 20
            ) {
                
                macStudySection
                
                macCardTypeSection
                
                macDisplaySection
                
                macPreviewSection
                
                macSourceSection
                
                macTagSection
            }
            .padding(24)
            .frame(
                maxWidth: 700,
                alignment: .leading
            )
        }
        .frame(
            minWidth: 500,
            minHeight: 500
        )
    }
    
    // MARK: Study
    
    private var macStudySection:
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
                .foregroundStyle(.secondary)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
    
    // MARK: Card Types
    
    private var macCardTypeSection:
        some View {
        
        GroupBox(
            "Review Card Types"
        ) {
            
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                
                Toggle(
                    "Recognition",
                    isOn:
                        $showRecognitionCards
                )
                
                Text(
                    "Target → Source"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
                
                Toggle(
                    "Recall",
                    isOn:
                        $showRecallCards
                )
                
                Text(
                    "Source → Target"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
                
                Text(
                    "Choose which types of cards appear during reviews. At least one card type must be enabled."
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
    
    // MARK: Display
    
    private var macDisplaySection:
        some View {
        
        GroupBox("Target Display") {
            
            VStack(
                alignment: .leading,
                spacing: 12
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
                        
                        Text(mode.title)
                            .tag(mode)
                    }
                }
                .pickerStyle(.menu)
                
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
                        
                        Text(mode.title)
                            .tag(mode)
                    }
                }
                .pickerStyle(.menu)
                
                Text(
                    "Target shows the target-language text. Reading shows the optional reading. Target + Reading shows both. If no reading exists, Pyoko displays the target text instead."
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
    
    // MARK: Preview
    
    private var macPreviewSection:
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
    
    // MARK: Sources
    
    private var macSourceSection:
        some View {
        
        GroupBox("Sources") {
            
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                
                if sources.isEmpty {
                    
                    Text(
                        "No data sources are installed."
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    
                    NavigationLink(
                        "Manage Sources"
                    ) {
                        SourceDataView()
                    }
                    
                } else {
                    
                    HStack {
                        
                        Button(
                            "Select All"
                        ) {
                            
                            selectedSourceIDs =
                                Set(
                                    sources
                                        .map(\.id)
                                )
                        }
                        
                        Button(
                            "Clear"
                        ) {
                            
                            selectedSourceIDs
                                .removeAll()
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
                        "Select the vocabulary sources that should be included in reviews."
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
    
    // MARK: Tags
    
    private var macTagSection:
        some View {
        
        GroupBox("Tags") {
            
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                
                if selectedSourceIDs
                    .isEmpty {
                    
                    Text(
                        "Select at least one source to choose tags."
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    
                } else if availableTags
                    .isEmpty {
                    
                    Text(
                        "No tags are available for the selected sources."
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
                        "Leaving all tags unselected includes every tag from the selected sources."
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
    
    #endif
    
    // MARK: - Available Tags
    
    private var availableTags:
        [PyokoTag] {
        
        guard
            !selectedSourceIDs.isEmpty
        else {
            return []
        }
        
        return tags.filter { tag in
            
            guard
                let cards = tag.cards
            else {
                return false
            }
            
            return cards.contains { card in
                
                guard
                    let sourceID =
                        card.source?.id
                else {
                    return false
                }
                
                return selectedSourceIDs
                    .contains(sourceID)
            }
        }
    }
    
    // MARK: - Validation
    
    private var canSave: Bool {
        
        guard
            !selectedSourceIDs.isEmpty
        else {
            return false
        }
        
        guard
            showRecognitionCards ||
            showRecallCards
        else {
            return false
        }
        
        return true
    }
    
    // MARK: - Load
    
    private func loadConfigurationIfNeeded() {
        
        guard
            !hasLoadedConfiguration
        else {
            return
        }
        
        hasLoadedConfiguration = true
        
        guard
            let configuration =
                configurations.first
        else {
            
            loadDefaultConfiguration()
            return
        }
        
        dailyCardLimit =
            configuration.dailyCardLimit
        
        showRecognitionCards =
            configuration
                .showRecognitionCards
        
        showRecallCards =
            configuration
                .showRecallCards
        
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
        
        pruneUnavailableTags()
    }
    
    private func loadDefaultConfiguration() {
        
        dailyCardLimit = 20
        
        showRecognitionCards = true
        
        showRecallCards = true
        
        beforeAnswerDisplayMode =
            .target
        
        afterAnswerDisplayMode =
            .targetAndReading
        
        selectedSourceIDs =
            Set(
                sources.map(\.id)
            )
        
        selectedTagIDs = []
    }
    
    // MARK: - Source Selection
    
    private func toggleSource(
        _ source: PyokoDataSource
    ) {
        
        if selectedSourceIDs
            .contains(source.id) {
            
            selectedSourceIDs
                .remove(source.id)
            
        } else {
            
            selectedSourceIDs
                .insert(source.id)
        }
    }
    
    // MARK: - Tag Selection
    
    private func toggleTag(
        _ tag: PyokoTag
    ) {
        
        if selectedTagIDs
            .contains(tag.id) {
            
            selectedTagIDs
                .remove(tag.id)
            
        } else {
            
            selectedTagIDs
                .insert(tag.id)
        }
    }
    
    private func pruneUnavailableTags() {
        
        let availableTagIDs =
            Set(
                availableTags
                    .map(\.id)
            )
        
        selectedTagIDs =
            selectedTagIDs
                .intersection(
                    availableTagIDs
                )
    }
    
    // MARK: - Save
    
    private func saveConfiguration() {
        
        guard
            showRecognitionCards ||
            showRecallCards
        else {
            
            errorMessage =
                "Enable at least one review card type."
            
            showingError = true
            
            return
        }
        
        guard
            !selectedSourceIDs.isEmpty
        else {
            
            errorMessage =
                "Select at least one data source."
            
            showingError = true
            
            return
        }
        
        let configuration:
            PyokoConfiguration
        
        if let existing =
            configurations.first {
            
            configuration = existing
            
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
        
        configuration.beforeAnswerDisplayMode =
            beforeAnswerDisplayMode
        
        configuration.afterAnswerDisplayMode =
            afterAnswerDisplayMode
        
        configuration.selectedSources =
            sources.filter {
                
                selectedSourceIDs
                    .contains($0.id)
            }
        
        configuration.selectedTags =
            availableTags.filter {
                
                selectedTagIDs
                    .contains($0.id)
            }
        
        do {
            
            try modelContext.save()
            
            dismiss()
            
        } catch {
            
            errorMessage =
                error.localizedDescription
            
            showingError = true
        }
    }
}

// MARK: - Source Row

private struct SourceSelectionRow:
    View {
    
    let source:
        PyokoDataSource
    
    let isSelected: Bool
    
    let action: () -> Void
    
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
        .buttonStyle(.plain)
    }
}

// MARK: - Tag Row

private struct TagSelectionRow:
    View {
    
    let tag: PyokoTag
    
    let isSelected: Bool
    
    let action: () -> Void
    
    var body: some View {
        
        Button(
            action: action
        ) {
            
            HStack {
                
                Text(tag.name)
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
        .buttonStyle(.plain)
    }
}
