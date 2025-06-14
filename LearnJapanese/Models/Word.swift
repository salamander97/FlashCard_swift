//
//  Word.swift
//  LearnJapanese
//
//  Created by Trung Hiếu on 2025/06/14.
//

import Foundation

struct Word: Codable, Identifiable {
    let id: Int
    let japaneseWord: String
    let kanji: String?
    let romaji: String
    let vietnameseMeaning: String
    let exampleSentenceJp: String?
    let exampleSentenceVn: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case japaneseWord = "japanese_word"
        case kanji, romaji
        case vietnameseMeaning = "vietnamese_meaning"
        case exampleSentenceJp = "example_sentence_jp"
        case exampleSentenceVn = "example_sentence_vn"
    }
}

struct Category: Codable, Identifiable {
    let id: Int
    let categoryName: String
    let categoryIcon: String
    let totalWords: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case categoryName = "category_name"
        case categoryIcon = "category_icon"
        case totalWords = "total_words"
    }
}

struct StudyProgress: Codable {
    let wordsLearned: Int
    let wordMastered: Int
    let totalWords: Int
    
    enum CodingKeys: String, CodingKey {
        case wordsLearned = "words_learned"
        case wordMastered = "word_mastered"
        case totalWords = "total_words"
    }
    var completionPercentage : Double {
        guard totalWords > 0 else {return 0}
        return Double(wordsLearned) / Double(totalWords) * 100
    }
}
