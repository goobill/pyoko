import CloudKit
import Observation

/// Reports account access only. SwiftData owns syncing and its completion state.
@MainActor @Observable
final class CloudAccountCheck {
    private(set) var isChecking = false
    private(set) var message = "Account not checked yet."
    private(set) var lastChecked: Date?

    func check(
        fetchStatus: @MainActor () async throws -> CKAccountStatus = {
            try await CKContainer(identifier: PyokoCloud.containerIdentifier).accountStatus()
        },
        now: @MainActor () -> Date = { Date() }
    ) async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }
        do {
            let status = try await fetchStatus()
            switch status {
            case .available: message = "iCloud account available."
            case .noAccount: message = "Sign in to iCloud in your device's Settings to sync."
            case .restricted: message = "iCloud access is restricted on this device."
            case .couldNotDetermine, .temporarilyUnavailable:
                message = "iCloud is temporarily unavailable. Try again later."
            @unknown default: message = "Unable to determine iCloud availability."
            }
        } catch {
            message = "Could not check iCloud: \(error.localizedDescription)"
        }
        lastChecked = now()
    }
}
