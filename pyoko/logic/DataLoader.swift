import Foundation
import SwiftData

@MainActor
final class DataLoader {
    
    private let modelContext:
        ModelContext
    
    private let defaultTagName =
        "No Tag"
    
    init(
        modelContext: ModelContext
    ) {
        
        self.modelContext =
            modelContext
    }
    
    // MARK: - URL
    
    func loadFromURL(
        deckName: String,
        urlString: String,
        createRecognition: Bool,
        createRecall: Bool,
        catalogKey: String? = nil,
        origin: DeckOrigin = DeckOrigin.url,
        originName: String? = nil,
        originIdentifier: String? = nil
    ) async throws {
        
        let trimmedURL =
            urlString
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
        
        guard
            let url =
                URL(
                    string:
                        trimmedURL
                ),
            let scheme =
                url.scheme?
                    .lowercased(),
            scheme == "http" ||
            scheme == "https"
        else {
            
            throw DataLoaderError
                .invalidURL
        }
        
        let data =
            try await download(
                from: url
            )
        
        try importCSV(
            data: data,
            deckName: deckName,
            catalogKey: catalogKey,
            origin: origin,
            originName: originName,
            originURLString:
                trimmedURL,
            originIdentifier:
                originIdentifier,
            createRecognition:
                createRecognition,
            createRecall:
                createRecall
        )
    }
    
    // MARK: - Google Sheets
    
    func loadFromGoogleSheet(
        deckName: String,
        urlString: String,
        createRecognition: Bool,
        createRecall: Bool
    ) async throws {
        
        let reference =
            try GoogleSheetsCSVURL
                .makeReference(
                    from:
                        urlString
                )
        
        let (
            data,
            response
        ) =
            try await downloadWithResponse(
                from:
                    reference.csvURL
            )
        
        // Private Sheets commonly redirect
        // to or return an HTML sign-in/access
        // page rather than CSV.
        
        if response.mimeType?
            .lowercased()
            .contains(
                "text/html"
            ) == true ||
            looksLikeHTML(data) {
            
            throw DataLoaderError
                .googleSheetNotAccessible
        }
        
        try importCSV(
            data: data,
            deckName: deckName,
            catalogKey: nil,
            origin:
                DeckOrigin.googleSheets,
            originName:
                "Google Sheet",
            originURLString:
                urlString,
            originIdentifier:
                reference.identifier,
            createRecognition:
                createRecognition,
            createRecall:
                createRecall
        )
    }
    
    // MARK: - Local / Files
    
    func loadFromFile(
        deckName: String,
        url: URL,
        createRecognition: Bool,
        createRecall: Bool
    ) throws {
        
        let accessingSecurityScopedResource =
            url
                .startAccessingSecurityScopedResource()
        
        defer {
            
            if accessingSecurityScopedResource {
                
                url
                    .stopAccessingSecurityScopedResource()
            }
        }
        
        let data =
            try Data(
                contentsOf: url
            )
        
        try importCSV(
            data: data,
            deckName: deckName,
            catalogKey: nil,
            origin:
                DeckOrigin.file,
            originName:
                url.lastPathComponent,
            originURLString: nil,
            originIdentifier: nil,
            createRecognition:
                createRecognition,
            createRecall:
                createRecall
        )
    }
    
    // MARK: - Download
    
    private func download(
        from url: URL
    ) async throws -> Data {
        
        let (
            data,
            _
        ) =
            try await downloadWithResponse(
                from: url
            )
        
        return data
    }
    
    private func downloadWithResponse(
        from url: URL
    ) async throws -> (
        Data,
        URLResponse
    ) {
        
        let (
            data,
            response
        ) =
            try await URLSession
                .shared
                .data(
                    from: url
                )
        
        if let httpResponse =
            response
                as? HTTPURLResponse {
            
            guard
                (200...299)
                    .contains(
                        httpResponse
                            .statusCode
                    )
            else {
                
                throw DataLoaderError
                    .downloadFailed(
                        statusCode:
                            httpResponse
                                .statusCode
                    )
            }
        }
        
        return (
            data,
            response
        )
    }
    
    // MARK: - Import
    
