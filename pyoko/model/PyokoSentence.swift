//
//  PyokoSentence.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

import Foundation

struct SentenceVocabulary: Identifiable, Hashable, Sendable {

    let sourceText: String
    let targetText: String
    let targetReading: String?

    var id: String {
        [
            sourceText,
            targetText,
            targetReading ?? ""
        ]
        .joined(separator: "\u{1F}")
    }
}


struct PyokoSentenceAlternative: Hashable, Sendable {

    let japanese: String
    let hiragana: String
}


struct PyokoSentence: Identifiable, Hashable, Sendable {

    let id: UUID

    let english: String

    let japanese: String
    let hiragana: String

    let alternativeEnglish: [String]
    let alternativeJapanese: [PyokoSentenceAlternative]

    let usedVocabulary: [String]

    init(
        id: UUID = UUID(),
        english: String,
        japanese: String,
        hiragana: String,
        alternativeEnglish: [String] = [],
        alternativeJapanese: [PyokoSentenceAlternative] = [],
        usedVocabulary: [String] = []
    ) {
        self.id = id
        self.english = english
        self.japanese = japanese
        self.hiragana = hiragana
        self.alternativeEnglish = alternativeEnglish
        self.alternativeJapanese = alternativeJapanese
        self.usedVocabulary = usedVocabulary
    }
}
