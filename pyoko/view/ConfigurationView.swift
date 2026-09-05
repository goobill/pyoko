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
        
        Form {
            
            studySection
            
            displaySection
            
            previewSection
            
            sourceSection
            
            tagSection
        }
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
    
    // MARK: - Study
    
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
    
    // MARK: - Display
    
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
    
    // MARK: - Preview
    
    private var previewSection: some View {
        
        Section {
            
            ExampleCardPreview(
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
    
    // MARK: - Sources
    
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
    
    // MARK: - Source Actions
    
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
    
    // MARK: - Tags
    
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
    
    // MARK: - Tag Actions
    
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
        
        beforeAnswerDisplayMode = .target
        
        afterAnswerDisplayMode = .reading
        
        // Select all currently installed sources
        // when no configuration exists yet.
        
        selectedSourceIDs = Set(
            sources.map(\.id)
        )
        
        // An empty tag selection means:
        // no tag filtering.
        
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

// MARK: - Example Card Preview

private struct ExampleCardPreview: View {
    
    let beforeAnswerDisplayMode:
        TargetDisplayMode
    
    let afterAnswerDisplayMode:
        TargetDisplayMode
    
    @State private var cardType:
        ExampleCardType = .recognition
    
    // MARK: - Example Data
    
    private let sourceText =
        "to eat"
    
    private let targetText =
        "食べる"
    
    private let targetReading =
        "たべる"
    
    var body: some View {
        
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            
            Picker(
                "Example Card Type",
                selection: $cardType
            ) {
                
                ForEach(
                    ExampleCardType.allCases
                ) { type in
                    
                    Text(type.title)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            HStack(
                alignment: .center,
                spacing: 12
            ) {
                
                previewStage(
                    title: "Before Answer",
                    primaryText:
                        beforePrimaryText,
                    secondaryText: nil
                )
                
                Image(
                    systemName: "arrow.right"
                )
                .foregroundStyle(
                    .secondary
                )
                
                previewStage(
                    title: "After Answer",
                    primaryText:
                        afterPrimaryText,
                    secondaryText:
                        afterSecondaryText
                )
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Before
    
    private var beforePrimaryText:
        String {
        
        switch cardType {
            
        case .recognition:
            
            return displayedTarget(
                mode:
                    beforeAnswerDisplayMode
            )
            
        case .recall:
            
            return sourceText
        }
    }
    
    // MARK: - After
    
    private var afterPrimaryText:
        String {
        
        switch cardType {
            
        case .recognition:
            
            return displayedTarget(
                mode:
                    afterAnswerDisplayMode
            )
            
        case .recall:
            
            return sourceText
        }
    }
    
    private var afterSecondaryText:
        String? {
        
        switch cardType {
            
        case .recognition:
            
            return sourceText
            
        case .recall:
            
            return displayedTarget(
                mode:
                    afterAnswerDisplayMode
            )
        }
    }
    
    // MARK: - Target Display
    
    private func displayedTarget(
        mode: TargetDisplayMode
    ) -> String {
        
        switch mode {
            
        case .target:
            return targetText
            
        case .reading:
            return targetReading
        }
    }
    
    // MARK: - Preview Stage
    
    private func previewStage(
        title: String,
        primaryText: String,
        secondaryText: String?
    ) -> some View {
        
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            
            Text(title)
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            
            VStack(
                spacing: 10
            ) {
                
                Spacer(
                    minLength: 8
                )
                
                Text(primaryText)
                    .font(.title2)
                    .fontWeight(
                        .semibold
                    )
                    .multilineTextAlignment(
                        .center
                    )
                
                if let secondaryText {
                    
                    Divider()
                    
                    Text(
                        secondaryText
                    )
                    .multilineTextAlignment(
                        .center
                    )
                }
                
                Spacer(
                    minLength: 8
                )
            }
            .frame(
                maxWidth: .infinity,
                minHeight: 140
            )
            .padding()
            .background(
                Color.secondary
                    .opacity(0.08)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12
                )
            )
        }
        .frame(
            maxWidth: .infinity
        )
    }
}

// MARK: - Example Card Type

private enum ExampleCardType:
    String,
    CaseIterable,
    Identifiable {
    
    case recognition
    case recall
    
    var id: Self {
        self
    }
    
    var title: String {
        
        switch self {
            
        case .recognition:
            return "Recognition"
            
        case .recall:
            return "Recall"
        }
    }
}
