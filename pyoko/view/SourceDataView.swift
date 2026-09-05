import SwiftUI
import SwiftData

struct SourceDataView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Query(
        sort: \PyokoDataSource.name
    )
    private var sources: [PyokoDataSource]
    
    @State private var downloadingSourceKeys:
        Set<String> = []
    
    @State private var sourceToDelete:
        PyokoDataSource?
    
    @State private var showingDeleteConfirmation =
        false
    
    @State private var showingError =
        false
    
    @State private var errorMessage =
        ""
    
    var body: some View {
        
        List {
            
            customSourcesSection
            
            defaultSourcesSection
        }
        .navigationTitle("Source Data")
        .toolbar {
            
            ToolbarItem(
                placement: .primaryAction
            ) {
                
                NavigationLink {
                    
                    DataLoaderView()
                    
                } label: {
                    
                    Label(
                        "Add Data Source",
                        systemImage: "plus"
                    )
                }
            }
        }
        .confirmationDialog(
            "Delete Data Source?",
            isPresented:
                $showingDeleteConfirmation,
            titleVisibility: .visible,
            presenting: sourceToDelete
        ) { source in
            
            Button(
                "Delete \(source.name)",
                role: .destructive
            ) {
                
                deleteSource(
                    source
                )
            }
            
            Button(
                "Cancel",
                role: .cancel
            ) {}
            
        } message: { source in
            
            Text(
                deleteMessage(
                    for: source
                )
            )
        }
        .alert(
            "Source Data Error",
            isPresented: $showingError
        ) {
            
            Button("OK") {}
            
        } message: {
            
            Text(errorMessage)
        }
    }
    
    // MARK: - Custom Sources
    
    private var customSources:
        [PyokoDataSource] {
        
        sources.filter {
            $0.origin == .custom
        }
    }
    
    private var customSourcesSection:
        some View {
        
        Section {
            
            if customSources.isEmpty {
                
                Text(
                    "No custom data sources added."
                )
                .foregroundStyle(
                    .secondary
                )
                
            } else {
                
                ForEach(
                    customSources
                ) { source in
                    
                    CustomSourceRow(
                        source: source,
                        onDelete: {
                            
                            requestDelete(
                                source
                            )
                        }
                    )
                }
            }
            
        } header: {
            
            Text("Custom Sources")
            
        } footer: {
            
            Text(
                "Add your own vocabulary using a CSV URL or local CSV file."
            )
        }
    }
    
    // MARK: - Default Sources
    
    private var defaultSourcesSection:
        some View {
        
        Section {
            
            ForEach(
                DefaultDataSources.all
            ) { defaultSource in
                
                DefaultSourceRow(
                    source:
                        defaultSource,
                    installedSource:
                        installedSource(
                            for: defaultSource
                        ),
                    isDownloading:
                        downloadingSourceKeys
                            .contains(
                                defaultSource.key
                            ),
                    onDownload: {
                        
                        download(
                            defaultSource
                        )
                    },
                    onDelete: {
                        
                        guard let source =
                            installedSource(
                                for: defaultSource
                            )
                        else {
                            return
                        }
                        
                        requestDelete(
                            source
                        )
                    }
                )
            }
            
        } header: {
            
            Text("Default Sources")
            
        } footer: {
            
            Text(
                "Default sources can be deleted and downloaded again at any time."
            )
        }
    }
    
    // MARK: - Installed Source
    
    private func installedSource(
        for source: DefaultDataSource
    ) -> PyokoDataSource? {
        
        sources.first {
            $0.catalogKey == source.key
        }
    }
    
    // MARK: - Download
    
    private func download(
        _ source: DefaultDataSource
    ) {
        
        guard
            !downloadingSourceKeys
                .contains(
                    source.key
                )
        else {
            return
        }
        
        downloadingSourceKeys.insert(
            source.key
        )
        
        Task {
            
            defer {
                
                downloadingSourceKeys.remove(
                    source.key
                )
            }
            
            do {
                
                let manager =
                    SourceDataManager(
                        modelContext:
                            modelContext
                    )
                
                try await manager.install(
                    source
                )
                
            } catch {
                
                showError(
                    error
                )
            }
        }
    }
    
    // MARK: - Delete
    
    private func requestDelete(
        _ source: PyokoDataSource
    ) {
        
        sourceToDelete = source
        
        showingDeleteConfirmation =
            true
    }
    
    private func deleteSource(
        _ source: PyokoDataSource
    ) {
        
        do {
            
            let manager =
                SourceDataManager(
                    modelContext:
                        modelContext
                )
            
            try manager.delete(
                source
            )
            
            sourceToDelete = nil
            
        } catch {
            
            showError(
                error
            )
        }
    }
    
    private func deleteMessage(
        for source: PyokoDataSource
    ) -> String {
        
        """
        This will delete \(source.vocabularyCount) vocabulary items and \(source.totalCardCount) cards from this source.
        """
    }
    
    // MARK: - Error
    
    private func showError(
        _ error: Error
    ) {
        
        errorMessage =
            error.localizedDescription
        
        showingError = true
    }
}

