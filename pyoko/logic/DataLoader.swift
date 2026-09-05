import Foundation
import SwiftData

@MainActor
final class DataLoader {
    
    private let modelContext: ModelContext
    
    private let defaultTagName = "No Tag"
    
    init(
        modelContext: ModelContext
    ) {
        self.modelContext = modelContext
    }
    
    // MARK: - URL
    
    func loadFromURL(
        sourceName: String,
        urlString: String,
        createRecognition: Bool,
        createRecall: Bool,
        catalogKey: String? = nil,
        origin: DataSourceOrigin = .custom
    ) async throws {
        
        let trimmedURL = urlString
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        
        guard
            let url = URL(string: trimmedURL),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            throw DataLoaderError.invalidURL
        }
        
        let (data, response) =
            try await URLSession.shared.data(
                from: url
            )
        
        if let httpResponse =
            response as? HTTPURLResponse,
           !(200...299).contains(
                httpResponse.statusCode
           ) {
            
            throw DataLoaderError.downloadFailed(
                statusCode:
                    httpResponse.statusCode
            )
        }
        
        try importCSV(
            data: data,
            sourceName: sourceName,
            catalogKey: catalogKey,
            origin: origin,
            createRecognition: createRecognition,
            createRecall: createRecall
        )
    }
    
    // MARK: - Local File
    
    func loadFromFile(
        sourceName: String,
        url: URL,
        createRecognition: Bool,
        createRecall: Bool
    ) throws {
        
        let accessingSecurityScopedResource =
            url.startAccessingSecurityScopedResource()
        
        defer {
            
            if accessingSecurityScopedResource {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let data = try Data(
            contentsOf: url
        )
        
        try importCSV(
            data: data,
            sourceName: sourceName,
            catalogKey: nil,
            origin: .custom,
            createRecognition: createRecognition,
            createRecall: createRecall
        )
    }
    
    // MARK: - Import
    
    private func importCSV(
        data: Data,
        sourceName: String,
        catalogKey: String?,
        origin: DataSourceOrigin,
        createRecognition: Bool,
        createRecall: Bool
    ) throws {
        
        guard
            createRecognition ||
            createRecall
        else {
            throw DataLoaderError.noCardTypesSelected
        }
        
        let sourceName =
            sourceName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        
        guard !sourceName.isEmpty else {
            throw DataLoaderError.emptySourceName
        }
        
        guard let csv = String(
            data: data,
            encoding: .utf8
        ) else {
            throw DataLoaderError.invalidEncoding
        }
        
        let words = try parseCSV(csv)
        
        try ensureSourceDoesNotExist(
            name: sourceName,
            catalogKey: catalogKey
        )
        
        let source = PyokoDataSource(
            catalogKey: catalogKey,
            name: sourceName,
            origin: origin,
            vocabularyCount: words.count,
            recognitionCount:
                createRecognition
                ? words.count
                : 0,
            recallCount:
                createRecall
                ? words.count
                : 0,
            importedAt: .now
        )
        
        modelContext.insert(source)
        
        var tagCache:
            [String: PyokoTag] = [:]
        
        for word in words {
            
            let tags = try getOrCreateTags(
                names: word.tags,
                cache: &tagCache
            )
            
            if createRecognition {
                
                let card = PyokoCard(
                    type: .recognition,
                    sourceText: word.sourceText,
                    targetText: word.targetText,
                    targetReading: word.targetReading,
                    source: source,
                    tags: tags
                )
                
                modelContext.insert(card)
            }
            
            if createRecall {
                
                let card = PyokoCard(
                    type: .recall,
                    sourceText: word.sourceText,
                    targetText: word.targetText,
                    targetReading: word.targetReading,
                    source: source,
                    tags: tags
                )
                
                modelContext.insert(card)
            }
        }
        
        try modelContext.save()
    }
    
    // MARK: - Source Validation
    
    private func ensureSourceDoesNotExist(
        name: String,
        catalogKey: String?
    ) throws {
        
        if let catalogKey {
            
            let key = catalogKey
            
            let descriptor =
                FetchDescriptor<PyokoDataSource>(
                    predicate:
                        #Predicate<PyokoDataSource> {
                            source in
                            
                            source.catalogKey == key
                        }
                )
            
            if try modelContext
                .fetch(descriptor)
                .first != nil {
                
                throw DataLoaderError
                    .sourceAlreadyExists(
                        name: name
                    )
            }
        }
        
        let sourceName = name
        
        let descriptor =
            FetchDescriptor<PyokoDataSource>(
                predicate:
                    #Predicate<PyokoDataSource> {
                        source in
                        
                        source.name == sourceName
                    }
            )
        
        if try modelContext
            .fetch(descriptor)
            .first != nil {
            
            throw DataLoaderError
                .sourceAlreadyExists(
                    name: name
                )
        }
    }
    
    // MARK: - Tags
    
    private func getOrCreateTags(
        names: [String],
        cache: inout [String: PyokoTag]
    ) throws -> [PyokoTag] {
        
        var tags: [PyokoTag] = []
        
        var seenNames: Set<String> = []
        
        let tagNames =
            names.isEmpty
                ? [defaultTagName]
                : names
        
        for name in tagNames {
            
            let trimmedName =
                name.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            
            guard !trimmedName.isEmpty else {
                continue
            }
            
            guard
                seenNames
                    .insert(trimmedName)
                    .inserted
            else {
                continue
            }
            
            if let cachedTag =
                cache[trimmedName] {
                
                tags.append(cachedTag)
                continue
            }
            
            let tagName = trimmedName
            
            let descriptor =
                FetchDescriptor<PyokoTag>(
                    predicate:
                        #Predicate<PyokoTag> {
                            tag in
                            
                            tag.name == tagName
                        }
                )
            
            if let existingTag =
                try modelContext
                    .fetch(descriptor)
                    .first {
                
                cache[trimmedName] =
                    existingTag
                
                tags.append(existingTag)
                
                continue
            }
            
            let tag = PyokoTag(
                name: trimmedName
            )
            
            modelContext.insert(tag)
            
            cache[trimmedName] = tag
            
            tags.append(tag)
        }
        
        return tags
    }
    
    // MARK: - CSV
    
    private func parseCSV(
        _ csv: String
    ) throws -> [ImportedWord] {
        
        let rows = try parseCSVRows(csv)
        
        // Row 1 is always treated as the header.
        
        guard rows.count > 1 else {
            throw DataLoaderError.noWordsFound
        }
        
        var words: [ImportedWord] = []
        
        for (
            index,
            row
        ) in rows
            .dropFirst()
            .enumerated() {
            
            // +2 because:
            // index starts at 0 and
            // row 1 is the header.
            
            let rowNumber = index + 2
            
            // Every row must always be:
            //
            // source,target,reading,tags
            
            guard row.count == 4 else {
                
                throw DataLoaderError.invalidColumnCount(
                    row: rowNumber,
                    values: row
                )
            }
            
            let sourceText =
                row[0].trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            
            let targetText =
                row[1].trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            
            let reading =
                row[2].trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            
            let rawTags =
                row[3].trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            
            // Source is required.
            
            guard !sourceText.isEmpty else {
                
                throw DataLoaderError.missingSource(
                    row: rowNumber,
                    values: row
                )
            }
            
            // Target is required.
            
            guard !targetText.isEmpty else {
                
                throw DataLoaderError.missingTarget(
                    row: rowNumber,
                    values: row
                )
            }
            
            // Reading is optional.
            
            let targetReading: String? =
                reading.isEmpty
                    ? nil
                    : reading
            
            // Tags are optional.
            
            var tags =
                rawTags
                    .split(separator: "|")
                    .map {
                        
                        String($0)
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                    }
                    .filter {
                        !$0.isEmpty
                    }
            
            // No tags -> "No Tag"
            
            if tags.isEmpty {
                tags = [defaultTagName]
            }
            
            words.append(
                ImportedWord(
                    sourceText: sourceText,
                    targetText: targetText,
                    targetReading: targetReading,
                    tags: tags
                )
            )
        }
        
        guard !words.isEmpty else {
            throw DataLoaderError.noWordsFound
        }
        
        return words
    }
    
    // MARK: - CSV Row Parser
    
    private func parseCSVRows(
        _ csv: String
    ) throws -> [[String]] {
        
        var rows: [[String]] = []
        
        var currentRow: [String] = []
        
        var currentField = ""
        
        var insideQuotes = false
        
        let characters = Array(csv)
        
        var index = 0
        
        while index < characters.count {
            
            let character =
                characters[index]
            
            if character == "\"" {
                
                // Escaped quote inside a quoted field:
                //
                // "Hello ""World"""
                
                if insideQuotes,
                   index + 1 < characters.count,
                   characters[index + 1] == "\"" {
                    
                    currentField.append("\"")
                    
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
                
                currentField = ""
                
            } else if (
                character == "\n" ||
                character == "\r"
            ) && !insideQuotes {
                
                // Handle Windows CRLF.
                
                if character == "\r",
                   index + 1 < characters.count,
                   characters[index + 1] == "\n" {
                    
                    index += 1
                }
                
                currentRow.append(
                    currentField
                )
                
                currentField = ""
                
                let hasContent =
                    currentRow.contains {
                        
                        !$0
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                    }
                
                if hasContent {
                    rows.append(currentRow)
                }
                
                currentRow = []
                
            } else {
                
                currentField.append(
                    character
                )
            }
            
            index += 1
        }
        
        // If a quote was opened but never closed,
        // the CSV is malformed.
        
        guard !insideQuotes else {
            throw DataLoaderError.invalidCSV
        }
        
        if !currentField.isEmpty ||
            !currentRow.isEmpty {
            
            currentRow.append(
                currentField
            )
            
            let hasContent =
                currentRow.contains {
                    
                    !$0
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty
                }
            
            if hasContent {
                rows.append(currentRow)
            }
        }
        
        return rows
    }
}

// MARK: - Imported Word

struct ImportedWord {
    
    let sourceText: String
    
    let targetText: String
    
    let targetReading: String?
    
    let tags: [String]
}

// MARK: - Errors

enum DataLoaderError: LocalizedError {
    
    case invalidURL
    
    case downloadFailed(
        statusCode: Int
    )
    
    case emptySourceName
    
    case sourceAlreadyExists(
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
    
    var errorDescription: String? {
        
        switch self {
            
        case .invalidURL:
            
            return "The URL is invalid."
            
        case .downloadFailed(
            let statusCode
        ):
            
            return """
            The file could not be downloaded.
            
            HTTP status: \(statusCode).
            """
            
        case .emptySourceName:
            
            return "Please enter a source name."
            
        case .sourceAlreadyExists(
            let name
        ):
            
            return """
            A data source named "\(name)" is already installed.
            
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
            
            Source and Target are required.
            
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
            
            Source and Target are required.
            
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
    
    // MARK: - Error Formatting
    
    private func formatRow(
        _ values: [String]
    ) -> String {
        
        values.joined(
            separator: ","
        )
    }
}
