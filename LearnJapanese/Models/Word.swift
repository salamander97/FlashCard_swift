//
//  Word.swift
//  LearnJapanese
//
//  Created by Trung Hiếu on 2025/06/14.
//

// Models/Word.swift
import Foundation

struct Word: Codable, Identifiable {
    let id: Int
    let japaneseWord: String
    let kanji: String?
    let romaji: String
    let vietnameseMeaning: String
    let exampleSentenceJp: String?
    let exampleSentenceVn: String?
    let jlptLevel: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case japaneseWord = "japanese_word"
        case kanji, romaji
        case vietnameseMeaning = "vietnamese_meaning"
        case exampleSentenceJp = "example_sentence_jp"
        case exampleSentenceVn = "example_sentence_vn"
        case jlptLevel = "jlpt_level"
    }
    
    // Custom initializer for creating sample data
    init(
        id: Int,
        japaneseWord: String,
        kanji: String? = nil,
        romaji: String,
        vietnameseMeaning: String,
        exampleSentenceJp: String? = nil,
        exampleSentenceVn: String? = nil,
        jlptLevel: String? = nil
    ) {
        self.id = id
        self.japaneseWord = japaneseWord
        self.kanji = kanji
        self.romaji = romaji
        self.vietnameseMeaning = vietnameseMeaning
        self.exampleSentenceJp = exampleSentenceJp
        self.exampleSentenceVn = exampleSentenceVn
        self.jlptLevel = jlptLevel
    }
}

struct Category: Codable, Identifiable {
    let id: Int
    let name: String
    let nameEn: String?
    let icon: String
    let color: String
    let description: String
    let difficultyLevel: Int
    let estimatedHours: Double?
    let totalWords: Int
    let learnedWords: Int
    let masteredWords: Int
    let completionPercentage: Double?
    let quizBestScore: Int?
    let quizAttempts: Int?
    let totalStudyTime: Int?
    let isCompleted: Bool
    let isUnlocked: Bool
    let lastStudiedAt: String?
    let unlockCondition: UnlockCondition?
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, color, description
        case nameEn = "name_en"
        case difficultyLevel = "difficulty_level"
        case estimatedHours = "estimated_hours"
        case totalWords = "total_words"
        case learnedWords = "learned_words"
        case masteredWords = "mastered_words"
        case completionPercentage = "completion_percentage"
        case quizBestScore = "quiz_best_score"
        case quizAttempts = "quiz_attempts"
        case totalStudyTime = "total_study_time"
        case isCompleted = "is_completed"
        case isUnlocked = "is_unlocked"
        case lastStudiedAt = "last_studied_at"
        case unlockCondition = "unlock_condition"
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
    
    var completionPercentage: Double {
        guard totalWords > 0 else { return 0 }
        return Double(wordsLearned) / Double(totalWords) * 100
    }
}

struct UnlockCondition: Codable {
    let minCompletion: Int?
    let requiredCategories: [Int]?

    enum CodingKeys: String, CodingKey {
        case minCompletion = "min_completion"
        case requiredCategories = "required_categories"
    }
}
