# Run Pyoko on iPhone and Mac

## 1. Signing and CloudKit

1. Open `pyoko.xcodeproj` in Xcode. Select the **pyoko** scheme.
2. In Xcode Settings → Apple Accounts, sign in. In Signing & Capabilities, select your team for **pyoko** and **PyokoWidgetsExtension**, with automatic signing enabled. The supplied team and bundle IDs are retained from your project.
3. For **pyoko**, confirm iCloud → CloudKit is enabled and create/select **iCloud.com.goobill.pyoko** under your team. The project configuration cannot register the container in your developer account by itself.
4. Confirm Push Notifications and, for iOS, Background Modes → Remote notifications. Both app and widget must have **group.com.goobill.pyoko** registered and enabled for their App Groups capability.
5. If you change your bundle or group IDs, update the app/extension build settings, `PyokoCloud.swift`, both app entitlement files, the widget entitlement file and `PyokoWidgetConstants.swift` consistently. Use one CloudKit container for both platforms.

CloudKit requires an active Apple Developer Program membership (normally US$99/year or the local equivalent). A free Personal Team can be used for basic on-device testing but cannot provision this CloudKit-enabled setup. Its provisioning profiles expire after seven days, so rebuild and reinstall from Xcode then. TestFlight beta distribution requires paid membership.

## 2. Run on your iPhone

1. Connect and trust your iPhone from your Mac. Enable **Developer Mode** under iPhone Settings → Privacy & Security when prompted; restart/confirm as instructed.
2. Choose your iPhone as Xcode's run destination and press Run. Resolve any signing/profile issues shown by Xcode.
3. Use iOS 26 or newer. An iPhone 15 does not need Apple Intelligence for this version.
4. In Decks, install N5 or N4. Each deck installs both recognition and recall cards; use Config to control which directions you review.

You can pair the phone for wireless debugging in Xcode after the initial connection. TestFlight is optional for later distribution and requires your Apple developer/App Store Connect setup.

## 3. Run on your Mac and test sync

1. Sign into the **same iCloud Apple Account** on phone and Mac, and allow Pyoko to use iCloud on both devices. This account is distinct from the Xcode signing account.
2. Run the app first on the device containing your existing data. Keep the app open and online while its initial upload completes. Use a backup/test copy of important data when testing an upgrade; do not uninstall the old app to resolve migration errors.
3. Choose **My Mac** as the destination and Run the same scheme. Wait for the original deck to appear. **Do not install the same seed separately on both devices while waiting.** Each independent install creates different record IDs and CloudKit does not enforce catalogue-key uniqueness across devices.
4. Disable N5 on one device. Wait for the other device's Decks screen and review config to show the same disabled state. Enable it again and confirm propagation.
5. Review one card on the phone, exit the session, then reopen Review on the Mac after sync. Confirm progress moved forward. Repeat in the opposite direction.
6. Change a review limit, quick config and a tag selection and confirm propagation. Change the theme and confirm it stays local to that device.
7. Test offline edits on one device, reconnect, then check the other device. Test deletion with a disposable deck; deck deletion and its card cascade sync too.

The Settings check reports **account availability only**, not upload/download completion. SwiftData/CloudKit sync is asynchronous; there is no forced-sync button or guaranteed immediate delivery. Inspect Xcode/Core Data + CloudKit logs and the CloudKit Console Development database if records do not appear. Build both copies against the same Development environment during testing. Before TestFlight/App Store use, deploy the development schema to Production in CloudKit Console, then validate Production separately.

## 4. Known limits before broader release

- Avoid simultaneous scheduled reviews on phone and Mac. Both devices currently update the same FSRS record; this implementation does not combine concurrent ratings or independent offline queues. Reopen a session after changing devices so its local UI state reloads.
- Catalogue-key duplicate checks only see locally available records. This prevents repeated local installation, not two devices installing independently before sync. Existing independent decks/history on two devices are not automatically deduplicated.
- Configs choose the oldest creation date after sync. Settings entered into a newer temporary config may be superseded by the older config. Existing independently created pre-update configs both have the legacy zero date; do not treat this as an automatic merge of two established databases.
- All builds use the Pyoko store name. Sentence settings and their relationships have now been removed from the schema; upgrade/migration must be tested using a backup copy of your real store. Startup still reports a container initialization failure rather than deleting the store or silently creating a different database.
- Signed-device builds, Xcode tests, actual macOS rendering and end-to-end sync have not been run in this editing environment.

For a future multi-device release, add explicit duplicate reconciliation and immutable review-event records with deterministic scheduling replay. That is the appropriate next step if you want to review concurrently on multiple offline devices.

## 5. Build and regression checklist

Run Product → Test for **My Mac** and an iOS simulator/device. Added unit tests use an in-memory store with CloudKit disabled; the app hosting them still needs valid signing for its configured capabilities.

- Confirm both `jlpt_n4.csv` and `jlpt_n5.csv` are in the built app resources. The project uses Xcode-synchronised folders, so no manual source-file registration should be needed.
- Install with networking off: N5 should show 644 words / 1,288 cards; N4 571 words / 1,142 cards.
- Disable N5, then install N4; N5 must stay disabled and N4 start enabled.
- Confirm Review → Config, Quick Review, Manage → Decks and the Settings cog work on phone and Mac; Mac Settings also opens with Command-comma. Verify Exit returns from both review modes.
- Confirm light/dark/system themes; resize the Mac window; test typing with Japanese input in Quick Review.
- Open a copy of the previous app's store, checking decks, FSRS values and selections survived.
- Repeat the two-device sync checks above before relying on cross-device progress.

## Apple references

- [SwiftData sync across devices](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)
- [Run on a physical device](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)
- [Apple CloudKit/Core Data sync sample](https://github.com/apple/sample-cloudkit-coredatasync)

## Push capability does not mean visible notifications

CloudKit uses silent background push notifications to receive data changes. Keep iCloud, Push Notifications and Remote notifications background mode for the CloudKit build. Do not add notification authorization requests for alerts, sounds or badges: Pyoko does not need them. The current source has no such requests or local notification scheduling.

If Xcode says “Personal development teams … do not support Push Notifications and iCloud”, this is a signing limitation, not a user permission problem. For cloud sync, select an enrolled Apple Developer Program team, enable the app's container and capabilities, and let automatic signing recreate compatible profiles. A Personal Team cannot fix this with Try Again alone.
