import SwiftUI
import SwiftData

struct ConfigurationView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Environment(\.dismiss)
    private var dismiss
    
    // MARK: - Stored Data
    
    @Query
    private var configurations: [PyokoConfiguration]
    
    @Query(
        sort: \PyokoDataSource.name
    )
    private var sources: [PyokoDataSource]
    
    @Query(
        sort: \PyokoTag.name
    )
    private var tags: [PyokoTag]
    
    // MARK: - Draft Configuration
    
    @State private var dailyCardLimit = 20
    
    @State private var beforeAnswerDisplayMode:
        TargetDisplayMode = .target
    
    @State private var afterAnswerDisplayMode:
        TargetDisplayMode = .reading
    
    @State private var selectedSourceIDs:
        Set<UUID> = []
    
    @State private var selectedTagIDs:
        Set<UUID> = []
    
    @State private var hasLoadedConfiguration = false
    
    // MARK: - Error
    
    @State private var showingError = false
    
    @State private var errorMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        
        configurationContent
            .navigationTitle("Configuration")
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
    private var configurationContent: some View {
        
        #if os(macOS)
        
        macOSContent
        
        #else
        
        iOSContent
        
        #endif
    }
    
    // MARK: - iOS Content
    
    #if os(iOS)
    
    private var iOSContent: some View {
        
        Form {
            
            studySection
            
            displaySection
            
            previewSection
            
            sourceSection
            
            tagSection
        }
    }
    
    #endif
    
    // MARK: - macOS Content
    
    #if os(macOS)
    
    private var macOSContent: some View {
        
        ScrollView {
            
            VStack(
                alignment: .leading,
                spacing: 20
            ) {
                
                macStudySection
                
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
    
    // MARK: macOS Study
    
    private var macStudySection: some View {
        
        GroupBox {
            
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                
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
                        .foregroundStyle(.secondary)
                    }
                }
                
                Text(
                    "The maximum number of cards added to a daily review session."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(4)
            
        } label: {
            
            Text("Study")
        }
    }
    
    // MARK: macOS Display
    
    private var macDisplaySection: some View {
        
        GroupBox {
            
            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                
                Picker(
                    "Before Answer",
                    selection: $beforeAnswerDisplayMode
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
                    selection: $afterAnswerDisplayMode
                ) {
                    
                    ForEach(
                        TargetDisplayMode.allCases,
                        id: \.self
                    ) { mode in
                        
                        Text(mode.title)
                            .tag(mode)
                    }
                }
                
                Text(
                    "Target shows the normal target-language text. Reading shows the optional reading. Target + Reading shows both. If no reading exists, Pyoko displays the target text instead."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(4)
            
        } label: {
            
            Text("Target Display")
        }
    }
    
    // MARK: macOS Preview
    
    private var macPreviewSection: some View {
        
        GroupBox {
            
            ExampleCardView(
                beforeAnswerDisplayMode:
                    beforeAnswerDisplayMode,
                afterAnswerDisplayMode:
                    afterAnswerDisplayMode
            )
            .padding(4)
            
        } label: {
            
            Text("Preview")
        }
    }
    
    // MARK: macOS Sources
    
    private var macSourceSection: some View {
        
        GroupBox {
            
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                
                if sources.isEmpty {
                    
                    Text(
                        "No data sources installed."
                    )
                    .foregroundStyle(.secondary)
                    
                    NavigationLink {
                        
                        SourceDataView()
                        
                    } label: {
                        
                        Label(
                            "Manage Source Data",
                            systemImage: "tray.full"
                        )
                    }
                    
                } else {
                    
                    HStack {
                        
                        Button("Select All") {
                            
                            selectedSourceIDs = Set(
                                sources.map(\.id)
                            )
                        }
                        
                        Button("Clear") {
                            
                            selectedSourceIDs.removeAll()
                            selectedTagIDs.removeAll()
                        }
                    }
                    
                    Divider()
                    
                    ForEach(
                        sources
                    ) { source in
                        
                        SourceSelectionRow(
                            source: source,
                            isSelected:
                                selectedSourceIDs.contains(
                                    source.id
                                )
                        ) {
                            
                            toggleSource(
                                source
                            )
                        }
                    }
                }
                
                if !sources.isEmpty {
                    
                    Divider()
                    
                    Text(
                        "Only vocabulary from selected data sources will be included in reviews."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(4)
            
        } label: {
            
            Text("Data Sources")
        }
    }
    
    // MARK: macOS Tags
    
    private var macTagSection: some View {
        
        GroupBox {
            
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                
                if selectedSourceIDs.isEmpty {
                    
                    Text(
                        "Select at least one data source to configure tags."
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
                            
                            selectedTagIDs = Set(
                                availableTags.map(\.id)
                            )
                        }
                        
                        Button("Clear Filter") {
                            
                            selectedTagIDs.removeAll()
                        }
                    }
                    
                    Divider()
                    
                    ForEach(
                        availableTags
                    ) { tag in
                        
                        TagSelectionRow(
                            tag: tag,
                            isSelected:
                                selectedTagIDs.contains(
                                    tag.id
                                )
                        ) {
                            
                            toggleTag(
                                tag
                            )
                        }
                    }
                }
                
                if !selectedSourceIDs.isEmpty {
                    
                    Divider()
                    
                    if selectedTagIDs.isEmpty {
                        
                        Text(
                            "No tag filter is active. All vocabulary from the selected sources will be included."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                    } else {
                        
                        Text(
                            "Only cards matching at least one selected tag will be included."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(4)
            
        } label: {
            
            Text("Tags")
        }
    }
    
    #endif
    
    // MARK: - iOS Study
    
    #if os(iOS)
    
    private var studySection: some View {
        
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
                    .foregroundStyle(.secondary)
                }
            }
            
        } header: {
            
            Text("Study")
            
        } footer: {
            
            Text(
                "The maximum number of cards added to a daily review session."
            )
        }
    }
    
    #endif
    
    // MARK: - iOS Display
    
    #if os(iOS)
    
    private var displaySection: some View {
        
        Section {
            
            Picker(
                "Before Answer",
                selection: $beforeAnswerDisplayMode
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
                selection: $afterAnswerDisplayMode
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
                "Target shows the normal target-language text. Reading uses the optional reading supplied by the vocabulary source. If no reading exists, Pyoko displays the target text instead."
            )
        }
    }
    
    #endif
    
    // MARK: - iOS Preview
    
    #if os(iOS)
    
    private var previewSection: some View {
        
        Section {
            
            ExampleCardView(
                beforeAnswerDisplayMode:
                    beforeAnswerDisplayMode,
                afterAnswerDisplayMode:
                    afterAnswerDisplayMode
            )
            
        } header: {
            
            Text("Preview")
            
        } footer: {
            
            Text(
                "This example shows how the selected display settings affect Recognition and Recall cards."
            )
        }
    }
    
    #endif
    
    // MARK: - iOS Sources
    
    #if os(iOS)
    
    private var sourceSection: some View {
        
        Section {
            
            if sources.isEmpty {
                
                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {
                    
                    Text(
                        "No data sources installed."
                    )
                    .foregroundStyle(.secondary)
                    
                    NavigationLink {
                        
                        SourceDataView()
                        
                    } label: {
                        
                        Label(
                            "Manage Source Data",
                            systemImage: "tray.full"
                        )
                    }
                }
                .padding(.vertical, 4)
                
            } else {
                
                sourceSelectionActions
                
                ForEach(
                    sources
                ) { source in
                    
                    SourceSelectionRow(
                        source: source,
                        isSelected:
                            selectedSourceIDs.contains(
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
            
            Text("Data Sources")
            
        } footer: {
            
            if !sources.isEmpty {
                
                Text(
                    "Only vocabulary from selected data sources will be included in reviews."
                )
            }
        }
    }
    
    private var sourceSelectionActions: some View {
        
        HStack {
            
            Button("Select All") {
                
                selectedSourceIDs = Set(
                    sources.map(\.id)
                )
            }
            
            Spacer()
            
            Button("Clear") {
                
                selectedSourceIDs.removeAll()
                selectedTagIDs.removeAll()
            }
        }
        .buttonStyle(.borderless)
    }
    
    #endif
    
    // MARK: - iOS Tags
    
    #if os(iOS)
    
    private var tagSection: some View {
        
        Section {
            
            if selectedSourceIDs.isEmpty {
                
                Text(
                    "Select at least one data source to configure tags."
                )
                .foregroundStyle(.secondary)
                
            } else if availableTags.isEmpty {
                
                Text(
                    "No tags are available for the selected sources."
                )
                .foregroundStyle(.secondary)
                
            } else {
                
                tagSelectionActions
                
                ForEach(
                    availableTags
                ) { tag in
                    
                    TagSelectionRow(
                        tag: tag,
                        isSelected:
                            selectedTagIDs.contains(
                                tag.id
                            )
                    ) {
                        
                        toggleTag(
                            tag
                        )
                    }
                }
            }
            
        } header: {
            
            Text("Tags")
            
        } footer: {
            
            if !selectedSourceIDs.isEmpty {
                
                if selectedTagIDs.isEmpty {
                    
                    Text(
                        "No tag filter is active. All vocabulary from the selected sources will be included."
                    )
                    
                } else {
                    
                    Text(
                        "Only cards matching at least one selected tag will be included."
                    )
                }
            }
        }
    }
    
    private var tagSelectionActions: some View {
        
        HStack {
            
            Button("Select All") {
                
                selectedTagIDs = Set(
                    availableTags.map(\.id)
                )
            }
            
            Spacer()
            
            Button("Clear Filter") {
                
                selectedTagIDs.removeAll()
            }
        }
        .buttonStyle(.borderless)
    }
    
    #endif
    
    // MARK: - Available Tags
    
    private var availableTags: [PyokoTag] {
        
        guard !selectedSourceIDs.isEmpty else {
            return []
        }
        
        return tags.filter { tag in
            
            guard let cards = tag.cards else {
                return false
            }
            
            return cards.contains { card in
                
                guard let sourceID =
                    card.source?.id
                else {
                    return false
                }
                
                return selectedSourceIDs.contains(
                    sourceID
                )
            }
        }
    }
    
    // MARK: - Validation
    
    private var canSave: Bool {
        
        !selectedSourceIDs.isEmpty
    }
    
    // MARK: - Load
    
    private func loadConfigurationIfNeeded() {
        
        guard !hasLoadedConfiguration else {
            return
        }
        
        hasLoadedConfiguration = true
        
        guard let configuration =
            configurations.first
        else {
            
            loadDefaultConfiguration()
            
            return
        }
        
        dailyCardLimit =
            configuration.dailyCardLimit
        
        beforeAnswerDisplayMode =
            configuration.beforeAnswerDisplayMode
        
        afterAnswerDisplayMode =
            configuration.afterAnswerDisplayMode
        
        selectedSourceIDs = Set(
            configuration
                .sources
                .map(\.id)
        )
        
        selectedTagIDs = Set(
            configuration
                .tags
                .map(\.id)
        )
        
        pruneUnavailableTags()
    }
    
    // MARK: - Defaults
    
    private func loadDefaultConfiguration() {
        
        dailyCardLimit = 20
        
        beforeAnswerDisplayMode =
            .target
        
        afterAnswerDisplayMode =
            .reading
        
        selectedSourceIDs = Set(
            sources.map(\.id)
        )
        
        selectedTagIDs = []
    }
    
    // MARK: - Toggle Source
    
    private func toggleSource(
        _ source: PyokoDataSource
    ) {
        
        if selectedSourceIDs.contains(
            source.id
        ) {
            
            selectedSourceIDs.remove(
                source.id
            )
            
        } else {
            
            selectedSourceIDs.insert(
                source.id
            )
        }
    }
    
    // MARK: - Toggle Tag
    
    private func toggleTag(
        _ tag: PyokoTag
    ) {
        
        if selectedTagIDs.contains(
            tag.id
        ) {
            
            selectedTagIDs.remove(
                tag.id
            )
            
        } else {
            
            selectedTagIDs.insert(
                tag.id
            )
        }
    }
    
    // MARK: - Prune Tags
    
    private func pruneUnavailableTags() {
        
        let availableTagIDs = Set(
            availableTags.map(\.id)
        )
        
        selectedTagIDs =
            selectedTagIDs.intersection(
                availableTagIDs
            )
    }
    
    // MARK: - Save
    
    private func saveConfiguration() {
        
        guard canSave else {
            return
        }
        
        do {
            
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
            
            configuration.beforeAnswerDisplayMode =
                beforeAnswerDisplayMode
            
            configuration.afterAnswerDisplayMode =
                afterAnswerDisplayMode
            
            configuration.selectedSources =
                sources.filter {
                    
                    selectedSourceIDs.contains(
                        $0.id
                    )
                }
            
            configuration.selectedTags =
                availableTags.filter {
                    
                    selectedTagIDs.contains(
                        $0.id
                    )
                }
            
            try modelContext.save()
            
            dismiss()
            
        } catch {
            
            errorMessage =
                error.localizedDescription
            
            showingError = true
        }
    }
}

// MARK: - Source Selection Row

private struct SourceSelectionRow: View {
    
    let source: PyokoDataSource
    
    let isSelected: Bool
    
    let action: () -> Void
    
    var body: some View {
        
        Button(
            action: action
        ) {
            
            HStack(
                spacing: 12
            ) {
                
                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    
                    Text(source.name)
                        .foregroundStyle(.primary)
                    
                    Text(
                        "\(source.vocabularyCount.formatted()) vocabulary"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                        systemName: "circle"
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

// MARK: - Tag Selection Row

private struct TagSelectionRow: View {
    
    let tag: PyokoTag
    
    let isSelected: Bool
    
    let action: () -> Void
    
    var body: some View {
        
        Button(
            action: action
        ) {
            
            HStack {
                
                Text(tag.name)
                    .foregroundStyle(.primary)
                
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
                        systemName: "circle"
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