// MARK: - Custom Source Row

private struct CustomSourceRow: View {
    
    let source: PyokoDataSource
    
    let onDelete: () -> Void
    
    var body: some View {
        
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            
            Text(source.name)
                .font(.headline)
            
            SourceStatisticsView(
                source: source
            )
            
            HStack {
                
                Text(importedText)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                
                Spacer()
                
                Button(
                    role: .destructive
                ) {
                    
                    onDelete()
                    
                } label: {
                    
                    Label(
                        "Delete",
                        systemImage: "trash"
                    )
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(
            .vertical,
            4
        )
    }
    
    private var importedText: String {
        
        "Imported \(source.importedAt.formatted(date: .abbreviated, time: .omitted))"
    }
}

// MARK: - Default Source Row

private struct DefaultSourceRow: View {
    
    let source: DefaultDataSource
    
    let installedSource:
        PyokoDataSource?
    
    let isDownloading: Bool
    
    let onDownload: () -> Void
    
    let onDelete: () -> Void
    
    var body: some View {
        
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            
            title
            
            if let installedSource {
                
                installedContent(
                    installedSource
                )
                
            } else {
                
                availableContent
            }
        }
        .padding(
            .vertical,
            4
        )
    }
    
    // MARK: - Title
    
    private var title: some View {
        
        HStack {
            
            Text(source.name)
                .font(.headline)
            
            Spacer()
            
            if installedSource != nil {
                
                Label(
                    "Installed",
                    systemImage:
                        "checkmark.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }
    
    // MARK: - Installed
    
    private func installedContent(
        _ installedSource:
            PyokoDataSource
    ) -> some View {
        
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            
            SourceStatisticsView(
                source: installedSource
            )
            
            HStack {
                
                Text(
                    "Imported \(installedSource.importedAt.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
                
                Spacer()
                
                Button(
                    role: .destructive
                ) {
                    
                    onDelete()
                    
                } label: {
                    
                    Label(
                        "Delete",
                        systemImage: "trash"
                    )
                }
                .buttonStyle(.borderless)
            }
        }
    }
    
    // MARK: - Available
    
    private var availableContent:
        some View {
        
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            
            Text(
                source.description
            )
            .font(.subheadline)
            .foregroundStyle(
                .secondary
            )
            
            HStack {
                
                Spacer()
                
                Button {
                    
                    onDownload()
                    
                } label: {
                    
                    if isDownloading {
                        
                        HStack {
                            
                            ProgressView()
                            
                            Text(
                                "Downloading"
                            )
                        }
                        
                    } else {
                        
                        Label(
                            "Download",
                            systemImage:
                                "arrow.down.circle"
                        )
                    }
                }
                .buttonStyle(.bordered)
                .disabled(
                    isDownloading
                )
            }
        }
    }
}

// MARK: - Statistics

private struct SourceStatisticsView:
    View {
    
    let source: PyokoDataSource
    
    var body: some View {
        
        HStack(
            spacing: 16
        ) {
            
            statistic(
                value:
                    source.vocabularyCount,
                title:
                    "Vocabulary"
            )
            
            if source.recognitionCount > 0 {
                
                statistic(
                    value:
                        source.recognitionCount,
                    title:
                        "Recognition"
                )
            }
            
            if source.recallCount > 0 {
                
                statistic(
                    value:
                        source.recallCount,
                    title:
                        "Recall"
                )
            }
        }
    }
    
    private func statistic(
        value: Int,
        title: String
    ) -> some View {
        
        VStack(
            alignment: .leading,
            spacing: 2
        ) {
            
            Text(
                value.formatted()
            )
            .font(.subheadline)
            .fontWeight(
                .semibold
            )
            
            Text(title)
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
        }
    }
}
