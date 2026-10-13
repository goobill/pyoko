import Testing
@testable import pyoko

@MainActor
struct WritingKeyboardTests {
    @Test func languageFollowsExpectedAnswer() {
        #expect(WritingKeyboardLanguage.preferred(for: .recall, hiraganaAnswer: false) == .japanese)
        #expect(WritingKeyboardLanguage.preferred(for: .recognition, hiraganaAnswer: false) == .english)
        #expect(WritingKeyboardLanguage.preferred(for: .recognition, hiraganaAnswer: true) == .japanese)
        #expect(WritingKeyboardLanguage.preferred(for: .recall, hiraganaAnswer: true) == .japanese)
    }

    @Test func regionalLanguagesAndUserOrderArePreserved() {
        #expect(WritingKeyboardLanguage.english.preferredIndex(in: ["emoji", "ja-JP", "en-GB", "en-US"]) == 2)
        #expect(WritingKeyboardLanguage.japanese.preferredIndex(in: ["en-US", "JA_jp", "ja"]) == 1)
    }

    @Test func missingLanguageRequestsSystemFallback() {
        #expect(WritingKeyboardLanguage.japanese.preferredIndex(in: [nil, "emoji", "en-US"]) == nil)
        #expect(WritingKeyboardLanguage.english.preferredIndex(in: []) == nil)
        #expect(WritingKeyboardLanguage.english.preferredIndex(in: ["english", "ja"]) == nil)
    }
}

#if os(iOS)
import SwiftUI
import UIKit

@MainActor
struct PhoneWritingFieldTests {
    private class FocusProbe: LanguageTextField {
        var focusAttempts = 0
        private var focused = false
        override var isFirstResponder: Bool { focused }
        override func becomeFirstResponder() -> Bool {
            focusAttempts += 1
            focused = true
            return true
        }
        override func resignFirstResponder() -> Bool {
            focused = false
            return true
        }
    }

    private func drainFocusUpdates() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    @Test func focusRequestedBeforeWindowAttachmentIsRetried() async {
        let field = FocusProbe()
        field.wantsFocus = true
        await drainFocusUpdates()
        #expect(field.focusAttempts == 0)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.addSubview(field)
        await drainFocusUpdates()
        #expect(field.isFirstResponder && field.focusAttempts == 1)
        field.wantsFocus = true
        field.text = "た"
        await drainFocusUpdates()
        #expect(field.focusAttempts == 1, "Text updates must not restart focus")
        field.wantsFocus = false
        await drainFocusUpdates()
        #expect(!field.isFirstResponder)
        field.removeFromSuperview()
    }

    @Test func cancelledFocusRequestDoesNotOpenKeyboardOnAttachment() async {
        let field = FocusProbe()
        field.wantsFocus = true
        field.wantsFocus = false
        let window = UIWindow(frame: .zero)
        window.addSubview(field)
        await drainFocusUpdates()
        #expect(field.focusAttempts == 0)
        field.removeFromSuperview()
    }

    @Test func editsAndReturnUseLatestText() {
        var answer = ""
        var submitted = ""
        let view = PhoneWritingField(
            text: Binding(get: { answer }, set: { answer = $0 }),
            isFocused: .constant(false), placeholder: "Answer", language: .japanese,
            onSubmit: { submitted = answer })
        let coordinator = view.makeCoordinator()
        let field = UITextField()
        field.text = "駅"
        coordinator.changed(field)
        #expect(answer == "駅")
        field.text = "えき"
        #expect(coordinator.textFieldShouldReturn(field) == false)
        #expect(answer == "えき")
        #expect(submitted == "えき")
    }
}
#endif
