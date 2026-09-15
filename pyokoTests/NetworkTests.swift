import Foundation
import SwiftData
import Testing
@testable import pyoko

/// Stateless routing avoids shared mutable handlers when tests execute concurrently.
private final class CSVProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let url = request.url else { return }
        let path = url.path
        let status = path.contains("failure") ? 503 : 200
        let html = path.contains("private")
        let body = html ? "<html>Sign in</html>" : "source,target,reading,tags\neat,食べる,たべる,Verb"
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": html ? "text/html" : "text/csv"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@MainActor
struct NetworkTests {
    private func session() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [CSVProtocol.self]
        return URLSession(configuration: config)
    }

    @Test func importsRemoteCSVWithoutNetworkAccess() async throws {
        let s = try TestStore(); let network = session(); defer { network.invalidateAndCancel() }
        try await DataLoader(modelContext: s.context, session: network).loadFromURL(
            deckName: "Remote", urlString: "https://example.test/valid.csv", createRecognition: true, createRecall: false)
        let deck = try #require(s.context.fetch(FetchDescriptor<PyokoDeck>()).first)
        #expect(deck.origin == .url && deck.vocabularyCount == 1)
        #expect(try s.context.fetchCount(FetchDescriptor<PyokoCard>()) == 1)
    }

    @Test func rejectsHTTPFailuresAndInvalidURL() async throws {
        let s = try TestStore(); let network = session(); defer { network.invalidateAndCancel() }
        let loader = DataLoader(modelContext: s.context, session: network)
        await #expect(throws: (any Error).self) {
            try await loader.loadFromURL(deckName: "Fail", urlString: "https://example.test/failure", createRecognition: true, createRecall: true)
        }
        await #expect(throws: (any Error).self) {
            try await loader.loadFromURL(deckName: "Fail", urlString: "file:///tmp/file.csv", createRecognition: true, createRecall: true)
        }
        #expect(try s.context.fetchCount(FetchDescriptor<PyokoDeck>()) == 0)
    }

    @Test func rejectsPrivateGoogleSheetHTML() async throws {
        let s = try TestStore(); let network = session(); defer { network.invalidateAndCancel() }
        await #expect(throws: (any Error).self) {
            try await DataLoader(modelContext: s.context, session: network).loadFromGoogleSheet(
                deckName: "Private", urlString: "https://docs.google.com/spreadsheets/d/private/edit", createRecognition: true, createRecall: true)
        }
        #expect(try s.context.fetchCount(FetchDescriptor<PyokoDeck>()) == 0)
    }
}
