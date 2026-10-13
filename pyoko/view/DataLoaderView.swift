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
        
        Group {
            #if os(macOS)
            desktopImport
            #else
            Form {
            
            deckSection
            Section { MoreDecksLink() }
            
            cardTypeSection
            
            formatSection
            
            importSection
            }
            .pyokoListPage()
            #endif
        }
        .accessibilityIdentifier("config.scroll")
        .pyokoSurface()
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

    #if os(macOS)
    /// Desktop panels share the same import state, validation and loader as the phone form.
    private var desktopImport: some View {
        MacPanelPage {
            Text("Import a deck").font(.largeTitle.bold())
            Text("Choose a CSV file or link, then select the cards to create.")
                .foregroundStyle(.secondary)
            MoreDecksLink().buttonStyle(.bordered)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 380), spacing: 24)], alignment: .leading, spacing: 24) {
                GroupBox("Deck details") {
                    VStack(alignment: .leading, spacing: 24) {
                        Picker("Import From", selection: $importMethod) {
                            ForEach(ImportMethod.allCases) { Text($0.title).tag($0) }
                        }.pickerStyle(.segmented)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Deck name").font(.headline)
                            TextField("Deck Name", text: $deckName)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityIdentifier("import.name")
                        }
                        switch importMethod {
                        case .file: fileImportFields
                        case .url: urlImportFields
                        case .googleSheets: googleSheetsFields
                        }
                        Divider()
                        Text("Cards to create").font(.headline)
                        Toggle("Recognition · Japanese → English", isOn: $createRecognition)
                        Toggle("Recall · English → Japanese", isOn: $createRecall)
                        Text("Each selected direction creates a separate review card for each word.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button { Task { await importData() } } label: {
                            HStack(spacing: 10) {
                                if isLoading { ProgressView().controlSize(.small) }
                                Text(isLoading ? "Importing…" : "Import Deck").font(.headline)
                            }.frame(maxWidth: .infinity, minHeight: 40)
                        }.buttonStyle(.borderedProminent)
                        .disabled(!canImport)
                        .accessibilityIdentifier("import.submit")
                    }
                    .disabled(isLoading)
                }
                GroupBox("CSV format") {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Use these four column headers:")
                        Text("source,target,reading,tags").font(.system(.body, design: .monospaced)).textSelection(.enabled)
                        Divider()
                        csvColumn(name: "English · source", description: "Required English meaning.")
                        csvColumn(name: "Kanji · target", description: "Required Japanese spelling; kana-only words are supported.")
                        csvColumn(name: "Hiragana · reading", description: "Optional reading.")
                        csvColumn(name: "Tags · tags", description: "Optional categories separated by |.")
                        Divider()
                        Text("to eat,食べる,たべる,N5|Verb").font(.system(.body, design: .monospaced)).textSelection(.enabled)
                        Text("Include the header row and four columns per word. Empty tags become No Tag.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }.accessibilityIdentifier("import.desktop")
    }
    #endif
    
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
            .accessibilityIdentifier("import.name")
            
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
                "Choose a CSV from your device, iCloud Drive, or another available file provider."
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
                    "Kanji → English"
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
                    "English → Kanji"
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
                            "English",
                        description:
                            "English meaning (CSV column: source)."
                    )
                    
                    csvColumn(
                        name:
                            "Kanji",
                        description:
                            "Japanese spelling, including kana-only words (CSV column: target)."
                    )
                    
                    csvColumn(
                        name:
                            "Hiragana",
                        description:
                            "Optional Hiragana (CSV column: reading)."
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
                        "English is required"
                    )
                    
                    formatRule(
                        "Kanji is required"
                    )
                    
                    formatRule(
                        "Hiragana can be empty"
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
            .accessibilityIdentifier("import.submit")
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
