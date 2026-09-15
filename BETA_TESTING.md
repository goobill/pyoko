# Pyoko 1.0 beta verification

This repository is a beta candidate. Automated tests have been written, but have not been compiled or run in the editing environment (no Xcode/Apple SDKs). Do not interpret the source checks as a passing XCTest run or a coverage percentage.

## Run in Xcode

Open `pyoko.xcodeproj`, select the **pyoko** scheme, and resolve signing for both app and widget with your enrolled developer team. Choose **My Mac** or an iOS simulator/device, then Product → Test. Coverage collection is enabled in the shared scheme; inspect the Test report in Xcode for results, screenshots and per-file coverage.

The application uses exactly the same iCloud-enabled configuration during development, testing and release. Unit/integration tests construct their own in-memory SwiftData containers and disposable widget preference suites using the normal service APIs. The app itself has no environment-dependent test or storage modes.

UI tests operate on real application data. They skip by default. Use a dedicated test device or simulator and a dedicated iCloud account with no valuable data; start with an empty app store. In the scheme's Test action, disable “Use the Run action's arguments and environment variables” if necessary and add **PYOKO_ALLOW_UI_TESTS = 1** to the test runner environment. Only the UI test runner reads this opt-in; app code does not. Clear the disposable test data between complete UI test runs, including synced test records as necessary. Never run this suite against your personal study account.

Run on both macOS and iOS before beta deployment. No Swift test execution or measured coverage figure is available from this editing environment.

## Automated coverage map

| Area | Tests / behaviour |
| --- | --- |
| Bundled N4/N5 | Row/card counts, installed origin, enabled state, preserving disabled decks, duplicate catalogue installs, missing resources |
| CSV/file import | LF/CRLF/CR, quoted commas, escaped quotes, embedded newlines, BOM, optional Hiragana, shared tags, malformed rows/header, empty values, duplicate names, no directions |
| URL / Sheets import | Stubbed success, HTTP failure, unsupported URL schemes, private Sheet HTML; no live network required |
| Sheet links / display formatting | Normal/published links, gid precedence/default, invalid links, time interval boundaries, Japanese labels and stable Codable values |
| Deck management | Idempotent enablement, tag cleanup, cascaded deletion, retaining unrelated decks, singleton config creation |
| Scheduled review | Deck/tag/direction/due filters, limits/new-card reservation, later-today separation, exclusions, resumed queues, non-mutating interval preview, rating persistence, duplicate-rating rejection, extension guard, next-day/reset behaviour |
| Quick review | Source filtering, deduplication, direction/limit selection, empty states, incorrect retry, corrected totals, reset, no FSRS writes |
| Today's vocabulary | Completed cards only, prior-day/pending/orphan exclusion, deduplication and tag union |
| Persistence/config | Shared schema creation, saved relationships, independent review/quick values, oldest config selection, current six-model schema |
| Widget | Legacy JSON, deck labels, enabled-deck filtering, per-deck deduplication, corrupt cache, invalid indexes, reveal/next, snapshot reorder, direction normalization and answer reset, empty/single-word handling |
| SwiftUI | Header bounds, installation and persistent enablement, delete/cancel/reinstall, incomplete import, hint and writing previews, direction guard, widget filters and preview, real quick retry/reset, all review ratings, Mac shortcuts, ten palettes/tints, screenshot capture |

Date-sensitive services accept an injected clock; tests use a fixed midday date. Network tests inject an ephemeral URLSession with a stateless URLProtocol. Randomised selectors are tested by allowed sets, counts and invariants rather than asserting a particular shuffle order.

## Required device and release checks

These checks cannot be replaced by the automated in-memory suites:

- Run the suite on both iOS and macOS; resolve compilation or UI-selector failures before archiving.
- Install an upgrade over a backup/test copy of your existing app store. Verify decks, tags, FSRS fields and both configs survive. Creating a current-schema in-memory store does not prove an old-store migration works.
- Run an actual scheduled review, extend it, retry quick-review mistakes and test Japanese keyboard input on the phone. Resize Mac windows and check dark mode, accessibility text sizes and VoiceOver.
- Add the widget on each platform. Verify deck names, reveal/next actions and changes after enabling/disabling decks. UI tests do not automate SpringBoard, the Mac desktop or WidgetKit's delivery schedule.
- Follow `SETUP.md` to verify real CloudKit sync in both directions with the same iCloud account, then offline/reconnect and a disposable deck deletion. CloudKit transport is not mocked as proof of sync.
- Use sequential reviews on the two devices. Concurrent/offline rating reconciliation and cross-device duplicate-deck repair are not implemented in this v1 candidate. Install seeds on one device and wait for them on the other.
- Before TestFlight, deploy the CloudKit Development schema to Production, archive the Release build, and verify the TestFlight build against Production. Confirm no notification permission dialog, sounds or banners are requested.
- Confirm App Store Connect privacy answers match the app and its dependency behaviour. Increment the build number for each upload; the marketing version remains 1.0.

