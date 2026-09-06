import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataLoaderView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Environment(\.dismiss)
    private var dismiss
    
    // MARK: - Import
    
    @State
    private var importMethod:
        ImportMethod =
            ImportMethod.file
    
    @State
    private var deckName =
        ""
    
    @State
    private var urlString =
        ""
    
    @State
    private var googleSheetsURL =
        ""
    
    @State
    private var selectedFileURL:
        URL?
    
    // MARK: - Cards
    
    @State
    private var createRecognition =
        true
    
    @State
    private var createRecall =
        true
    
    // MARK: - UI
    
    @State
    private var isLoading =
        false
    
    @State
    private var showingFilePicker =
        false
    
    @State
    private var showingError =
        false
    
    @State
    private var errorMessage =
        ""
    
    // MARK: - Body
    
    var body: some View {
        
        Form {
            
            deckSection
            
            cardTypeSection
            
            formatSection
            
            importSection
        }
        .navigationTitle(
            "Import Deck"
        )
        .fileImporter(
            isPresented:
                $showingFilePicker,
            allowedContentTypes: [
                .commaSeparatedText,
                .text
            ],
            allowsMultipleSelection:
                false
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
            
            Text(
                errorMessage
            )
        }
    }
    
    // MARK: - Deck
    
    private var deckSection:
        some View {
        
        Section {
            
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
                "Deck Name",
                text:
                    $deckName
            )
            
            switch importMethod {
                
            case .file:
                
                fileImportFields
                
            case .url:
                
                urlImportFields
                
            case .googleSheets:
                
                googleSheetsFields
            }
            
        } header: {
            
            Text("Deck")
        }
    }
    
    // MARK: - File
    
    private var fileImportFields:
        some View {
        
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            
            Button {
                
                showingFilePicker =
                    true
                
            } label: {
                
                HStack {
                    
                    Image(
                        systemName:
                            "doc"
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
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
            
            Text(
                "Choose a CSV from Files. Available locations can include local storage, iCloud Drive, Google Drive, and other installed file providers."
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
        }
    }
    
    // MARK: - URL
    
    private var urlImportFields:
        some View {
        
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            
            TextField(
                "CSV URL",
                text:
                    $urlString
            )
            .autocorrectionDisabled()
            .pyokoURLInput()
            
            Text(
                "Enter a direct URL to a CSV file."
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
        }
    }
    
    // MARK: - Google Sheets
    
    private var googleSheetsFields:
        some View {
        
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            
            TextField(
                "Google Sheets URL",
                text:
                    $googleSheetsURL
            )
            .autocorrectionDisabled()
            .pyokoURLInput()
            
            Text(
                "Paste the normal Google Sheets sharing URL. The selected sheet must be publicly readable or published to the web."
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
            
            Label(
                "Private Google Sheets are not supported yet.",
                systemImage:
                    "lock"
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
        }
    }
    
    // MARK: - Cards
    
    private var cardTypeSection:
        some View {
        
        Section {
            
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                
                Toggle(
                    "Recognition",
                    isOn:
                        $createRecognition
                )
                
                Text(
                    "Target → Source"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
                
                Text(
                    "Example: 食べる → to eat"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
            
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                
                Toggle(
                    "Recall",
                    isOn:
                        $createRecall
                )
                
                Text(
                    "Source → Target"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
                
                Text(
                    "Example: to eat → 食べる"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
            
        } header: {
            
            Text(
                "Cards to Create"
            )
            
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
                spacing: 16
            ) {
                
                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {
                    
                    Text(
                        "Required Format"
                    )
                    .font(
                        .headline
                    )
                    
                    Text(
                        "source,target,reading,tags"
                    )
                    .font(
                        .system(
                            .body,
                            design:
                                .monospaced
                        )
                    )
                    .textSelection(
                        .enabled
                    )
                }
                
                Divider()
                
                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {
                    
                    csvColumn(
                        name:
                            "Source",
                        description:
                            "The language you already know."
                    )
                    
                    csvColumn(
                        name:
                            "Target",
                        description:
                            "The language you are learning."
                    )
                    
                    csvColumn(
                        name:
                            "Reading",
                        description:
                            "Optional reading or pronunciation of the target."
                    )
                    
                    csvColumn(
                        name:
                            "Tags",
                        description:
                            "Optional categories separated using |."
                    )
                }
                
                Divider()
                
                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {
                    
                    Text(
                        "Example"
                    )
                    .font(
                        .subheadline
                    )
                    .fontWeight(
                        .semibold
                    )
                    
                    Text(
                        """
                        source,target,reading,tags
                        to eat,食べる,たべる,N5|Verb
                        library,図書館,としょかん,N5|Place
                        thank you,ありがとう,,Greeting
                        data,data,,
                        """
                    )
                    .font(
                        .system(
                            .caption,
                            design:
                                .monospaced
                        )
                    )
                    .textSelection(
                        .enabled
                    )
                }
                
                Divider()
                
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
                        "Every data row must contain exactly 4 columns"
                    )
                }
            }
            .padding(
                .vertical,
                4
            )
            
        } header: {
            
            Text(
                "CSV Format"
            )
            
        } footer: {
            
            Text(
                "The first row is treated as the header. Empty tags are automatically assigned “No Tag”."
            )
        }
    }
    
    private func csvColumn(
        name: String,
        description: String
    ) -> some View {
        
        VStack(
            alignment: .leading,
            spacing: 2
        ) {
            
            Text(name)
                .fontWeight(
                    .medium
                )
            
            Text(
                description
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
        }
    }
    
    private func formatRule(
        _ text: String
    ) -> some View {
        
        Label(
            text,
            systemImage:
                "checkmark.circle"
        )
        .font(
            .caption
        )
        .foregroundStyle(
            .secondary
        )
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
                            "Import Deck"
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
    
    private var canImport:
        Bool {
        
        guard
            !isLoading
        else {
            return false
        }
        
        guard
            !deckName
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty
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
            
        case .file:
            
            return selectedFileURL
                != nil
            
        case .url:
            
            return !urlString
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty
            
        case .googleSheets:
            
            return !googleSheetsURL
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty
        }
    }
    
    // MARK: - File Selection
    
    private func handleFileSelection(
        _ result:
            Result<[URL], Error>
    ) {
        
        switch result {
            
        case .success(
            let urls
        ):
            
            guard
                let url =
                    urls.first
            else {
                return
            }
            
            selectedFileURL =
                url
            
            if deckName
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty {
                
                deckName =
                    url
                        .deletingPathExtension()
                        .lastPathComponent
            }
            
        case .failure(
            let error
        ):
            
            showError(
                error
            )
        }
    }
    
    // MARK: - Import
    
    private func importData()
        async {
        
        isLoading =
            true
        
        defer {
            
            isLoading =
                false
        }
        
        let loader =
            DataLoader(
                modelContext:
                    modelContext
            )
        
        do {
            
            switch importMethod {
                
            case .file:
                
                guard
                    let selectedFileURL
                else {
                    
                    throw DataLoaderError
                        .invalidCSV
                }
                
                try loader
                    .loadFromFile(
                        deckName:
                            deckName,
                        url:
                            selectedFileURL,
                        createRecognition:
                            createRecognition,
                        createRecall:
                            createRecall
                    )
                
            case .url:
                
                try await loader
                    .loadFromURL(
                        deckName:
                            deckName,
                        urlString:
                            urlString,
                        createRecognition:
                            createRecognition,
                        createRecall:
                            createRecall
                    )
                
            case .googleSheets:
                
                try await loader
                    .loadFromGoogleSheet(
                        deckName:
                            deckName,
                        urlString:
                            googleSheetsURL,
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
    
    case file
    case url
    case googleSheets
    
    var id: Self {
        self
    }
    
    var title: String {
        
        switch self {
            
        case .file:
            return "File"
            
        case .url:
            return "URL"
            
        case .googleSheets:
            return "Sheets"
        }
    }
}

// MARK: - URL Input

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
