import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BookLibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \StudyBook.createdAt, order: .reverse) private var books: [StudyBook]
    @State private var showingImporter = false
    @State private var showingManualSheet = false
    @State private var importStatus: String?
    @State private var isImporting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("教材库").font(.system(size: 27, weight: .bold)).foregroundStyle(ZT.ink)
                        Text("PDF 与手动笔记都可以转成学习资料").font(.system(size: 13)).foregroundStyle(ZT.muted)
                    }
                    Spacer()
                    Image(systemName: "books.vertical.fill").font(.title2).foregroundStyle(ZT.blue)
                }

                HStack(spacing: 10) {
                    Button {
                        showingImporter = true
                    } label: {
                        Label(isImporting ? "正在导入" : "导入 PDF", systemImage: "doc.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity).padding(13)
                            .background(ZT.blue, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white)
                    }
                    .disabled(isImporting)

                    Button {
                        showingManualSheet = true
                    } label: {
                        Label("手动输入", systemImage: "square.and.pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity).padding(13)
                            .background(.white, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(ZT.line, lineWidth: 1))
                    }
                    .foregroundStyle(ZT.ink)
                }

                if books.isEmpty {
                    ZTCard {
                        VStack(spacing: 10) {
                            Image(systemName: "doc.text.magnifyingglass").font(.system(size: 34)).foregroundStyle(ZT.blue)
                            Text("还没有教材").font(.system(size: 16, weight: .semibold)).foregroundStyle(ZT.ink)
                            Text("导入一份可复制文字的 PDF，系统会提取每页文本与页码。扫描版图片 PDF 暂时需要 OCR 才能自动提取文字。")
                                .font(.system(size: 12)).foregroundStyle(ZT.muted).multilineTextAlignment(.center)
                        }.frame(maxWidth: .infinity).padding(.vertical, 18)
                    }
                } else {
                    SectionHeading(title: "已导入", trailing: "\(books.count) 份资料")
                    ForEach(books) { book in
                        NavigationLink {
                            BookDetailView(book: book)
                        } label: {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 14).fill(ZT.blue.opacity(0.1))
                                    .frame(width: 48, height: 54)
                                    .overlay(Image(systemName: book.localFileName.isEmpty ? "note.text" : "doc.richtext")
                                        .font(.system(size: 22)).foregroundStyle(ZT.blue))
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(book.title).font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(ZT.ink).lineLimit(2)
                                    Text("\(book.pageCount) 页 · \(book.textCharacterCount) 个文本字符")
                                        .font(.system(size: 11)).foregroundStyle(ZT.muted)
                                    Text(book.extractionStatus)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(book.textCharacterCount > 0 ? ZT.green : .orange)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(ZT.muted)
                            }
                            .padding(12)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }

                ZTCard {
                    Label("教材证据优先", systemImage: "checkmark.seal")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(ZT.ink)
                    Text("AI 只会收到已提取的页面文本。生成的知识点和题目保留页码；建议在正式使用前抽查内容与引用。")
                        .font(.system(size: 12)).foregroundStyle(ZT.muted).padding(.top, 4)
                }
            }
            .padding(18)
        }
        .background(ZT.paper.ignoresSafeArea())
        .navigationTitle("教材库")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { result in
            importPDF(result)
        }
        .sheet(isPresented: $showingManualSheet) {
            ManualSourceSheet()
        }
        .alert("教材导入", isPresented: Binding(
            get: { importStatus != nil },
            set: { if !$0 { importStatus = nil } }
        )) {
            Button("确定", role: .cancel) { importStatus = nil }
        } message: {
            Text(importStatus ?? "")
        }
    }

    private func importPDF(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importStatus = "未能选择文件：\(error.localizedDescription)"
        case .success(let urls):
            guard let url = urls.first else { return }
            isImporting = true
            defer { isImporting = false }
            do {
                let extracted = try PDFImportService.importPDF(from: url)
                let book = StudyBook(
                    title: extracted.title,
                    pageCount: extracted.pageCount,
                    localFileName: extracted.fileName,
                    extractionStatus: extracted.hasSelectableText ? "已提取文本" : "扫描版：未提取到文本",
                    textCharacterCount: extracted.characterCount
                )
                context.insert(book)
                for (index, text) in extracted.pageTexts.enumerated() {
                    context.insert(BookPage(bookID: book.id, pageNumber: index + 1, text: text))
                }
                try context.save()
                if extracted.hasSelectableText {
                    importStatus = "导入成功：共 \(extracted.pageCount) 页，提取 \(extracted.characterCount) 个文本字符。现在可以阅读原文或进行 AI 拆解。"
                } else {
                    importStatus = "PDF 已保存，共 \(extracted.pageCount) 页，但没有提取到可复制文本。阅读器可正常打开文件；AI 分析需先接入 OCR。"
                }
            } catch {
                importStatus = error.localizedDescription
            }
        }
    }
}

private struct BookDetailView: View {
    let book: StudyBook

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ZTCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(book.title).font(.system(size: 23, weight: .bold)).foregroundStyle(ZT.ink)
                        Text(book.extractionStatus).font(.system(size: 13, weight: .medium)).foregroundStyle(ZT.green)
                        HStack {
                            Label("\(book.pageCount) 页", systemImage: "doc.text")
                            Spacer()
                            Label("\(book.textCharacterCount) 字符", systemImage: "text.alignleft")
                        }.font(.system(size: 12)).foregroundStyle(ZT.muted)
                    }
                }

                NavigationLink {
                    PDFReaderView(book: book)
                } label: {
                    Label(book.localFileName.isEmpty ? "查看手动输入原文" : "阅读 PDF 与页面原文",
                          systemImage: book.localFileName.isEmpty ? "text.alignleft" : "doc.text.magnifyingglass")
                        .frame(maxWidth: .infinity).padding(15)
                        .background(.white, in: RoundedRectangle(cornerRadius: 14))
                }
                .foregroundStyle(ZT.ink)

                NavigationLink {
                    AIAnalysisView(book: book)
                } label: {
                    Label("AI 拆解知识点并生成题目", systemImage: "sparkles")
                        .frame(maxWidth: .infinity).padding(15)
                        .background(ZT.blue, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white)
                }

                Text("AI 生成内容会保存到本地知识点与题库。检查页码和答案后再用于复习。")
                    .font(.system(size: 12)).foregroundStyle(ZT.muted)
            }.padding(18)
        }
        .background(ZT.paper.ignoresSafeArea())
        .navigationTitle("教材详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ManualSourceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var title = ""
    @State private var text = ""
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("资料标题") {
                    TextField("例如：电力电子技术 · Buck 变换器", text: $title)
                }
                Section("教材原文或讲义内容") {
                    TextEditor(text: $text).frame(minHeight: 220)
                }
                Section {
                    Text("手动内容会作为第 1 页保存，可直接进行 AI 分析。请尽量保留章节标题，以便生成更好的知识关系。")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("手动添加资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("无法保存", isPresented: Binding(
                get: { errorText != nil },
                set: { if !$0 { errorText = nil } }
            )) {
                Button("确定", role: .cancel) { errorText = nil }
            } message: {
                Text(errorText ?? "")
            }
        }
    }

    private func save() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let book = StudyBook(title: cleanTitle, pageCount: 1, localFileName: "",
                             extractionStatus: "手动输入", textCharacterCount: cleanText.count)
        context.insert(book)
        context.insert(BookPage(bookID: book.id, pageNumber: 1, text: cleanText))
        do {
            try context.save()
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