## Reproducibility and cleanup

FSRS is pinned to the revision already resolved by the supplied project: `4fbaf20184d62f82a9f44f343337c61a2c5483e9`. This replaces tracking the moving `main` branch without upgrading the library.

Unused Xcode widget and test templates are removed. `TodayReviewProvider.swift` lives under `logic/`. Sentence generation and its persisted config/relationships have now been removed entirely at your request. This requires validating an upgrade from the prior schema against a backup; no old-store migration fixture was provided. `.gitignore` excludes local Xcode state, build results and signing exports. Main service entry points have documentation comments explaining their effects.


## Widget config regression checks

Run WidgetTests in Xcode, then verify on iPhone and Mac: switch each source, disable a selected deck, select decks and tags separately, test empty selections, complete a review and cross midnight. Check system and coloured palettes in light/dark, restart persistence, and reveal/next behaviour. Confirm review config changes do not overwrite widget preferences and widget taps leave scores unchanged. Added tests cover filters, day boundaries, stable vocabulary IDs, shared preview/widget Hiragana rendering, preference round-trips and old snapshot decoding; they have not been executed in the editing environment.

Hint regression tests explicitly configure their display modes and hint preference, including the Quick writing preview. Rendered-view tests supplement taps: toggling state must alter actual SwiftUI output, and standalone Hiragana must match the primary Japanese size and colour. Recognition intentionally hides hints when Hiragana is already visible or is the answer.

## Regression release gate

Previously Reviewed tests cover lifetime FSRS repetitions, old reviews with future due dates, enabled/disabled decks, orphan and ungraded cards, deduplication, both practice directions, limits, saved source selection and no scheduling writes. A UI test grades a scheduled card, selects the new source, relaunches and starts practice.

Quick Review keyboard regression tests verify that 3 increments Incorrect, 4 corrects retry mistakes, both advance, and neither scores before reveal. A writing-mode test types “3 4” without scoring, then checks the answer and uses 4. Existing unit tests continue to verify retry totals and that Quick Review leaves every FSRS field unchanged.

The UI target runs serially because it operates on one real application store. Unit tests retain isolated containers. Treat skipped UI tests as **not verified**, even when Xcode reports the remaining tests passed. Use a clean disposable store/account for a full run; the deck-deletion test removes and reinstalls N5 and therefore destroys its test progress.

Run Product → Test on both My Mac and an iPhone simulator/device. Run the Mac keyboard cases, including typing “to eat” in a writing field, as well as mouse/touch interactions. Test Space reveal, all four rating keys, suppression of grading before reveal, Quick skip, retry/reset, and Review continuation. Real widget interactions and CloudKit transport still require the device checks above.

Use a warnings-as-errors build to catch the main-actor default-initializer regression at compilation time. From the repository directory, with signing configured:

```sh
xcodebuild -project pyoko.xcodeproj -scheme pyoko -destination 'platform=macOS' build-for-testing SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```

Then run tests in Xcode with the test-runner opt-in enabled. Repeat the build for your chosen iOS destination. Do not add a production environment switch to enable tests. Review both the app and embedded widget build diagnostics.

New suites:

| Suite | Failure conditions checked |
| --- | --- |
| FSRSIntegrationTests | All 16 state/rating combinations, full persisted scheduler output, exact initial learning intervals, graduation, lapse/relearning, preview/apply consistency, duplicate/unknown/out-of-queue rejection, no Quick scheduling changes |
| DiskPersistenceTests | Reopened disk store loses IDs, schedule fields, relationships or independent config; tag nullification/deck cascade fails |
| WidgetRenderingTests | Hint state is ignored; redundant/stale hint is rendered; standalone Hiragana becomes small/grey; Before Answer stops affecting the view |
| QuickTests | Skip scores a card, advances beyond completion, loses a retry mistake, changes FSRS or fails reset |
| pyokoUITests | Hint tap reveals answer accidentally, preview does not reset, final direction disables, filters/enablement do not persist, keyboard controls or actual review actions fail |

These tests have been source-reviewed, but **have not been compiled or executed here**. No measured coverage percentage or passing Xcode result is claimed. Test outcomes, CloudKit sync and prior-schema migration remain beta release gates.
