import Foundation
import SwiftData

@MainActor
final class DataLoader {

    private let modelContext: ModelContext
    private let session: URLSession

    private let defaultTagName =
        "No Tag"

    init(
        modelContext: ModelContext,
        session: URLSession = .shared
    ) {
        self.session = session
        self.modelContext =
            modelContext
    }

    /// Install the shipped CSV using the same parser and enablement as imports.
    func loadBundledDeck(_ deck: DefaultDeck, bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: deck.resourceName, withExtension: "csv")
            ?? bundle.url(forResource: deck.resourceName, withExtension: "csv", subdirectory: "seed") else {
            throw BundledDeckError.missingResource(deck.resourceName)
        }
        // Save pending UI edits before starting, so rollback only undoes this install.
        // Use the view's context so enablement and deck rows update immediately.
        try modelContext.save()
        do {
            try importCSV(
                data: Data(contentsOf: url), deckName: deck.name,
                catalogKey: deck.key, origin: .builtIn,
                originName: url.lastPathComponent, originURLString: nil,
                originIdentifier: deck.key, createRecognition: true, createRecall: true
            )
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    // MARK: - URL

    /// Downloads and validates a CSV before creating a deck and its selected card directions.
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
            urlString.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard
            let url =
                URL(
                    string: trimmedURL
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

    /// Converts a public Sheet link to CSV; rejects HTTP failures and private HTML sign-in pages.
    func loadFromGoogleSheet(
        deckName: String,
        urlString: String,
        createRecognition: Bool,
        createRecall: Bool
    ) async throws {

        let reference =
            try GoogleSheetsCSVURL
                .makeReference(
                    from: urlString
                )

        let (
            data,
            response
        ) =
            try await downloadWithResponse(
                from: reference.csvURL
            )

        /*
         A private Google Sheet may return
         an HTML login/access page instead
         of CSV.
        */

        if response.mimeType?
            .lowercased()
            .contains(
                "text/html"
            ) == true ||
            looksLikeHTML(
                data
            ) {

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

    // MARK: - File

    /// Reads a security-scoped CSV and preserves existing deck selections when importing.
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
            try await session.data(
                    from: url
                )

        if let httpResponse =
            response as? HTTPURLResponse {

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

    /// Validates all rows before inserting the deck, shared tags and vocabulary cards.
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

        let trimmedDeckName =
            deckName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard
            !trimmedDeckName.isEmpty
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
            name: trimmedDeckName,
            catalogKey: catalogKey
        )

        // MARK: Create Deck

        let deck =
            PyokoDeck(
                catalogKey:
                    catalogKey,
                name:
                    trimmedDeckName,
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

        // MARK: Create Cards

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

        /*
         Automatically enable the newly
         imported deck in the user's existing
         review config.

         This is especially important when the
         config was created while there
         were no decks installed.

         We only add the NEW deck.

         Previously deselected decks remain
         deselected.
        */

        try selectNewDeckInConfig(
            deck
        )

        try modelContext.save()
    }

    // MARK: - Automatically Select Imported Deck

    private func selectNewDeckInConfig(
        _ deck: PyokoDeck
    ) throws {

        let descriptor =
            FetchDescriptor<PyokoConfig>(sortBy: [SortDescriptor(\PyokoConfig.createdAt)])

        /*
         If no config exists yet,
         there is nothing to update.

         When ConfigView eventually
         creates its first config, it
         already defaults to selecting all
         installed decks.
        */

        guard
            let config =
                try modelContext
                    .fetch(
                        descriptor
                    )
                    .first
        else {
            return
        }

        var selectedDecks =
            config
                .selectedDecks ??
            []

        /*
         Defensive duplicate check.

         This should normally never be hit for
         a newly created deck, but it keeps the
         relationship clean.
        */

        guard
            !selectedDecks
                .contains(
                    where: {
                        $0.id == deck.id
                    }
                )
        else {
            return
        }

        selectedDecks.append(
            deck
        )

        config.selectedDecks =
            selectedDecks
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

        guard
            rows.count > 1
        else {

            throw DataLoaderError
                .noWordsFound
        }

        let header = rows[0].map {
            $0.replacingOccurrences(of: "\u{FEFF}", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        guard header == ["source", "target", "reading", "tags"] else {
            throw DataLoaderError.invalidHeader
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
            Array(csv.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n"))

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
            ) &&
            !insideQuotes {

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
                    data:
                        prefix,
                    encoding:
                        .utf8
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
    case invalidHeader

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

        case .invalidHeader:
            return "CSV columns must be source,target,reading,tags, in that order."

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
            Row \(row) is missing its English value.

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
            Row \(row) is missing its Kanji value.

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

private enum BundledDeckError: LocalizedError {
    case missingResource(String)
    var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            return "The bundled deck \(name).csv is missing. Check the app target's Copy Bundle Resources."
        }
    }
}
