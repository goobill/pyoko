# Pyoko 1.0

An offline-capable Japanese vocabulary app for iPhone, iPad and native macOS. Practise English, Kanji and Hiragana with scheduled FSRS review or quick self-evaluated sessions.

**Status: beta candidate, not yet Xcode-verified.** Unit, integration, rendered-view and UI regression suites are included. Source checks are not a passing test run: Swift compilation, runtime tests, coverage, device sync and store migration must be verified on a Mac before release.

## Latest changes: regression tests and Mac keyboard controls

Quick Review's tag picker now lists tags linked to cards in installed decks. Start checks that a selected tag has vocabulary, preventing stale empty tags from leading to an empty session. Single-tag import/save/reload and UI-start regression tests are included. This does not reconstruct missing tag relationships in existing data.

Quick Review → Vocabulary now includes **Previously Reviewed**: random vocabulary from enabled decks with at least one scheduled Review grade, at any date. Either recognition or recall history qualifies the word; the session still follows your chosen directions and card limit. Pending cards, previews and Quick Review answers do not qualify new words. Start is disabled when no qualifying vocabulary is available.

- Hint tests tap the actual control and require visible Hiragana without revealing the answer. Rendered-view tests cover hidden/visible hints, disabled hints, missing readings and standalone Hiragana typography.
- FSRS integration tests exercise every rating across new, learning, review and relearning states; compare every saved scheduling field with the pinned scheduler; check learning/graduation/lapse behaviour; and reject invalid or duplicate submissions.
- Disk-store tests reopen saved data and check card identity, complete FSRS state, config independence, inverse relationships and deletion rules.
- UI tests establish display preferences before testing previews, hint interactions, widget filters, deck controls, writing input, ratings and keyboard shortcuts. They use the normal iCloud-enabled app.

On Mac, **Space** reveals the current answer. In scheduled Review, **1 = Again, 2 = Hard, 3 = Good, 4 = Easy**; grading advances to the next card. Number keys cannot grade before reveal. Space also continues a completed Review when another batch is available.

In Quick Review, **3 = Incorrect** and **4 = Correct** after revealing the answer; either rating advances. **Space after reveal advances without scoring** (also available as Next Card). Skipping never changes FSRS and never counts as Correct. In writing mode, spaces and numbers remain text input; use Check Answer or Return before scoring or advancing. No keyboard controls apply to config text fields or the widget.

## Themes and header

The home title and settings cog share a horizontal row: a full-width content header on iPhone/iPad and a sidebar header on Mac. Settings includes ten palettes: Classic, Ruby, Sunset, Forest, Ocean, Indigo, Plum, Rose, Slate and Mono. Each adds a subtle background colour and matching accent.

System/Light/Dark appearance is independent of the palette. Ten tint choices (blue, red, orange, green, teal, indigo, purple, pink, grey and charcoal) can override the palette's accent. Choosing another palette restores its matching tint. Preferences update immediately, persist through AppStorage and remain local to each device. Existing appearance settings are retained. Themes cover app screens and the Mac Settings window; widget colours are configured separately under Widget → Config.

## Build and test

Open `pyoko.xcodeproj` in Xcode, select the `pyoko` scheme and your enrolled developer team for both app and widget. Choose My Mac or your iPhone and Run. All builds use the same persistent **Pyoko** store configuration with iCloud enabled; there are no local/cloud modes or repository scripts.

Use Product → Test to run the unit/integration suites. Coverage is enabled in the shared scheme. UI tests exercise the real app and require a dedicated test device/iCloud account; see [BETA_TESTING.md](BETA_TESTING.md). See [SETUP.md](SETUP.md) for signing and sync setup.

## Navigation and practice

- **Review → Config:** daily limits, a minimum-new-card allowance, direction, display, hints, enabled decks and tags. FSRS updates only after grading a scheduled card. Completed sessions can be extended with another batch of due cards.
- **Quick Review:** session size, optional writing, matching Direction/Card Display controls, preview and vocabulary filters. Correct/Incorrect results support retrying mistakes and resetting. Quick Review does not alter FSRS.
- **Manage → Decks:** install, import, enable, disable and delete decks. Disabling a deck does not delete its cards/history and affects future queue selection; an existing queue is retained.
- **Settings:** device-local light/dark/system theme. A nonintrusive iCloud account check is available.

macOS has a sidebar, bounded-width content and a native Settings window with Command-comma. Review sessions use a navigation stack so Exit works on both platforms.

Review and Quick Review share `CardConfigView` and `CardPreviewView`. Previews use real card rendering, support recognition/recall and hints, and reset when settings change. The quick preview supports typed answers. Preview samples are never saved.

## Japanese labels and CSV compatibility

| UI label | CSV column | Meaning |
| --- | --- | --- |
| English | `source` | English meaning |
| Kanji | `target` | Japanese spelling, including kana-only words |
| Hiragana | `reading` | Optional pronunciation |
| Tags | `tags` | Categories separated by `|` |

The UI is Japanese-specific; the model names and CSV contract remain language-neutral. Use this header in order:

```csv
source,target,reading,tags
"to bathe, to shower",浴びる,あびる,N5|Verb
to eat,食べる,たべる,N5|Verb
```

The importer checks header order, required fields and row widths before insertion. It supports LF/CRLF/CR, UTF-8 BOM, quoted commas, doubled quotes and quoted newlines. Imports can come from local CSVs, URLs or public/published Google Sheets; private Sheets are not supported. Network-based imports are optional.

