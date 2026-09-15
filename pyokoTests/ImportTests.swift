import Foundation
import SwiftData
import Testing
@testable import pyoko

@MainActor
struct ImportTests {
    @Test(arguments: ["\n", "\r\n", "\r"])
    func acceptsLineEndingsAndQuotedCommas(_ newline: String) throws {
        let store = try TestStore()
        try store.importCSV(["source,target,reading,tags", "\"to bathe, to shower\",浴びる,あびる,N5|Verb"].joined(separator: newline))
        let cards = try store.context.fetch(FetchDescriptor<PyokoCard>())
        #expect(cards.count == 2)
        #expect(Set(cards.map(\.type)) == [.recall, .recognition])
        #expect(cards.allSatisfy { $0.sourceText == "to bathe, to shower" && $0.targetReading == "あびる" })
        #expect(try store.context.fetchCount(FetchDescriptor<PyokoTag>()) == 2)
    }

    @Test func acceptsBOMAndEmptyHiragana() throws {
        let store = try TestStore()
        try store.importCSV("\u{FEFF}source,target,reading,tags\nhello,こんにちは,,", recall: false)
        let card = try #require(store.context.fetch(FetchDescriptor<PyokoCard>()).first)
        #expect(card.targetReading == nil)
        #expect(card.tags?.first?.name == "No Tag")
        #expect(card.type == .recognition)
    }

    @Test func preservesEscapedQuotesAndEmbeddedNewlines() throws {
        let store = try TestStore()
        try store.importCSV("source,target,reading,tags\n\"say \"\"hello\"\"\nand smile\",笑う,わらう,Verb")
        let card = try #require(store.context.fetch(FetchDescriptor<PyokoCard>()).first)
        #expect(card.sourceText == "say \"hello\"\nand smile")
    }

    @Test(arguments: [
        "source,target,reading,tags\n", "target,source,reading,tags\n食べる,eat,たべる,Verb",
        "source,target,reading,tags\neat,食べる,たべる", "source,target,reading,tags\n,食べる,たべる,Verb",
        "source,target,reading,tags\neat,,たべる,Verb", "source,target,reading,tags\n\"unfinished,食べる,たべる,Verb"
    ])
    func rejectsMalformedDataWithoutPartialRecords(_ csv: String) throws {
        let store = try TestStore()
        #expect(throws: (any Error).self) { try store.importCSV(csv) }
        #expect(try store.context.fetchCount(FetchDescriptor<PyokoDeck>()) == 0)
        #expect(try store.context.fetchCount(FetchDescriptor<PyokoCard>()) == 0)
        #expect(try store.context.fetchCount(FetchDescriptor<PyokoTag>()) == 0)
    }

    @Test func rejectsNoDirectionsAndDuplicateDeckNames() throws {
        let store = try TestStore()
        let csv = "source,target,reading,tags\neat,食べる,たべる,Verb"
        #expect(throws: (any Error).self) { try store.importCSV(csv, recognition: false, recall: false) }
        try store.importCSV(csv)
        #expect(throws: (any Error).self) { try store.importCSV(csv) }
        #expect(try store.context.fetchCount(FetchDescriptor<PyokoDeck>()) == 1)
    }
}
