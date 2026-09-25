import SwiftUI
import CoreGraphics
import Testing
@testable import pyoko

/// Render real SwiftUI views: string-only assertions missed the small grey Hiragana bug.
@MainActor
struct WidgetRenderingTests {
    @Test func lockScreenRendersEnglishAndChangesWithTheSelectedWord() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let first = PyokoWidgetWord(id: "eat", source: "to eat", target: "食べる", reading: "たべる")
        let second = PyokoWidgetWord(id: "eat", source: "different meaning", target: "食べる", reading: "たべる")
        let a = LockScreenWordContent(word: first, snapshot: .empty, date: now)
        let b = LockScreenWordContent(word: second, snapshot: .empty, date: now)
        #expect(try pixels(LockScreenWordView(content: a), height: 76)
                    != pixels(LockScreenWordView(content: b), height: 76),
                "The lock-screen view must render the English meaning, not just Japanese")
        #expect(try pixels(LockScreenWordView(content: a, inline: true), height: 24)
                    != pixels(LockScreenWordView(content: b, inline: true), height: 24))
    }

    private func pixels<V: View>(_ view: V, height: CGFloat = 180) throws -> [UInt8] {
        let renderer = ImageRenderer(content: view
            .frame(width: 300, height: height)
            .environment(\.colorScheme, .light)
            .environment(\.dynamicTypeSize, .medium)
            .background(Color.white))
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        let width = image.width, height = image.height
        var result = [UInt8](repeating: 0, count: width * height * 4)
        try result.withUnsafeMutableBytes { buffer in
            let context = try #require(CGContext(data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        }
        return result
    }

    @Test(arguments: [PyokoWidgetDirection.recognition, .recall], [false, true])
    func hiraganaAloneHasTheSameSizeAndColourAsPrimaryJapanese(
        _ direction: PyokoWidgetDirection, _ revealed: Bool
    ) throws {
        // Same visible text through two modes must produce identical pixels.
        // This fails when .reading uses the small grey secondary reading style.
        var kana = PyokoWidgetSnapshot(publishedAt: .distantPast, words: [],
            includeRecognition: true, includeRecall: true, readingOnlyAnswer: false,
            before: .reading, after: .reading)
        let source = PyokoWidgetWord(id: "sample", source: "to eat", target: "食べる",
                                    reading: "たべる", deckName: "Example")
        let actual = try pixels(WidgetWordView(word: source, direction: direction,
                                               revealed: revealed, snapshot: kana))
        kana.before = .target; kana.after = .target
        let reference = PyokoWidgetWord(id: "sample", source: "to eat", target: "たべる",
                                       reading: nil, deckName: "Example")
        let expected = try pixels(WidgetWordView(word: reference, direction: direction,
                                                 revealed: revealed, snapshot: kana))
        #expect(Set(expected).count > 4, "A blank renderer must not count as a matching card")
        #expect(actual == expected, "Standalone Hiragana must use the primary Japanese typography and colour")
    }

    @Test func beforeAnswerModeActuallyChangesRenderedQuestion() throws {
        let word = PyokoWidgetWord(id: "sample", source: "to eat", target: "食べる", reading: "たべる")
        var config = PyokoWidgetSnapshot(publishedAt: .distantPast, words: [],
            includeRecognition: true, includeRecall: false, readingOnlyAnswer: false, before: .target)
        let kanji = try pixels(WidgetWordView(word: word, direction: .recognition, revealed: false, snapshot: config))
        config.before = .reading
        let kana = try pixels(WidgetWordView(word: word, direction: .recognition, revealed: false, snapshot: config))
        #expect(kanji != kana, "The renderer must use Before Answer, not always display Kanji")
    }

    @Test(arguments: [CardType.recognition, .recall], [false, true])
    func quickHintStateActuallyChangesRenderedContent(_ type: CardType, _ writing: Bool) throws {
        let card = PyokoQuickCard(type: type, sourceText: "to eat", targetText: "食べる", targetReading: "たべる")
        func view(hint: Bool, enabled: Bool = true) -> QuickCardView {
            QuickCardView(card: card, beforeAnswerDisplayMode: .target, afterAnswerDisplayMode: .targetAndReading,
                readingHintEnabled: enabled, recognitionReadingOnlyEnabled: false, writingEnabled: writing,
                submittedAnswer: "", answerRevealed: false, hintRevealed: .constant(hint), onReveal: {})
        }
        let hidden = try pixels(view(hint: false), height: 400)
        let visible = try pixels(view(hint: true), height: 400)
        #expect(hidden != visible, "Regression: Hint state must actually render Hiragana in Quick Review")
        #expect(try pixels(view(hint: true, enabled: false), height: 400)
                    == pixels(view(hint: false, enabled: false), height: 400))
    }

    @Test func reviewHintStateActuallyChangesRenderedContent() throws {
        let card = PyokoCard(type: .recognition, sourceText: "to eat", targetText: "食べる", targetReading: "たべる", deck: nil)
        func view(hint: Bool, answerIsReading: Bool = false) -> ReviewCardView {
            ReviewCardView(card: card, beforeAnswerDisplayMode: .target, afterAnswerDisplayMode: .targetAndReading,
                readingHintEnabled: true, readingOnlyAnswer: answerIsReading, answerRevealed: false,
                hintRevealed: .constant(hint), onReveal: {})
        }
        #expect(try pixels(view(hint: false), height: 400) != pixels(view(hint: true), height: 400))
        #expect(try pixels(view(hint: false, answerIsReading: true), height: 400)
                    == pixels(view(hint: true, answerIsReading: true), height: 400),
                "A stale hint must never expose a Hiragana-only answer")
    }

    @Test(arguments: [TargetDisplayMode.reading, .targetAndReading])
    func hintDoesNotDuplicateAnAlreadyVisibleReading(_ mode: TargetDisplayMode) throws {
        let card = PyokoQuickCard(type: .recognition, sourceText: "to eat", targetText: "食べる", targetReading: "たべる")
        func view(_ hint: Bool) -> QuickCardView {
            QuickCardView(card: card, beforeAnswerDisplayMode: mode, afterAnswerDisplayMode: .targetAndReading,
                readingHintEnabled: true, recognitionReadingOnlyEnabled: false, writingEnabled: false,
                submittedAnswer: "", answerRevealed: false, hintRevealed: .constant(hint), onReveal: {})
        }
        #expect(try pixels(view(false), height: 400) == pixels(view(true), height: 400))
    }

    @Test(arguments: [nil, "", "   "] as [String?])
    func missingReadingsCannotRenderStaleHints(_ reading: String?) throws {
        let card = PyokoQuickCard(type: .recognition, sourceText: "to eat", targetText: "食べる", targetReading: reading)
        func view(_ hint: Bool) -> QuickCardView {
            QuickCardView(card: card, beforeAnswerDisplayMode: .target, afterAnswerDisplayMode: .targetAndReading,
                readingHintEnabled: true, recognitionReadingOnlyEnabled: false, writingEnabled: false,
                submittedAnswer: "", answerRevealed: false, hintRevealed: .constant(hint), onReveal: {})
        }
        #expect(try pixels(view(false), height: 400) == pixels(view(true), height: 400))
    }
}
