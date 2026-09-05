import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataLoaderView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Environment(\.dismiss)
    private var dismiss
    
    // MARK: - Import
    
    @State private var importMethod:
        ImportMethod = .url
    
    @State private var sourceName = ""
    
    @State private var urlString = ""
    
    @State private var selectedFileURL:
        URL?
    
    // MARK: - Card Types
    
    @State private var createRecognition = true
    
    @State private var createRecall = true
    
    // MARK: - UI State
    
    @State private var isLoading = false
    
    @State private var showingFilePicker = false
    
    @State private var showingError = false
    
    @State private var errorMessage = ""
    
    // MARK: - Body
    
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
            ],
            allowsMultipleSelection: false
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
                selection: $importMethod
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
            .pickerStyle(.segmented)
            
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
    
    // MARK: - File
    
    private var filePickerRow:
        some View {
        
        Button {
            
            showingFilePicker = true
            
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
                    .foregroundStyle(.primary)
                    
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
                .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Card Types
    
    private var cardTypeSection:
        some View {
        
        Section {
            
            Toggle(
                "Recognition",
                isOn: $createRecognition
            )
            
            Text(
                "Target → Source"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Toggle(
                "Recall",
                isOn: $createRecall
            )
            
            Text(
                "Source → Target"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            
        } header: {
            
            Text("Card Types")
            
        } footer: {
            
            Text(
                "Each selected type creates a separate review card for every vocabulary item."
            )
        }
    }
    
    // MARK: - CSV Format
    
    private var formatSection:
        some View {
        
        Section {
            
            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                
                // Required format
                
                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {
                    
                    Text(
                        "Required Format"
                    )
                    .font(.headline)
                    
                    Text(
                        "source,target,reading,tags"
                    )
                    .font(
                        .system(
                            .body,
                            design: .monospaced
                        )
                    )
                    .textSelection(.enabled)
                }
                
                Divider()
                
                // Example
                
                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
                    
                    Text("Example")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(
                        """
                        source,target,reading,tags
                        to eat,食べる,たべる,N5|Verb
                        library,図書館,としょかん,N5|Place
                        thank you,ありがとう,,Greeting
                        bread,pain,,Food
                        """
                    )
                    .font(
                        .system(
                            .caption,
                            design: .monospaced
                        )
                    )
                    .textSelection(.enabled)
                }
                
                Divider()
                
                // Rules
                
                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
                    
                    formatRule(
                        "Source is required"
                    )
                    
                    formatRule(
                        "Target is required"
                    )
                    
                    formatRule(
                        "Reading can be empty"
                    )
                    
                    formatRule(
                        "Tags can be empty"
                    )
                    
                    formatRule(
                        "Use | between multiple tags"
                    )
                    
                    formatRule(
                        "Every row must contain exactly 4 columns"
                    )
                }
            }
            .padding(.vertical, 4)
            
        } header: {
            
            Text("CSV Format")
            
        } footer: {
            
            Text(
                "The first row is treated as the header. Empty tags are automatically assigned “No Tag”."
            )
        }
    }
    
    // MARK: - Format Rule
    
    private func formatRule(
        _ text: String
    ) -> some View {
        
        Label(
            text,
            systemImage:
                "checkmark.circle"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
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
            .disabled(!canImport)
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
        
        guard !trimmedName.isEmpty else {
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
            
            return selectedFileURL != nil
        }
    }
    
    // MARK: - File Selection
    
    private func handleFileSelection(
        _ result: Result<[URL], Error>
    ) {
        switch result {
            
        case .success(let urls):
            
            guard let url = urls.first else {
                return
            }
            
            selectedFileURL = url
            
            let trimmedName = sourceName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            
            if trimmedName.isEmpty {
                sourceName = url
                    .deletingPathExtension()
                    .lastPathComponent
            }
            
        case .failure(let error):
            
            showError(error)
        }
    }
    
    // MARK: - Import Data
    
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
            
            showError(error)
        }
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
            .keyboardType(.URL)
        
        #else
        
        self
        
        #endif
    }
}
