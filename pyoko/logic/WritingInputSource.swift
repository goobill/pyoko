import Foundation

/// Metadata from enabled Mac input sources; selection never installs or enables one.
struct WritingInputSource {
    let id: String
    let languages: [String]
    let asciiCapable: Bool

    static func preferredID(for language: WritingKeyboardLanguage,
                            sources: [Self], current: String?) -> String? {
        let matching = sources.filter { source in
            guard language.preferredIndex(in: source.languages.map { Optional($0) }) != nil else { return false }
            if language == .english { return source.asciiCapable }
            // Apple's Japanese–Romaji Hiragana mode converts Latin keystrokes to
            // Japanese. The Roman and Katakana modes are not Recall's default.
            let id = source.id.lowercased()
            return id.contains("romajityping") && id.hasSuffix(".japanese") && !source.asciiCapable
        }
        return matching.first(where: { $0.id == current })?.id ?? matching.first?.id
    }
}
