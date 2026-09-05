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
        origin: DataSourceOrigin = DataSourceOrigin.custom
    ) async throws {
        
        let trimmedURL = urlString
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        
        guard
            let url = URL(
                string: trimmedURL
            ),
            let scheme = url.scheme?
                .lowercased(),
            scheme == "http" ||
            scheme == "https"
        else {
            throw DataLoaderError.invalidURL
        }
        
        let (
            data,
            response
        ) = try await URLSession.shared.data(
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
            origin: DataSourceOrigin.custom,
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
        
        guard createRecognition ||
              createRecall
        else {
            throw DataLoaderError
                .noCardTypesSelected
        }
        
        let sourceName = sourceName
            .trimmingCharacters(
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
        
        let words = try parseCSV(
            csv
        )
        
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
            importedAt: Date.now
        )
        
        modelContext.insert(
            source
        )
        
        // Prevent repeated SwiftData queries for
        // the same tags during one import.
        var tagCache:
            [String: PyokoTag] = [:]
        
        for word in words {
            
            let tags = try getOrCreateTags(
                names: word.tags,
                cache: &tagCache
            )
            
            if createRecognition {
                
                let card = PyokoCard(
                    type:
                        CardType.recognition,
                    english:
                        word.english,
                    japanese:
                        word.japanese,
                    source:
                        source,
                    tags:
                        tags
                )
                
                modelContext.insert(
                    card
                )
            }
            
            if createRecall {
                
                let card = PyokoCard(
                    type:
                        CardType.recall,
                    english:
                        word.english,
                    japanese:
                        word.japanese,
                    source:
                        source,
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
                        
                        source.name ==
                            sourceName
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
            
            let trimmedName = name
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            
            guard !trimmedName.isEmpty else {
                continue
            }
            
            guard seenNames
                .insert(trimmedName)
                .inserted
            else {
                continue
            }
            
            // Already encountered during
            // this import.
            
            if let cachedTag =
                cache[trimmedName] {
                
                tags.append(
                    cachedTag
                )
                
                continue
            }
            
            let tagName = trimmedName
            
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
                    .fetch(descriptor)
                    .first {
                
                cache[trimmedName] =
                    existingTag
                
                tags.append(
                    existingTag
                )
                
                continue
            }
            
            let tag = PyokoTag(
                name: trimmedName
            )
            
            modelContext.insert(
                tag
            )
            
            cache[trimmedName] = tag
            
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
        
        let rows = try parseCSVRows(
            csv
        )
        
        // First row is always ignored
        // as the header.
        
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
            
            let rowNumber =
                index + 2
            
            // Exact format:
            //
            // English, Japanese, Tags
            
            guard row.count == 3 else {
                
                throw DataLoaderError
                    .invalidRow(
                        row: rowNumber
                    )
            }
            
            let english = row[0]
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            
            let japanese = row[1]
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            
            guard
                !english.isEmpty,
                !japanese.isEmpty
            else {
                
                throw DataLoaderError
                    .invalidRow(
                        row: rowNumber
                    )
            }
            
            var tags = row[2]
                .split(
                    separator: "|"
                )
                .map {
                    String($0)
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
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
                    english:
                        english,
                    japanese:
                        japanese,
                    tags:
                        tags
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
        
        let characters =
            Array(csv)
        
        var index = 0
        
        while index <
                characters.count {
            
            let character =
                characters[index]
            
            if character == "\"" {
                
                // Escaped quote: ""
                
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
                
                currentField = ""
                
            } else if (
                character == "\n" ||
                character == "\r"
            ) && !insideQuotes {
                
                // Windows CRLF
                
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
                    rows.append(
                        currentRow
                    )
                }
                
                currentRow = []
                
            } else {
                
                currentField.append(
                    character
                )
            }
            
            index += 1
        }
        
        // Unclosed quote.
        
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
                rows.append(
                    currentRow
                )
            }
        }
        
        return rows
    }
}

// MARK: - Imported Word

struct ImportedWord {
    
    let english: String
    
    let japanese: String
    
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
    
    case invalidRow(
        row: Int
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
            The file could not be downloaded. HTTP status: \(statusCode).
            """
            
        case .emptySourceName:
            
            return "Please enter a source name."
            
        case .sourceAlreadyExists(
            let name
        ):
            
            return """
            A data source named "\(name)" is already installed. Delete it before importing it again.
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
            """
            
        case .invalidRow(
            let row
        ):
            
            return """
            Row \(row) is invalid. Every row must contain exactly English, Japanese, and Tags.
            """
            
        case .noWordsFound:
            
            return """
            No vocabulary was found in the CSV file.
            """
        }
    }
}
