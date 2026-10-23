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
    var localFileName: String
    var pageCount: Int
    var extractionStatus: String
    var textCharacterCount: Int

    init(title: String, author: String = "", pageCount: Int = 0, sourceURL: String? = nil,
         localFileName: String = "", extractionStatus: String = "待解析", textCharacterCount: Int = 0) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.createdAt = .now
        self.pageCount = pageCount
        self.sourceURL = sourceURL
        self.localFileName = localFileName
        self.extractionStatus = extractionStatus
        self.textCharacterCount = textCharacterCount
    }
}

@Model
final class BookPage {
    var id: UUID
    var bookID: UUID
    var pageNumber: Int
    var text: String

    init(bookID: UUID, pageNumber: Int, text: String) {
        self.id = UUID()
        self.bookID = bookID
        self.pageNumber = pageNumber
        self.text = text
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
    var evidenceText: String
    var lastReviewedAt: Date?
    var nextReviewAt: Date?

    init(title: String, summary: String, mastery: Double = 0.2,
         bookTitle: String = "示例教材", chapter: String = "第一章", pageNumber: Int = 1,
         evidenceText: String = "") {
        self.id = UUID()
        self.title = title
        self.summary = summary
        self.mastery = mastery
        self.bookTitle = bookTitle
        self.chapter = chapter
        self.pageNumber = pageNumber
        self.evidenceText = evidenceText
    }
}

@Model
final class KnowledgeEdge {
    var id: UUID
    var bookTitle: String
    var fromTitle: String
    var toTitle: String
    var relationType: String

    init(bookTitle: String, fromTitle: String, toTitle: String, relationType: String = "related") {
        self.id = UUID()
        self.bookTitle = bookTitle
        self.fromTitle = fromTitle
        self.toTitle = toTitle
        self.relationType = relationType
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
    var sourceEvidence: String

    init(pointTitle: String, stem: String, options: [String], correctAnswer: String,
         explanation: String, sourceBook: String = "示例教材", sourcePage: Int = 1,
         sourceEvidence: String = "") {
        self.id = UUID()
        self.pointTitle = pointTitle
        self.stem = stem
        self.optionsData = (try? JSONEncoder().encode(options)) ?? Data()
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.sourceBook = sourceBook
        self.sourcePage = sourcePage
        self.sourceEvidence = sourceEvidence
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
final class AgentMessage {
    var id: UUID
    var role: String
    var content: String
    var createdAt: Date
    var relatedBookTitle: String?

    init(role: String, content: String, relatedBookTitle: String? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.createdAt = .now
        self.relatedBookTitle = relatedBookTitle
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
