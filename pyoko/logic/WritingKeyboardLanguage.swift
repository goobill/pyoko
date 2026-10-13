import Foundation

enum WritingKeyboardLanguage: String {
    case japanese = "ja"
    case english = "en"

    static func preferred(for direction: CardType, hiraganaAnswer: Bool) -> Self {
        direction == .recall || hiraganaAnswer ? .japanese : .english
    }

    /// Match regional variants, preserving the user's ordering of enabled keyboards.
    func preferredIndex(in languages: [String?]) -> Int? {
        languages.firstIndex { language in
            guard let language else { return false }
            return language.lowercased().split(whereSeparator: { $0 == "-" || $0 == "_" }).first
                == Substring(rawValue)
        }
    }
}
