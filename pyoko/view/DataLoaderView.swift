import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataLoaderView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State private var importMethod:
        ImportMethod = .url
    
    @State private var sourceName =
        ""
    
    @State private var urlString =
        ""
    
    @State private var selectedFileURL:
        URL?
    
    @State private var createRecognition =
        true
    
    @State private var createRecall =
        true
    
    @State private var isLoading =
        false
    
    @State private var showingFilePicker =
        false
    
    @State private var showingError =
        false
    
    @State private var errorMessage =
        ""
    
    var body: some View {
        
        Form {
            
            sourceSection
            
            cardTypeSection
            
            formatSection
            
            importSection
        }
        .navigationTitle(
            "Add Data Source"
        )
        .fileImporter(
            isPresented:
                $showingFilePicker,
            allowedContentTypes: [
                .commaSeparatedText,
                .text
            ]
        ) { result in
            
            handleFileSelection(
                result
            )
        }
        .alert(
            "Import Failed",
            isPresented:
                $showingError
        ) {
            
            Button("OK") {}
            
        } message: {
            
            Text(errorMessage)
        }
    }
    
    // MARK: - Source
    
    private var sourceSection:
        some View {
        
        Section("Source") {
            
            Picker(
                "Import From",
                selection:
                    $importMethod
            ) {
                
                ForEach(
                    ImportMethod.allCases
                ) { method in
                    
                    Text(
                        method.title
                    )
                    .tag(method)
                }
            }
            .pickerStyle(
                .segmented
            )
            
            TextField(
                "Source Name",
                text: $sourceName
            )
            
            switch importMethod {
                
            case .url:
                
                urlField
                
            case .file:
                
                filePickerRow
            }
        }
    }
    
    // MARK: - URL
    
    private var urlField:
        some View {
        
        TextField(
            "CSV URL",
            text: $urlString
        )
        .autocorrectionDisabled()
        .pyokoURLInput()
    }
    
    // MARK: - File Picker
    
    private var filePickerRow:
        some View {
        
        Button {
            
            showingFilePicker =
                true
            
        } label: {
            
            HStack {
                
                Image(
                    systemName: "doc"
                )
                
                if let selectedFileURL {
                    
                    Text(
                        selectedFileURL
                            .lastPathComponent
                    )
                    .foregroundStyle(
                        .primary
                    )
                    
                } else {
                    
                    Text(
                        "Choose CSV File"
                    )
                }
                
                Spacer()
                
                Image(
                    systemName:
                        "chevron.right"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }
    
    // MARK: - Card Types
    
    private var cardTypeSection:
        some View {
        
        Section {
            
            Toggle(
                "Recognition",
                isOn:
                    $createRecognition
            )
            
            Text(
                "Japanese → English"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
            
            Toggle(
                "Recall",
                isOn:
                    $createRecall
            )
            
            Text(
                "English → Japanese"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
            
        } header: {
            
            Text("Card Types")
            
        } footer: {
            
            Text(
                "Each selected type creates a separate card for every vocabulary item."
            )
        }
    }
    
    // MARK: - Format
    
    private var formatSection:
        some View {
        
        Section("CSV Format") {
            
            Text(
                "english,japanese,tags"
            )
            .font(
                .system(
                    .body,
                    design:
                        .monospaced
                )
            )
            
            Text(
                "The first row is ignored as the header. Every vocabulary row must contain exactly three columns in this order."
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
            
            Text(
                "Separate multiple tags using |. An empty tags column is automatically assigned “No Tag”."
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
        }
    }
    
    // MARK: - Import
    
    private var importSection:
        some View {
        
        Section {
            
            Button {
                
                Task {
                    await importData()
                }
                
            } label: {
                
                HStack {
                    
                    Spacer()
                    
                    if isLoading {
                        
                        ProgressView()
                        
                    } else {
                        
                        Text(
                            "Import Data"
                        )
                        .fontWeight(
                            .semibold
                        )
                    }
                    
                    Spacer()
                }
            }
            .disabled(
                !canImport
            )
        }
    }
    
    // MARK: - Validation
    
    private var canImport: Bool {
        
        guard !isLoading else {
            return false
        }
        
        let trimmedName =
            sourceName
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
        
        guard
            !trimmedName.isEmpty
        else {
            return false
        }
        
        guard
            createRecognition ||
            createRecall
        else {
            return false
        }
        
        switch importMethod {
            
        case .url:
            
            return !urlString
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty
            
        case .file:
            
            return selectedFileURL
                != nil
        }
    }
    
    // MARK: - File Selection
    
    private func handleFileSelection(
        _ result:
            Result<URL, Error>
    ) {
        
        switch result {
            
        case .success(let url):
            
            selectedFileURL =
                url
            
            let trimmedName =
                sourceName
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
            
            if trimmedName.isEmpty {
                
                sourceName =
                    url
                        .deletingPathExtension()
                        .lastPathComponent
            }
            
        case .failure(let error):
            
            showError(
                error
            )
        }
    }
    
    // MARK: - Import
    
    private func importData()
        async {
        
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        let loader = DataLoader(
            modelContext:
                modelContext
        )
        
        do {
            
            switch importMethod {
                
            case .url:
                
                try await loader
                    .loadFromURL(
                        sourceName:
                            sourceName,
                        urlString:
                            urlString,
                        createRecognition:
                            createRecognition,
                        createRecall:
                            createRecall
                    )
                
            case .file:
                
                guard
                    let selectedFileURL
                else {
                    throw DataLoaderError
                        .invalidCSV
                }
                
                try loader
                    .loadFromFile(
                        sourceName:
                            sourceName,
                        url:
                            selectedFileURL,
                        createRecognition:
                            createRecognition,
                        createRecall:
                            createRecall
                    )
            }
            
            dismiss()
            
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

// MARK: - Import Method

private enum ImportMethod:
    String,
    CaseIterable,
    Identifiable {
    
    case url
    case file
    
    var id: Self {
        self
    }
    
    var title: String {
        
        switch self {
            
        case .url:
            return "URL"
            
        case .file:
            return "File"
        }
    }
}

// MARK: - Platform URL Input

private extension View {
    
    @ViewBuilder
    func pyokoURLInput()
        -> some View {
        
        #if os(iOS)
        
        self
            .textInputAutocapitalization(
                .never
            )
            .keyboardType(
                .URL
            )
        
        #else
        
        self
        
        #endif
    }
}