    private func importCSV(
        data: Data,
        deckName: String,
        catalogKey: String?,
        origin: DeckOrigin,
        originName: String?,
        originURLString: String?,
        originIdentifier: String?,
        createRecognition: Bool,
        createRecall: Bool
    ) throws {
        
        guard
            createRecognition ||
            createRecall
        else {
            
            throw DataLoaderError
                .noCardTypesSelected
        }
        
        let deckName =
            deckName
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
        
        guard
            !deckName.isEmpty
        else {
            
            throw DataLoaderError
                .emptyDeckName
        }
        
        guard
            let csv =
                String(
                    data: data,
                    encoding: .utf8
                )
        else {
            
            throw DataLoaderError
                .invalidEncoding
        }
        
        let words =
            try parseCSV(
                csv
            )
        
        try ensureDeckDoesNotExist(
            name: deckName,
            catalogKey:
                catalogKey
        )
        
        let deck =
            PyokoDeck(
                catalogKey:
                    catalogKey,
                name:
                    deckName,
                origin:
                    origin,
                originName:
                    originName,
                originURLString:
                    originURLString,
                originIdentifier:
                    originIdentifier,
                vocabularyCount:
                    words.count,
                recognitionCount:
                    createRecognition
                    ? words.count
                    : 0,
                recallCount:
                    createRecall
                    ? words.count
                    : 0,
                importedAt:
                    Date.now
            )
        
        modelContext.insert(
            deck
        )
        
        var tagCache:
            [String: PyokoTag] = [:]
        
        for word in words {
            
            let tags =
                try getOrCreateTags(
                    names:
                        word.tags,
                    cache:
                        &tagCache
                )
            
            if createRecognition {
                
                let card =
                    PyokoCard(
                        type:
                            CardType.recognition,
                        sourceText:
                            word.sourceText,
                        targetText:
                            word.targetText,
                        targetReading:
                            word.targetReading,
                        deck:
                            deck,
                        tags:
                            tags
                    )
                
                modelContext.insert(
                    card
                )
            }
            
            if createRecall {
                
                let card =
                    PyokoCard(
                        type:
                            CardType.recall,
                        sourceText:
                            word.sourceText,
                        targetText:
                            word.targetText,
                        targetReading:
                            word.targetReading,
                        deck:
                            deck,
                        tags:
                            tags
                    )
                
                modelContext.insert(
                    card
                )
            }
        }
        
        try modelContext.save()
    }
    
    // MARK: - Duplicate Deck
    
    private func ensureDeckDoesNotExist(
        name: String,
        catalogKey: String?
    ) throws {
        
        if let catalogKey {
            
            let key =
                catalogKey
            
            let descriptor =
                FetchDescriptor<PyokoDeck>(
                    predicate:
                        #Predicate<PyokoDeck> {
                            deck in
                            
                            deck.catalogKey ==
                                key
                        }
                )
            
            if try modelContext
                .fetch(
                    descriptor
                )
                .first != nil {
                
                throw DataLoaderError
                    .deckAlreadyExists(
                        name: name
                    )
            }
        }
        
        let deckName =
            name
        
