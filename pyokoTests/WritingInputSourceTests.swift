import Testing
@testable import pyoko

@MainActor
struct WritingInputSourceTests {
    private let romaji = WritingInputSource(id: "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese",
                                            languages: ["ja"], asciiCapable: false)
    private let kana = WritingInputSource(id: "com.apple.inputmethod.Kotoeri.KanaTyping.Japanese",
                                          languages: ["ja"], asciiCapable: false)
    private let english = WritingInputSource(id: "com.apple.keylayout.British",
                                             languages: ["en-GB"], asciiCapable: true)

    @Test func recallSelectsRomajiConversionRatherThanKanaOrLatinOutput() {
        let latin = WritingInputSource(id: "com.apple.inputmethod.Kotoeri.RomajiTyping.Roman",
                                       languages: ["ja"], asciiCapable: true)
        let katakana = WritingInputSource(id: "com.apple.inputmethod.Kotoeri.RomajiTyping.Katakana",
                                          languages: ["ja"], asciiCapable: false)
        #expect(WritingInputSource.preferredID(for: .japanese,
            sources: [kana, latin, katakana, english, romaji], current: kana.id) == romaji.id)
    }

    @Test func unavailableRomajiDoesNotForceKanaOrInstallAnything() {
        #expect(WritingInputSource.preferredID(for: .japanese, sources: [kana, english], current: english.id) == nil)
        #expect(WritingInputSource.preferredID(for: .english, sources: [romaji], current: romaji.id) == nil)
    }

    @Test func recognitionPreservesPreferredEnglishLayout() {
        let us = WritingInputSource(id: "com.apple.keylayout.US", languages: ["en-US"], asciiCapable: true)
        #expect(WritingInputSource.preferredID(for: .english, sources: [us, english, romaji], current: english.id) == english.id)
        #expect(WritingInputSource.preferredID(for: .english, sources: [english, romaji], current: romaji.id) == english.id)
    }
}
