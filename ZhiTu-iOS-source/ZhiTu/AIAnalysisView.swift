import SwiftUI
import SwiftData

struct AIAnalysisView: View {
    let book: StudyBook
    @Environment(\.modelContext) private var context
    @Query private var pages: [BookPage]
    @Query private var allPoints: [KnowledgePoint]
    @Query private var allQuestions: [StudyQuestion]
    @State private var isWorking = false
    @State private var resultMessage: String?
    @State private var importedConceptCount = 0
    @State private var importedRelationCount = 0
    @State private var importedQuestionCount = 0
    @State private var rejectedCount = 0

    @AppStorage("aiEndpoint") private var endpoint = ""
    @AppStorage("aiModel") private var model = "deepseek-chat"

    init(book: StudyBook) {
        self.book = book
        let id = book.id
        _pages = Query(filter: #Predicate<BookPage> { $0.bookID == id },
                       sort: [SortDescriptor(\BookPage.pageNumber)])
        _allPoints = Query()
        _allQuestions = Query()
    }

    private var hasExtractedText: Bool {
        pages.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ZTCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("教材 AI 分析", systemImage: "sparkles")
                            .font(.system(size: 18, weight: .bold)).foregroundStyle(ZT.ink)
                        Text(book.title).font(.system(size: 15, weight: .semibold))
                        Text("系统会读取已提取的页面文本，生成知识点、关系和练习题。每项内容都必须带有来自对应页的原文短句，才能保存。")
                            .font(.system(size: 13)).foregroundStyle(ZT.muted)
                        HStack {
                            Label("\(book.pageCount) 页", systemImage: "doc.text")
                            Spacer()
                            Label("\(book.textCharacterCount) 字符", systemImage: "text.alignleft")
                        }
                        .font(.system(size: 12)).foregroundStyle(ZT.muted)
                    }
                }

                if endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ZTCard {
                        Label("还没有配置 AI 接口", systemImage: "gearshape")
                            .font(.system(size: 14, weight: .semibold))
                        Text("请先进入「我的 → AI 服务设置」填写接口地址和模型名称。")
                            .font(.system(size: 12)).foregroundStyle(ZT.muted).padding(.top, 4)
                        NavigationLink("打开 AI 服务设置") { AISettingsView() }
                            .font(.system(size: 14, weight: .semibold)).padding(.top, 6)
                    }
                }

                Button {
                    Task { await runAnalysis() }
                } label: {
                    HStack {
                        if isWorking { ProgressView().tint(.white) }
                        Text(isWorking ? "正在分析教材…" : "生成知识图谱与题目")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity).padding(15)
                    .background(ZT.blue, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white)
                }
                .disabled(isWorking || endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !hasExtractedText)

                if !hasExtractedText {
                    Text("没有提取到可用文本。扫描版 PDF 需要 OCR 才能交给 AI 分析。")
                        .font(.system(size: 12)).foregroundStyle(.orange)
                }

                if importedConceptCount > 0 || importedQuestionCount > 0 || rejectedCount > 0 {
                    ZTCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("分析结果已处理", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 15, weight: .bold)).foregroundStyle(ZT.green)
                            Text("新增知识点：\(importedConceptCount)")
                            Text("新增关系：\(importedRelationCount)")
                            Text("新增练习题：\(importedQuestionCount)")
                            Text("因原文证据缺失、页码无效或答案格式不正确而跳过：\(rejectedCount)")
                            Text("保存结果前已进行原文短句和页码的基础校验。请仍然抽查内容；这不是完整的学术或事实审核。")
                                .font(.system(size: 12)).foregroundStyle(ZT.muted)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(ZT.paper.ignoresSafeArea())
        .navigationTitle("AI 拆解")
        .navigationBarTitleDisplayMode(.inline)
        .alert("AI 分析", isPresented: Binding(
            get: { resultMessage != nil },
            set: { if !$0 { resultMessage = nil } }
        )) {
            Button("确定", role: .cancel) { resultMessage = nil }
        } message: {
            Text(resultMessage ?? "")
        }
    }

    @MainActor
    private func runAnalysis() async {
        guard let url = URL(string: endpoint.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              url.host != nil else {
            resultMessage = "接口地址无效。请输入完整 URL，例如 https://你的服务/v1/chat/completions。"
            return
        }
        isWorking = true
        defer { isWorking = false }
        let settings = AIProviderSettings(endpoint: url, model: model, apiKey: SecretStore.read())
        do {
            let textPages = pages.map { (page: $0.pageNumber, text: $0.text) }
            let analysis = try await AIService.analyze(bookTitle: book.title, pageTexts: textPages, settings: settings)

            var sourceByPage: [Int: String] = [:]
            for page in pages { sourceByPage[page.pageNumber] = page.text }

            let groundedConcepts = analysis.concepts.filter { concept in
                guard !concept.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      concept.page > 0,
                      let source = sourceByPage[concept.page] else { return false }
                return isGrounded(evidence: concept.evidence, in: source)
            }
            let groundedTitles = Set(groundedConcepts.map(\.title))
            let allowedPages = Set(sourceByPage.keys)
            var addedConcepts = 0
            var rejected = analysis.concepts.count - groundedConcepts.count

            for concept in groundedConcepts {
                let alreadyExists = allPoints.contains {
                    $0.bookTitle == book.title && $0.title.caseInsensitiveCompare(concept.title) == .orderedSame
                }
                if !alreadyExists {
                    context.insert(KnowledgePoint(
                        title: concept.title,
                        summary: concept.summary,
                        mastery: 0.1,
                        bookTitle: book.title,
                        chapter: concept.chapter ?? "AI 提取",
                        pageNumber: concept.page,
                        evidenceText: concept.evidence
                    ))
                    addedConcepts += 1
                }
            }

            var addedRelations = 0
            for relation in analysis.relations {
                guard groundedTitles.contains(relation.from),
                      groundedTitles.contains(relation.to),
                      relation.from != relation.to else {
                    rejected += 1
                    continue
                }
                let type = ["prerequisite", "related", "contains"].contains(relation.type) ? relation.type : "related"
                context.insert(KnowledgeEdge(bookTitle: book.title, fromTitle: relation.from,
                                             toTitle: relation.to, relationType: type))
                addedRelations += 1
            }

            var addedQuestions = 0
            for item in analysis.questions {
                guard !item.stem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      item.options.count >= 2,
                      item.options.contains(item.answer),
                      groundedTitles.contains(item.conceptTitle),
                      allowedPages.contains(item.page),
                      let source = sourceByPage[item.page],
                      isGrounded(evidence: item.evidence, in: source) else {
                    rejected += 1
                    continue
                }
                let duplicate = allQuestions.contains {
                    $0.sourceBook == book.title && $0.stem == item.stem
                }
                if !duplicate {
                    context.insert(StudyQuestion(
                        pointTitle: item.conceptTitle,
                        stem: item.stem,
                        options: item.options,
                        correctAnswer: item.answer,
                        explanation: item.explanation,
                        sourceBook: book.title,
                        sourcePage: item.page,
                        sourceEvidence: item.evidence
                    ))
                    addedQuestions += 1
                }
            }
            try context.save()
            importedConceptCount = addedConcepts
            importedRelationCount = addedRelations
            importedQuestionCount = addedQuestions
            rejectedCount = rejected
            book.extractionStatus = "已完成 AI 分析"
            try context.save()
            resultMessage = "处理完成：新增 \(addedConcepts) 个知识点、\(addedRelations) 条关系、\(addedQuestions) 道题。跳过 \(rejected) 个未通过基础来源校验的条目。"
        } catch {
            resultMessage = error.localizedDescription
        }
    }

    private func isGrounded(evidence: String, in sourceText: String) -> Bool {
        let quote = normalizeWhitespace(evidence)
        let source = normalizeWhitespace(sourceText)
        return quote.count >= 8 && source.localizedCaseInsensitiveContains(quote)
    }

    private func normalizeWhitespace(_ value: String) -> String {
        value.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