## Bundled decks

| Deck | File | Words | Recognition + recall cards |
| --- | --- | ---: | ---: |
| JLPT N5 | `jlpt_n5.csv` | 644 | 1,288 |
| JLPT N4 | `jlpt_n4.csv` | 571 | 1,142 |

Install explicitly from Decks. No internet is needed. Newly installed decks start enabled without re-enabling previously disabled decks. Duplicate local catalogue installations are rejected; existing decks are not overwritten. Deleting/reinstalling a deck deletes its old study history.

## Widget

Open **Widget → Config** from its own home/sidebar section. Preferences save automatically on each device and apply to all Word Review widgets there, independently of Review and Quick Review config.

- **All Enabled Cards:** random vocabulary from every enabled deck, ignoring review tag filters.
- **Selected Decks:** choose one or more enabled decks, with Select All/Deselect All controls.
- **Selected Tags:** match any selected tag across enabled decks. An empty deck or tag selection shows no words. Disabled decks are always excluded.
- **Today's Review Words:** vocabulary actually completed today, excluding pending reviews and previous days. The snapshot expires at the next local midnight. Open the app to publish the new day's words.
- The shared Card Display controls match Review and Quick Review: recognition/recall, Kanji/Hiragana/both before and after revealing, and Hiragana-only recognition answers. The interactive preview uses the actual widget card renderer, supports direction switching and reveal/reset, and has no instructional text inside the card. The card header keeps only the tap icon and deck name.
- **Default (System)** keeps the system widget background; ten optional palettes adapt to light/dark. The page includes a sample question preview and matching word count.

Tap to reveal, then tap again for a random next word. Widget interaction does not change FSRS scores. The top-right label shows the deck name (for example, N5 Vocab). Identical vocabulary from different decks keeps separate source labels.

The app publishes cached vocabulary through the App Group when data or preferences change and when it becomes active. The extension does not fetch CloudKit directly. WidgetKit controls refresh timing; updates may not appear immediately, and system widget tinting can override palette colours. No notification permission or banners are requested. Old snapshots still decode with default appearance until refreshed.

## Storage and sync

Every app build uses the persistent **Pyoko** SwiftData store and private CloudKit container `iCloud.com.goobill.pyoko`. The app and widget require compatible Apple developer signing. Review, quick practice and bundled installation still work without an internet connection; sync resumes when available.

Sync covers decks, cards, tags, FSRS fields, saved review queues and review/quick configs. Theme and the active quick session remain local.

CloudKit notifications are silent transport updates, not banners/sounds/badges. Pyoko does not request alert authorization or schedule notification alerts. Sync is asynchronous; account availability does not prove all records are synced. For v1, use devices sequentially and install defaults on only one device before allowing sync. Concurrent offline review reconciliation and duplicate-deck merging are not implemented.

## Sentence generation removed completely

There are no sentence screens, generator, selector, sentence config model, inverse relationships or sentence enums left in the app. No Foundation Models or Apple Intelligence dependency remains.

**Upgrade warning:** removing the old persisted sentence config changes the schema. Current-schema tests are not proof that every existing database upgrades successfully. Test an upgrade on a backup of your existing database before installing this candidate over real data; do not delete the store as a workaround.

## Repository layout

- `pyoko/logic`: import, deck management, scheduling/retrieval, quick practice and today's completed vocabulary.
- `pyoko/model`: six SwiftData entities plus lightweight quick-session values.
- `pyoko/enum`: display, deck-origin, quick-source and URL/interval helpers.
- `pyoko/view`: shared and platform-adaptive SwiftUI screens.
- `pyoko/widget`, `PyokoWidgets`: snapshot publishing/storage and the active WidgetKit extension.
- `pyoko/seed`: bundled catalogue and CSV resources.
- `pyokoTests`, `pyokoUITests`: isolated logic/integration tests and UI smoke tests.

Main service APIs document their effects. Tests inject clocks and download sessions, use fresh in-memory stores, and isolate widget preferences in disposable suites. The app contains no test-mode switches. Widget tests inject a preferences suite through the same storage implementation used by the app. Unused sample widgets and placeholder tests were removed. Local Xcode metadata, build products and signing exports are ignored by Git.

## Beta requirements

Use a compatible Xcode 26+ installation, iOS/iPadOS 26+ or macOS 26+. The original project was created with Xcode 26.6. FSRS is pinned to the original resolved revision `4fbaf20184d62f82a9f44f343337c61a2c5483e9`, not a moving branch.

Free Personal Team iPhone testing requires periodic reprovisioning (seven days) and cannot provision the configured CloudKit capabilities. TestFlight requires Apple Developer Program membership, normally US$99/year or local equivalent. Follow the full [beta checklist](BETA_TESTING.md), including real old-store migration and CloudKit Production tests where sync is enabled.

Previous combined widget filters migrate to Selected Tags (or All Enabled Cards if no tags were selected); individual-word selections are retired in favour of deck/tag sources. Widget display fields are optional in stored preferences and snapshots so existing settings continue to decode.

## Hiragana hint fix

Quick Review now renders the revealed Hiragana hint and honours Before Answer display mode, including in its preview and writing mode. Both card views keep the hint button outside the answer-reveal gesture region. Hints are unavailable when disabled, the reading is blank, recognition already displays the reading, or Hiragana itself is the recognition answer. UI regression tests cover show/hide without revealing the full answer in both config previews. These tests require Xcode and have not been run in the editing environment.