        let descriptor =
            FetchDescriptor<PyokoDeck>(
                predicate:
                    #Predicate<PyokoDeck> {
                        deck in
                        
                        deck.name ==
                            deckName
                    }
            )
        
        if try modelContext
            .fetch(
                descriptor
            )
            .first != nil {
            
            throw DataLoaderError
                .deckAlreadyExists(
                    name: name
                )
        }
    }
    
    // MARK: - Tags
    
    private func getOrCreateTags(
        names: [String],
        cache:
            inout [String: PyokoTag]
    ) throws -> [PyokoTag] {
        
        var tags:
            [PyokoTag] = []
        
        var seenNames:
            Set<String> = []
        
        let tagNames =
            names.isEmpty
            ? [defaultTagName]
            : names
        
        for name in tagNames {
            
            let trimmedName =
                name
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
            
            guard
                !trimmedName.isEmpty
            else {
                continue
            }
            
            guard
                seenNames
                    .insert(
                        trimmedName
                    )
                    .inserted
            else {
                continue
            }
            
            if let cachedTag =
                cache[
                    trimmedName
                ] {
                
                tags.append(
                    cachedTag
                )
                
                continue
            }
            
            let tagName =
                trimmedName
            
            let descriptor =
                FetchDescriptor<PyokoTag>(
                    predicate:
                        #Predicate<PyokoTag> {
                            tag in
                            
                            tag.name ==
                                tagName
                        }
                )
            
            if let existingTag =
                try modelContext
                    .fetch(
                        descriptor
                    )
                    .first {
                
                cache[
                    trimmedName
                ] =
                    existingTag
                
                tags.append(
                    existingTag
                )
                
                continue
            }
            
            let tag =
                PyokoTag(
                    name:
                        trimmedName
                )
            
            modelContext.insert(
                tag
            )
            
            cache[
                trimmedName
            ] =
                tag
            
            tags.append(
                tag
            )
        }
        
        return tags
    }
    
    // MARK: - CSV
    
    private func parseCSV(
        _ csv: String
    ) throws -> [ImportedWord] {
        
        let rows =
            try parseCSVRows(
                csv
            )
        
        // Row 1 is always the header.
        
        guard
            rows.count > 1
        else {
            
            throw DataLoaderError
                .noWordsFound
        }
        
        var words:
            [ImportedWord] = []
        
        for (
            index,
            row
        ) in rows
            .dropFirst()
            .enumerated() {
            
            let rowNumber =
                index + 2
            
            guard
                row.count == 4
            else {
                
                throw DataLoaderError
                    .invalidColumnCount(
                        row:
                            rowNumber,
                        values:
                            row
                    )
            }
            
            let sourceText =
                row[0]
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
            
            let targetText =
                row[1]
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
            
            let reading =
                row[2]
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
            
            let rawTags =
                row[3]
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
            
            guard
                !sourceText.isEmpty
            else {
                
                throw DataLoaderError
                    .missingSource(
                        row:
                            rowNumber,
                        values:
                            row
                    )
            }
            
            guard
                !targetText.isEmpty
            else {
                
                throw DataLoaderError
                    .missingTarget(
                        row:
                            rowNumber,
                        values:
                            row
                    )
            }
            
            let targetReading:
                String? =
                    reading.isEmpty
                    ? nil
                    : reading
            
            var tags =
                rawTags
                    .split(
                        separator: "|"
                    )
                    .map {
                        
                        String($0)
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )
                    }
                    .filter {
                        !$0.isEmpty
                    }
            
            if tags.isEmpty {
                
                tags = [
                    defaultTagName
                ]
            }
            
            words.append(
                ImportedWord(
                    sourceText:
                        sourceText,
                    targetText:
                        targetText,
                    targetReading:
                        targetReading,
                    tags:
                        tags
                )
            )
        }
        
        guard
            !words.isEmpty
        else {
            
            throw DataLoaderError
                .noWordsFound
        }
        
        return words
    }
    
    // MARK: - CSV Parser
    
    private func parseCSVRows(
        _ csv: String
    ) throws -> [[String]] {
        
        var rows:
            [[String]] = []
        
        var currentRow:
            [String] = []
        
        var currentField =
            ""
        
        var insideQuotes =
            false
        
        let characters =
            Array(csv)
        
        var index =
            0
        
        while
            index <
            characters.count {
            
            let character =
                characters[index]
            
            if character == "\"" {
                
                if insideQuotes,
                   index + 1 <
                    characters.count,
                   characters[
                    index + 1
                   ] == "\"" {
                    
                    currentField
                        .append("\"")
                    
                    index += 2
                    
                    continue
                }
                
                insideQuotes.toggle()
                
            } else if
                character == ",",
                !insideQuotes {
                
                currentRow.append(
                    currentField
                )
                
                currentField =
                    ""
                
            } else if (
                character == "\n" ||
                character == "\r"
            ) && !insideQuotes {
                
                if character == "\r",
                   index + 1 <
                    characters.count,
                   characters[
                    index + 1
                   ] == "\n" {
                    
                    index += 1
                }
                
                currentRow.append(
                    currentField
                )
                
                currentField =
                    ""
                
                let hasContent =
                    currentRow
                        .contains {
                            
                            !$0
                                .trimmingCharacters(
                                    in:
                                        .whitespacesAndNewlines
                                )
                                .isEmpty
                        }
                
                if hasContent {
                    
                    rows.append(
                        currentRow
                    )
                }
                
                currentRow =
                    []
                
            } else {
                
                currentField
                    .append(
                        character
                    )
            }
            
            index += 1
        }
        
        guard
            !insideQuotes
        else {
            
            throw DataLoaderError
                .invalidCSV
        }
        
        if
            !currentField.isEmpty ||
            !currentRow.isEmpty {
            
            currentRow.append(
                currentField
            )
            
            let hasContent =
                currentRow
                    .contains {
                        
                        !$0
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )
                            .isEmpty
                    }
            
            if hasContent {
                
                rows.append(
                    currentRow
                )
            }
        }
        
        return rows
    }
    
    // MARK: - HTML Detection
    
    private func looksLikeHTML(
        _ data: Data
    ) -> Bool {
        
        let prefix =
            data.prefix(
                1024
            )
        
        guard
            let string =
                String(
                    data: prefix,
                    encoding: .utf8
                )?
                .lowercased()
        else {
            return false
        }
        
        return
            string.contains(
                "<!doctype html"
            ) ||
            string.contains(
                "<html"
            )
    }
}

