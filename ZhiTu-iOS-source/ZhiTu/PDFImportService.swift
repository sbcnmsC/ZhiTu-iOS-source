import Foundation
import PDFKit

struct ExtractedPDF {
    let title: String
    let fileName: String
    let pageTexts: [String]
    let pageCount: Int
    let characterCount: Int
    let hasSelectableText: Bool
}

enum PDFImportError: LocalizedError {
    case invalidPDF
    case cannotCreateStorage

    var errorDescription: String? {
        switch self {
        case .invalidPDF: return "无法读取该 PDF。文件可能已损坏或不是有效的 PDF。"
        case .cannotCreateStorage: return "无法创建应用的教材存储目录。"
        }
    }
}

enum PDFImportService {
    static func importPDF(from sourceURL: URL) throws -> ExtractedPDF {
        let didStartAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let fileManager = FileManager.default
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw PDFImportError.cannotCreateStorage
        }
        let booksDirectory = base.appendingPathComponent("Books", isDirectory: true)
        try fileManager.createDirectory(at: booksDirectory, withIntermediateDirectories: true)

        let safeName = UUID().uuidString + ".pdf"
        let destination = booksDirectory.appendingPathComponent(safeName)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: sourceURL, to: destination)

        guard let document = PDFDocument(url: destination), document.pageCount > 0 else {
            try? fileManager.removeItem(at: destination)
            throw PDFImportError.invalidPDF
        }

        var texts: [String] = []
        var total = 0
        for index in 0..<document.pageCount {
            let text = document.page(at: index)?.string?
                .replacingOccurrences(of: "\u{0000}", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            texts.append(text)
            total += text.count
        }

        return ExtractedPDF(
            title: sourceURL.deletingPathExtension().lastPathComponent,
            fileName: safeName,
            pageTexts: texts,
            pageCount: document.pageCount,
            characterCount: total,
            hasSelectableText: total > 0
        )
    }

    static func storedPDFURL(fileName: String) -> URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return base.appendingPathComponent("Books", isDirectory: true).appendingPathComponent(fileName)
    }
}
