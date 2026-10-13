import CloudKit
import Testing
@testable import pyoko

@MainActor
struct CloudAccountCheckTests {
    @Test func repeatedChecksReportCompletionEvenWhenAccountIsUnchanged() async {
        let check = CloudAccountCheck()
        let first = Date(timeIntervalSince1970: 100)
        let second = Date(timeIntervalSince1970: 200)
        await check.check(fetchStatus: {
            #expect(check.isChecking)
            // A second request during an active check must not start another call.
            await check.check(fetchStatus: { Issue.record("Duplicate account request"); return .noAccount })
            return .available
        }, now: { first })
        #expect(!check.isChecking)
        #expect(check.message == "iCloud account available.")
        #expect(check.lastChecked == first)
        await check.check(fetchStatus: { .available }, now: { second })
        #expect(check.lastChecked == second)
        #expect(!check.isChecking)
    }

    @Test(arguments: [CKAccountStatus.noAccount, .restricted, .couldNotDetermine, .temporarilyUnavailable])
    func unavailableStatesReplaceSuccess(_ status: CKAccountStatus) async {
        let check = CloudAccountCheck()
        await check.check(fetchStatus: { .available })
        await check.check(fetchStatus: { status })
        #expect(check.message != "iCloud account available.")
        #expect(!check.isChecking && check.lastChecked != nil)
    }

    @Test func failedCheckShowsErrorAndCanBeRetried() async {
        enum Offline: Error { case unavailable }
        let check = CloudAccountCheck()
        await check.check(fetchStatus: { throw Offline.unavailable })
        #expect(check.message.hasPrefix("Could not check iCloud:"))
        #expect(!check.isChecking && check.lastChecked != nil)
        await check.check(fetchStatus: { .available })
        #expect(check.message == "iCloud account available.")
    }
}
