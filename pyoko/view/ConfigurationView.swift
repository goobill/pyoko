//
//  ConfigurationView.swift
//  pyoko
//
//  Created by Bill on 05/09/2026.
//

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
    
    @State private var kanjiLevel:
        KanjiLevel = .n5
    
    @State private var selectedSourceIDs:
        Set<UUID> = []
    
    @State private var selectedTagIDs:
        Set<UUID> = []
    
    @State private var hasLoadedConfiguration =
        false
    
    // MARK: - Error
    
    @State private var showingError =
        false
    
    @State private var errorMessage =
        ""
    
    // MARK: - Body
    
    var body: some View {
        
        Form {
            
            studySection
            
            kanjiSection
            
            sourceSection
            
            tagSection
        }
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
        ) {
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
    
    private var studySection:
        some View {
        
        Section {
            
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
            
        } header: {
            
            Text("Study")
            
        } footer: {
            
            Text(
                "The maximum number of cards Pyoko will add to a daily review session."
            )
        }
    }
    
    // MARK: - Kanji
    
    private var kanjiSection:
        some View {
        
        Section {
            
            Picker(
                "Kanji Level",
                selection: $kanjiLevel
            ) {
                
                ForEach(
                    KanjiLevel.allCases,
                    id: \.self
                ) { level in
                    
                    Text(level.rawValue)
                        .tag(level)
                }
            }
            
        } header: {
            
            Text("Kanji")
            
        } footer: {
            
            Text(
                "This represents your current kanji level. Pyoko can use it to provide reading assistance for kanji above your selected level."
            )
        }
    }
    
    // MARK: - Sources
    
    private var sourceSection:
        some View {
        
        Section {
            
            if sources.isEmpty {
                
                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {
                    
                    Text(
                        "No data sources installed."
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    
                    NavigationLink {
                        
                        SourceDataView()
                        
                    } label: {
                        
                        Label(
                            "Manage Source Data",
                            systemImage:
                                "tray.full"
                        )
                    }
                }
                .padding(
                    .vertical,
                    4
                )
                
            } else {
                
                sourceSelectionActions
                
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
    
    private var sourceSelectionActions:
        some View {
        
        HStack {
            
            Button(
                "Select All"
            ) {
                
                selectedSourceIDs =
                    Set(
                        sources.map(
                            \.id
                        )
                    )
            }
            
            Spacer()
            
            Button(
                "Clear"
            ) {
                
                selectedSourceIDs
                    .removeAll()
                
                selectedTagIDs
                    .removeAll()
            }
        }
        .buttonStyle(
            .borderless
        )
    }
    
    // MARK: - Tags
    
    private var tagSection:
        some View {
        
        Section {
            
            if selectedSourceIDs.isEmpty {
                
                Text(
                    "Select at least one data source to configure tags."
                )
                .foregroundStyle(
                    .secondary
                )
                
            } else if availableTags.isEmpty {
                
                Text(
                    "No tags are available for the selected sources."
                )
                .foregroundStyle(
                    .secondary
                )
                
            } else {
                
                tagSelectionActions
                
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
    
    private var tagSelectionActions:
        some View {
        
        HStack {
            
            Button(
                "Select All"
            ) {
                
                selectedTagIDs =
                    Set(
                        availableTags.map(
                            \.id
                        )
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
        .buttonStyle(
            .borderless
        )
    }
    
    // MARK: - Available Tags
    
    private var availableTags:
        [PyokoTag] {
        
        guard
            !selectedSourceIDs.isEmpty
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
                
                guard let sourceID =
                    card.source?.id
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
    
    // MARK: - Validation
    
    private var canSave: Bool {
        
        !selectedSourceIDs.isEmpty
    }
    
    // MARK: - Load
    
    private func loadConfigurationIfNeeded() {
        
        guard
            !hasLoadedConfiguration
        else {
            return
        }
        
        hasLoadedConfiguration =
            true
        
        guard let configuration =
            configurations.first
        else {
            
            loadDefaultConfiguration()
            
            return
        }
        
        dailyCardLimit =
            configuration.dailyCardLimit
        
        kanjiLevel =
            configuration.kanjiLevel
        
        selectedSourceIDs =
            Set(
                configuration
                    .sources
                    .map(
                        \.id
                    )
            )
        
        selectedTagIDs =
            Set(
                configuration
                    .tags
                    .map(
                        \.id
                    )
            )
        
        pruneUnavailableTags()
    }
    
    // MARK: - Defaults
    
    private func loadDefaultConfiguration() {
        
        dailyCardLimit = 20
        
        kanjiLevel = .n5
        
        // When configuration is first created,
        // use all currently installed sources.
        
        selectedSourceIDs =
            Set(
                sources.map(
                    \.id
                )
            )
        
        // Empty means no tag filter.
        
        selectedTagIDs =
            []
    }
    
    // MARK: - Toggle Source
    
    private func toggleSource(
        _ source: PyokoDataSource
    ) {
        
        if selectedSourceIDs
            .contains(
                source.id
            ) {
            
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
    
    // MARK: - Toggle Tag
    
    private func toggleTag(
        _ tag: PyokoTag
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
    
    // MARK: - Prune Tags
    
    private func pruneUnavailableTags() {
        
        let availableTagIDs =
            Set(
                availableTags.map(
                    \.id
                )
            )
        
        selectedTagIDs =
            selectedTagIDs
                .intersection(
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
            
            configuration.kanjiLevel =
                kanjiLevel
            
            configuration.selectedSources =
                sources.filter {
                    
                    selectedSourceIDs
                        .contains(
                            $0.id
                        )
                }
            
            // Empty selectedTags intentionally
            // means "no tag filter".
            
            configuration.selectedTags =
                availableTags.filter {
                    
                    selectedTagIDs
                        .contains(
                            $0.id
                        )
                }
            
            try modelContext.save()
            
            dismiss()
            
        } catch {
            
            errorMessage =
                error.localizedDescription
            
            showingError =
                true
        }
    }
}

// MARK: - Source Row

private struct SourceSelectionRow:
    View {
    
    let source:
        PyokoDataSource
    
    let isSelected:
        Bool
    
    let action:
        () -> Void
    
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
                    
                    Text(
                        source.name
                    )
                    .foregroundStyle(
                        .primary
                    )
                    
                    Text(
                        sourceSummary
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
                        .tint
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
    
    private var sourceSummary:
        String {
        
        "\(source.vocabularyCount.formatted()) vocabulary"
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
                        .tint
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
