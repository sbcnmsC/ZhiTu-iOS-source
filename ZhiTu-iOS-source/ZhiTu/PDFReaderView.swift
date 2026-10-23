import SwiftUI
import PDFKit
import SwiftData
import UIKit

struct PDFReaderView: View {
    let book: StudyBook
    var initialPage: Int = 1
    @Query private var pages: [BookPage]
    @State private var selectedPage: Int
    @State private var showText = true

    init(book: StudyBook, initialPage: Int = 1) {
        self.book = book
        self.initialPage = initialPage
        _selectedPage = State(initialValue: max(1, initialPage))
        let id = book.id
        _pages = Query(
            filter: #Predicate<BookPage> { $0.bookID == id },
            sort: [SortDescriptor(\BookPage.pageNumber)]
        )
    }

    private var documentURL: URL? {
        PDFImportService.storedPDFURL(fileName: book.localFileName)
    }

    private var selectedText: String {
        pages.first(where: { $0.pageNumber == selectedPage })?.text ?? ""
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title).font(.system(size: 20, weight: .bold)).foregroundStyle(ZT.ink)
                        Text("\(book.pageCount) 页 · 已提取 \(book.textCharacterCount) 个字符")
                            .font(.system(size: 12)).foregroundStyle(ZT.muted)
                    }
                    Spacer()
                    Menu {
                        ForEach(1...max(book.pageCount, 1), id: \.self) { page in
                            Button("第 \(page) 页") { selectedPage = page }
                        }
                    } label: {
                        Label("第 \(selectedPage) 页", systemImage: "doc.text.magnifyingglass")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }

                if book.localFileName.isEmpty {
                    ZTCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("手动输入资料", systemImage: "text.alignleft")
                                .font(.system(size: 15, weight: .semibold))
                            Text("这份资料没有 PDF 文件，下面展示你手动输入的原文。")
                                .font(.system(size: 12)).foregroundStyle(ZT.muted)
                        }
                    }
                } else if let documentURL, FileManager.default.fileExists(atPath: documentURL.path) {
                    PDFKitReader(url: documentURL, pageNumber: selectedPage)
                        .frame(height: 430)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ZT.line, lineWidth: 1))
                } else {
                    ZTCard {
                        ContentUnavailableView("找不到本地 PDF", systemImage: "doc.questionmark",
                                               description: Text("请重新导入这份教材。"))
                    }
                }

                HStack {
                    SectionHeading(title: "本页原文")
                    Spacer()
                    Button(showText ? "收起" : "展开") { showText.toggle() }
                        .font(.system(size: 12, weight: .medium))
                }

                if showText {
                    ZTCard {
                        if selectedText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("本页没有可提取的文字", systemImage: "text.viewfinder")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("这通常表示页面是扫描图片。当前版本不会伪造原文；OCR 可在后续版本接入。")
                                    .font(.system(size: 12)).foregroundStyle(ZT.muted)
                            }
                        } else {
                            Text(selectedText)
                                .font(.system(size: 14))
                                .foregroundStyle(ZT.ink)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        selectedPage = max(1, selectedPage - 1)
                    } label: {
                        Label("上一页", systemImage: "chevron.left")
                            .frame(maxWidth: .infinity).padding(12)
                            .background(.white, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedPage <= 1)

                    Button {
                        selectedPage = min(max(1, book.pageCount), selectedPage + 1)
                    } label: {
                        HStack {
                            Text("下一页")
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity).padding(12)
                        .background(ZT.blue, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.white)
                    }
                    .disabled(selectedPage >= book.pageCount)
                }
                .font(.system(size: 13, weight: .semibold))
            }
            .padding(16)
        }
        .background(ZT.paper.ignoresSafeArea())
        .navigationTitle("教材阅读")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PDFKitReader: UIViewRepresentable {
    let url: URL
    let pageNumber: Int

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePage
        view.displayDirection = .vertical
        view.usePageViewController(true, withViewOptions: nil)
        view.backgroundColor = UIColor.secondarySystemBackground
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        guard let document = view.document, document.pageCount > 0 else { return }
        let index = min(max(pageNumber - 1, 0), document.pageCount - 1)
        if let page = document.page(at: index), view.currentPage !== page {
            view.go(to: page)
        }
    }
}