// MARK: - Imported Word

struct ImportedWord {
    
    let sourceText:
        String
    
    let targetText:
        String
    
    let targetReading:
        String?
    
    let tags:
        [String]
}

// MARK: - Errors

enum DataLoaderError:
    LocalizedError {
    
    case invalidURL
    
    case invalidGoogleSheetURL
    
    case googleSheetNotAccessible
    
    case downloadFailed(
        statusCode: Int
    )
    
    case emptyDeckName
    
    case deckAlreadyExists(
        name: String
    )
    
    case noCardTypesSelected
    
    case invalidEncoding
    
    case invalidCSV
    
    case invalidColumnCount(
        row: Int,
        values: [String]
    )
    
    case missingSource(
        row: Int,
        values: [String]
    )
    
    case missingTarget(
        row: Int,
        values: [String]
    )
    
    case noWordsFound
    
    var errorDescription:
        String? {
        
        switch self {
            
        case .invalidURL:
            
            return """
            The URL is invalid.
            """
            
        case .invalidGoogleSheetURL:
            
            return """
            The Google Sheets URL is invalid.
            
            Paste a normal Google Sheets sharing URL or a published Google Sheets URL.
            """
            
        case .googleSheetNotAccessible:
            
            return """
            Pyoko could not access this Google Sheet as CSV.
            
            Make sure the spreadsheet is publicly readable or has been published to the web.
            
            Private Google Sheets are not supported yet.
            """
            
        case .downloadFailed(
            let statusCode
        ):
            
            return """
            The file could not be downloaded.
            
            HTTP status: \(statusCode).
            """
            
        case .emptyDeckName:
            
            return """
            Please enter a deck name.
            """
            
        case .deckAlreadyExists(
            let name
        ):
            
            return """
            A deck named "\(name)" is already installed.
            
            Delete it before importing it again.
            """
            
        case .noCardTypesSelected:
            
            return """
            Select at least one card type.
            """
            
        case .invalidEncoding:
            
            return """
            The file must use UTF-8 encoding.
            """
            
        case .invalidCSV:
            
            return """
            The CSV file is invalid.
            
            Check that quotes are correctly opened and closed.
            """
            
        case .invalidColumnCount(
            let row,
            let values
        ):
            
            return """
            Row \(row) has \(values.count) columns, but Pyoko requires exactly 4.
            
            Expected:
            source,target,reading,tags
            
            Received:
            \(formatRow(values))
            """
            
        case .missingSource(
            let row,
            let values
        ):
            
            return """
            Row \(row) is missing its Source value.
            
            Expected:
            source,target,reading,tags
            
            Received:
            \(formatRow(values))
            """
            
        case .missingTarget(
            let row,
            let values
        ):
            
            return """
            Row \(row) is missing its Target value.
            
            Expected:
            source,target,reading,tags
            
            Received:
            \(formatRow(values))
            """
            
        case .noWordsFound:
            
            return """
            No vocabulary was found in the CSV file.
            """
        }
    }
    
    private func formatRow(
        _ values: [String]
    ) -> String {
        
        values.joined(
            separator: ","
        )
    }
}
