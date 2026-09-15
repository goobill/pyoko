import Foundation
import Testing
@testable import pyoko

@MainActor
struct UtilityTests {
    @Test(arguments: [
        ("https://docs.google.com/spreadsheets/d/abc/edit#gid=42", "abc:42", "/spreadsheets/d/abc/export"),
        (" https://docs.google.com/spreadsheets/d/abc/edit?gid=7#gid=42 ", "abc:7", "/spreadsheets/d/abc/export"),
        ("https://docs.google.com/spreadsheets/d/abc/edit", "abc:0", "/spreadsheets/d/abc/export"),
        ("https://docs.google.com/spreadsheets/d/e/pubID/pub?gid=3", "published:pubID:3", "/spreadsheets/d/e/pubID/pub")
    ])
    func sheetLinks(_ input: String, _ identifier: String, _ path: String) throws {
        let result = try GoogleSheetsCSVURL.makeReference(from: input)
        #expect(result.identifier == identifier && result.csvURL.path == path)
        #expect(result.csvURL.scheme == "https")
    }

    @Test(arguments: ["garbage", "ftp://docs.google.com/spreadsheets/d/abc/edit", "https://docs.google.com/spreadsheets/d/e/", "https://example.com/spreadsheets/d/abc", "https://docs.google.com/document/d/abc", "https://docs.google.com/spreadsheets/"])
    func rejectsNonSheetLinks(_ url: String) {
        #expect(throws: (any Error).self) { try GoogleSheetsCSVURL.makeReference(from: url) }
    }

    @Test(arguments: [(-1.0,"<1m"),(59.0,"<1m"),(60.0,"1m"),(3600.0,"1h"),(86400.0,"1d"),(2592000.0,"1mo"),(31536000.0,"1y")])
    func intervalBoundaries(_ seconds: Double, _ label: String) {
        let now = Date(timeIntervalSince1970: 0)
        #expect(ReviewIntervalFormatter.string(from: now, to: now.addingTimeInterval(seconds)) == label)
    }

    @Test func displayLabelsDoNotChangeStoredValues() throws {
        #expect(TargetDisplayMode.target.title == "Kanji")
        #expect(TargetDisplayMode.reading.title == "Hiragana")
        #expect(TargetDisplayMode.targetAndReading.title == "Kanji + Hiragana")
        #expect(!TargetDisplayMode.target.includesReading)
        #expect(TargetDisplayMode.targetAndReading.includesReading && TargetDisplayMode.targetAndReading.includesTarget)
        #expect(try JSONDecoder().decode(TargetDisplayMode.self, from: Data(#""targetAndReading""#.utf8)) == .targetAndReading)
        #expect(ReviewProgress(completed: 5, total: 3).remaining == 0)
    }
}
