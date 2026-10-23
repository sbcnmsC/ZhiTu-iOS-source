import SwiftUI
import SwiftData

struct AgentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \AgentMessage.createdAt) private var messages: [AgentMessage]
    @Query(sort: \StudyBook.createdAt, order: .reverse) private var books: [StudyBook]
    @Query(sort: \BookPage.pageNumber) private var pages: [BookPage]
    @Query(sort: \KnowledgePoint.mastery) private var points: [KnowledgePoint]
    @Query(sort: \AnswerAttempt.answeredAt, order: .reverse) private var attempts: [AnswerAttempt]

    @AppStorage("aiEndpoint") private var endpoint = ""
    @AppStorage("aiModel") private var model = "deepseek-chat"
    @State private var selectedBookID = "all"
    @State private var draft = ""
    @State private var isSending = false
    @State private var alertMessage: String?

    private var selectedBookTitle: String {
        guard selectedBookID != "all",
              let book = books.first(where: { $0.id.uuidString == selectedBookID }) else {
            return "全部教材"
        }
        return book.title
    }

    var body: some View {
        VStack(spacing: 0) {
            contextPicker
            Divider().overlay(ZT.line)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 14) {
                        if messages.isEmpty {
                            welcomePanel
                                .id("agent-welcome")
                        }

                        ForEach(messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }

                        if isSending {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("正在结合教材和学习记录思考…")
                                    .font(.system(size: 12)).foregroundStyle(ZT.muted)
                                Spacer()
                            }
                            .padding(12)
                            .background(.white, in: RoundedRectangle(cornerRadius: 14))
                            .id("agent-thinking")
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isSending) { _, sending in
                    if sending {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("agent-thinking", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(ZT.paper.ignoresSafeArea())
        .navigationTitle("学习 Agent")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("清空对话", systemImage: "trash", role: .destructive) {
                        clearConversation()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            composer
        }
        .alert("学习 Agent", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("确定", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var contextPicker: some View {
        HStack(spacing: 8) {
            Image(systemName: "books.vertical.fill").foregroundStyle(ZT.blue)
            Picker("教材范围", selection: $selectedBookID) {
                Text("全部教材").tag("all")
                ForEach(books) { book in
                    Text(book.title).tag(book.id.uuidString)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(ZT.ink)
            .lineLimit(1)

            Spacer(minLength: 4)

            Text("\(points.count) 个知识点")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ZT.muted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.8))
    }

    private var welcomePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZTCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(ZT.blue)
                            .frame(width: 44, height: 44)
                            .background(ZT.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("你的学习 Agent").font(.system(size: 18, weight: .bold)).foregroundStyle(ZT.ink)
                            Text("讲解 · 规划 · 抽查 · 复盘").font(.system(size: 12)).foregroundStyle(ZT.muted)
                        }
                    }
                    Text("我会优先参考你选择的教材原文和已记录的掌握情况。回答涉及教材时会标注来源页码；找不到证据时会明确说明。")
                        .font(.system(size: 13)).foregroundStyle(ZT.muted)
                }
            }

            Text("你可以让我帮你").font(.system(size: 15, weight: .bold)).foregroundStyle(ZT.ink)
            suggestion("解释一个知识点，用例子讲到我懂", icon: "lightbulb") {
                sendSuggestion("请结合我选中的教材，用简单例子分步骤解释最重要的知识点，并标出能核对的原文页码。")
            }
            suggestion("为今天制定学习顺序", icon: "calendar") {
                sendSuggestion("根据我的掌握度、错题和前置依赖，为我安排今天的学习计划。计划要具体，优先补薄弱点。")
            }
            suggestion("生成 5 道教材抽查题", icon: "checkmark.circle") {
                sendSuggestion("请仅基于我选中的教材生成 5 道抽查题，每道题给选项、答案、解析和来源页码；没有原文证据的内容不要出题。")
            }

            if endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ZTCard {
                    Label("还差一步：配置 AI 服务", systemImage: "gearshape")
                        .font(.system(size: 14, weight: .semibold))
                    Text("先在「我的 → AI 服务设置」填写兼容的 Chat Completions 接口。")
                        .font(.system(size: 12)).foregroundStyle(ZT.muted).padding(.top, 4)
                    NavigationLink("打开 AI 服务设置") { AISettingsView() }
                        .font(.system(size: 13, weight: .semibold)).padding(.top, 6)
                }
            }

            Text("隐私提示：发送问题时，会把问题、近期对话、相关学习统计和所选教材的部分提取文本发送到你配置的 AI 接口。")
                .font(.system(size: 11)).foregroundStyle(ZT.muted)
                .padding(.horizontal, 4)
        }
    }

    private func suggestion(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundStyle(ZT.blue).frame(width: 22)
                Text(title).font(.system(size: 13, weight: .medium)).foregroundStyle(ZT.ink)
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 11)).foregroundStyle(ZT.muted)
            }
            .padding(13)
            .background(.white, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(ZT.line.opacity(0.8), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
        .disabled(isSending)
    }

    private func messageBubble(_ message: AgentMessage) -> some View {
        let isUser = message.role == "user"
        return HStack(alignment: .top, spacing: 8) {
            if isUser { Spacer(minLength: 36) }
            if !isUser {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ZT.blue)
                    .frame(width: 27, height: 27)
                    .background(ZT.blue.opacity(0.1), in: Circle())
            }
            Text(message.content)
                .font(.system(size: 14))
                .foregroundStyle(isUser ? .white : ZT.ink)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(isUser ? ZT.blue : .white,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    if !isUser {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(ZT.line.opacity(0.65), lineWidth: 0.7)
                    }
                }
            if !isUser { Spacer(minLength: 20) }
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 10) {
                TextField("问问教材、概念或考试题…", text: $draft, axis: .vertical)
                    .font(.system(size: 14))
                    .lineLimit(1...4)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 11)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(ZT.line, lineWidth: 1))

                Button {
                    Task { await sendDraft() }
                } label: {
                    Group {
                        if isSending {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .frame(width: 43, height: 43)
                    .background(ZT.blue, in: Circle())
                    .foregroundStyle(.white)
                }
                .disabled(isSending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("发送消息")
            }

            HStack {
                Text(selectedBookTitle)
                    .lineLimit(1)
                Spacer()
                Text("AI 回答需自行核对")
            }
            .font(.system(size: 10))
            .foregroundStyle(ZT.muted)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func sendSuggestion(_ text: String) {
        draft = text
        Task { await sendDraft() }
    }

    @MainActor
    private func sendDraft() async {
        let question = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isSending else { return }
        guard let url = URL(string: endpoint.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(),
              ["https", "http"].contains(scheme), url.host != nil else {
            alertMessage = "请先在「我的 → AI 服务设置」里填写有效的 Chat Completions URL。"
            return
        }

        // Snapshot recent turns before inserting the current question.
        var history = messages.suffix(10).map {
            TutorTurn(role: $0.role, content: $0.content)
        }
        history.append(TutorTurn(role: "user", content: question))

        context.insert(AgentMessage(role: "user", content: question,
                                    relatedBookTitle: selectedBookID == "all" ? nil : selectedBookTitle))
        do { try context.save() } catch {
            alertMessage = "无法保存对话：\(error.localizedDescription)"
            return
        }

        draft = ""
        isSending = true
        defer { isSending = false }

        do {
            let provider = AIProviderSettings(endpoint: url, model: model, apiKey: SecretStore.read())
            let textbook = buildTextbookContext(query: question)
            let learning = buildLearningContext()
            let reply = try await AIService.tutorReply(
                history: history,
                textbookContext: textbook,
                learningContext: learning,
                settings: provider
            )
            context.insert(AgentMessage(role: "assistant", content: reply,
                                        relatedBookTitle: selectedBookID == "all" ? nil : selectedBookTitle))
            try context.save()
        } catch {
            context.insert(AgentMessage(role: "assistant",
                                        content: "这次请求没有成功：\(error.localizedDescription)\n\n请检查网络、接口地址、模型名称和 API Key。"))
            try? context.save()
        }
    }

    private func buildTextbookContext(query: String) -> String {
        let candidates = pages.filter { page in
            selectedBookID == "all" || page.bookID.uuidString == selectedBookID
        }
        guard !candidates.isEmpty else { return "" }

        let compactQuery = String(query.lowercased().filter { $0.isLetter || $0.isNumber })
        let tokens = Set(compactQuery.map { String($0) }.filter {
            !["的", "了", "吗", "是", "请", "帮", "我", "你", "和", "与", "在", "中", "怎么", "什么", "一下"].contains($0)
        })

        func score(_ text: String) -> Int {
            let lowered = text.lowercased()
            return tokens.reduce(into: 0) { total, token in
                if lowered.contains(token) { total += 1 }
            } + (compactQuery.count > 2 && lowered.contains(compactQuery) ? 5 : 0)
        }

        let ranked = candidates
            .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { score($0.text) > score($1.text) }

        var remaining = 10_000
        var excerpts: [String] = []
        for page in ranked {
            guard remaining > 0, excerpts.count < 8 else { break }
            let title = books.first(where: { $0.id == page.bookID })?.title ?? "未知教材"
            let excerpt = String(page.text.prefix(min(1_600, remaining)))
            let block = "[\(title) 第 \(page.pageNumber) 页]\n\(excerpt)"
            excerpts.append(block)
            remaining -= block.count
        }
        return excerpts.joined(separator: "\n\n")
    }

    private func buildLearningContext() -> String {
        let weakPoints = points.sorted { $0.mastery < $1.mastery }.prefix(12).map {
            "知识点：\($0.title)；掌握度约 \(Int($0.mastery * 100))%；\($0.summary)"
        }
        let wrongAnswers = attempts.filter { !$0.isCorrect }.prefix(5).map {
            "错题：\($0.questionStem)；用户曾选择：\($0.selectedAnswer)"
        }
        return (Array(weakPoints) + Array(wrongAnswers)).joined(separator: "\n")
    }

    private func clearConversation() {
        for message in messages {
            context.delete(message)
        }
        try? context.save()
    }
}
