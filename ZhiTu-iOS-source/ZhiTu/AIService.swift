import Foundation
import Security

struct AIConcept: Decodable {
    let title: String
    let summary: String
    let page: Int
    let chapter: String?
}

struct AIRelation: Decodable {
    let from: String
    let to: String
    let type: String
}

struct AIQuestion: Decodable {
    let conceptTitle: String
    let stem: String
    let options: [String]
    let answer: String
    let explanation: String
    let page: Int
}

struct AIAnalysisResult: Decodable {
    let concepts: [AIConcept]
    let relations: [AIRelation]
    let questions: [AIQuestion]
}

struct AIProviderSettings {
    let endpoint: URL
    let model: String
    let apiKey: String
}

enum AIServiceError: LocalizedError {
    case missingEndpoint
    case invalidEndpoint
    case badHTTPStatus(Int, String)
    case emptyResponse
    case invalidJSON
    case responseTooLarge

    var errorDescription: String? {
        switch self {
        case .missingEndpoint: return "请先在「我的 → AI 服务设置」里填写 Chat Completions 接口地址。"
        case .invalidEndpoint: return "接口地址必须是有效的 HTTPS URL（本地开发服务可使用 HTTP）。"
        case let .badHTTPStatus(code, body): return "AI 服务返回 HTTP \(code)：\(body.prefix(300))"
        case .emptyResponse: return "AI 服务没有返回文本内容。"
        case .invalidJSON: return "AI 返回内容不是有效的知识图谱 JSON，请重试或调整模型。"
        case .responseTooLarge: return "教材文本过长，请先拆分章节后再进行 AI 分析。"
        }
    }
}

enum SecretStore {
    private static let service = "com.sbcnmsc.ZhiTu"
    private static let account = "ai-api-key"

    static func read() -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else { return "" }
        return value
    }

    static func write(_ value: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let data = Data(value.utf8)
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            let update: [String: Any] = [kSecValueData as String: data]
            let result = SecItemUpdate(query as CFDictionary, update as CFDictionary)
            guard result == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(result)) }
        } else {
            var add = query
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let result = SecItemAdd(add as CFDictionary, nil)
            guard result == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(result)) }
        }
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum AIService {
    private struct Message: Encodable {
        let role: String
        let content: String
    }

    private struct RequestBody: Encodable {
        let model: String
        let messages: [Message]
        let temperature: Double
    }

    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct ResponseMessage: Decodable { let content: String? }
            let message: ResponseMessage
        }
        let choices: [Choice]
    }

    static func analyze(bookTitle: String, pageTexts: [(page: Int, text: String)],
                        settings: AIProviderSettings) async throws -> AIAnalysisResult {
        let usable = pageTexts.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !usable.isEmpty else {
            throw NSError(domain: "ZhiTu.AI", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "这份 PDF 没有可提取文本。扫描版教材需要先接入 OCR。"])
        }

        var source = ""
        for page in usable {
            let block = "\n\n[PDF 第 \(page.page) 页]\n\(page.text)"
            if source.count + block.count > 18_000 { break }
            source += block
        }
        guard source.count <= 18_000 else { throw AIServiceError.responseTooLarge }

        let prompt = """
        你是严格的教材知识结构整理器。只基于提供的教材片段生成 JSON，不要使用外部知识补全。
        如果片段不足以支持结论，少生成条目，不要猜测。所有 page 必须是来源标签中出现的 PDF 页码。
        输出必须是纯 JSON，结构如下：
        {
          "concepts":[{"title":"知识点名","summary":"简洁准确的说明","page":1,"chapter":"章节名"}],
          "relations":[{"from":"已输出的知识点名","to":"已输出的知识点名","type":"prerequisite|related|contains"}],
          "questions":[{"conceptTitle":"已输出的知识点名","stem":"题干","options":["A","B","C","D"],"answer":"必须与其中一个选项完全一致","explanation":"基于原文的解析","page":1}]
        }
        concepts 最多 18 个，relations 最多 30 条，questions 最多 12 道。
        题目应当可由文本作答，避免教材没有支持的事实。不要输出 Markdown 代码围栏。
        教材标题：\(bookTitle)
        教材片段：
        \(source)
        """

        var request = URLRequest(url: settings.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !settings.apiKey.isEmpty {
            request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        }
        let body = RequestBody(
            model: settings.model,
            messages: [
                Message(role: "system", content: "Return a compact, valid JSON object only."),
                Message(role: "user", content: prompt)
            ],
            temperature: 0.2
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AIServiceError.emptyResponse }
        guard (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "无法读取错误内容"
            throw AIServiceError.badHTTPStatus(http.statusCode, bodyText)
        }
        let chat = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = chat.choices.first?.message.content, !content.isEmpty else {
            throw AIServiceError.emptyResponse
        }
        let jsonText = stripCodeFence(content)
        guard let jsonData = jsonText.data(using: .utf8),
              let result = try? JSONDecoder().decode(AIAnalysisResult.self, from: jsonData) else {
            throw AIServiceError.invalidJSON
        }
        return result
    }

    private static func stripCodeFence(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("```") else { return trimmed }
        let lines = trimmed.components(separatedBy: .newlines)
        return lines.dropFirst().dropLast().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
