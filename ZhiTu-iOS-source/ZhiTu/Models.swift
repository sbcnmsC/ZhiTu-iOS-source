import Foundation
import SwiftData

enum EdgeKind: String, Codable, CaseIterable {
    case prerequisite
    case related
    case contains
}

@Model
final class StudyBook {
    var id: UUID
    var title: String
    var author: String
    var createdAt: Date
    var sourceURL: String?
    var pageCount: Int

    init(title: String, author: String = "", pageCount: Int = 0, sourceURL: String? = nil) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.createdAt = .now
        self.pageCount = pageCount
        self.sourceURL = sourceURL
    }
}

@Model
final class KnowledgePoint {
    var id: UUID
    var title: String
    var summary: String
    var mastery: Double
    var bookTitle: String
    var chapter: String
    var pageNumber: Int
    var lastReviewedAt: Date?
    var nextReviewAt: Date?

    init(title: String, summary: String, mastery: Double = 0.2,
         bookTitle: String = "示例教材", chapter: String = "第一章", pageNumber: Int = 1) {
        self.id = UUID()
        self.title = title
        self.summary = summary
        self.mastery = mastery
        self.bookTitle = bookTitle
        self.chapter = chapter
        self.pageNumber = pageNumber
    }
}

@Model
final class StudyQuestion {
    var id: UUID
    var pointTitle: String
    var stem: String
    var optionsData: Data
    var correctAnswer: String
    var explanation: String
    var sourceBook: String
    var sourcePage: Int

    init(pointTitle: String, stem: String, options: [String], correctAnswer: String,
         explanation: String, sourceBook: String = "示例教材", sourcePage: Int = 1) {
        self.id = UUID()
        self.pointTitle = pointTitle
        self.stem = stem
        self.optionsData = (try? JSONEncoder().encode(options)) ?? Data()
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.sourceBook = sourceBook
        self.sourcePage = sourcePage
    }

    var options: [String] {
        (try? JSONDecoder().decode([String].self, from: optionsData)) ?? []
    }
}

@Model
final class AnswerAttempt {
    var id: UUID
    var questionID: UUID
    var questionStem: String
    var selectedAnswer: String
    var isCorrect: Bool
    var answeredAt: Date

    init(questionID: UUID, questionStem: String, selectedAnswer: String, isCorrect: Bool) {
        self.id = UUID()
        self.questionID = questionID
        self.questionStem = questionStem
        self.selectedAnswer = selectedAnswer
        self.isCorrect = isCorrect
        self.answeredAt = .now
    }
}

@Model
final class ReviewRecord {
    var id: UUID
    var pointTitle: String
    var dueDate: Date
    var status: String
    var stability: Double
    var difficulty: Double

    init(pointTitle: String, dueDate: Date = .now, status: String = "待复习",
         stability: Double = 1, difficulty: Double = 5) {
        self.id = UUID()
        self.pointTitle = pointTitle
        self.dueDate = dueDate
        self.status = status
        self.stability = stability
        self.difficulty = difficulty
    }
}
