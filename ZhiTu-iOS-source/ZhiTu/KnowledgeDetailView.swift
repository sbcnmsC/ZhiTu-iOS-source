import SwiftUI

struct KnowledgeDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var point: KnowledgePoint

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ZTCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(point.chapter.uppercased()).font(.system(size: 11, weight: .bold)).foregroundStyle(ZT.blue)
                            Spacer()
                            Text("掌握度 \(Int(point.mastery * 100))%").font(.system(size: 12, weight: .semibold)).foregroundStyle(ZT.green)
                        }
                        Text(point.title).font(.system(size: 28, weight: .bold)).foregroundStyle(ZT.ink)
                        Text(point.summary).font(.system(size: 15)).foregroundStyle(ZT.muted)
                        ProgressView(value: point.mastery).tint(ZT.green)
                    }
                }

                SectionHeading(title: "知识关系")
                ZTCard {
                    VStack(alignment: .leading, spacing: 12) {
                        relation("前置知识", detail: "建议先确认基础概念", icon: "arrow.turn.up.left")
                        Divider()
                        relation("相关知识", detail: "在图谱中继续探索相邻节点", icon: "point.3.connected.trianglepath.dotted")
                        Divider()
                        relation("易错提醒", detail: "通过答题历史逐步生成", icon: "lightbulb")
                    }
                }

                SectionHeading(title: "教材原文", trailing: "演示锚点")
                ZTCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(point.bookTitle, systemImage: "doc.text").font(.system(size: 14, weight: .semibold))
                        Text("\(point.chapter) · 第 \(point.pageNumber) 页")
                            .font(.system(size: 12)).foregroundStyle(ZT.muted)
                        Text("这里将在接入 PDFKit 后展示可验证的原文片段，并支持点击跳转到 PDF 对应页面。当前页码为示例数据。")
                            .font(.system(size: 13)).foregroundStyle(ZT.muted)
                    }
                }

                Button {
                    point.lastReviewedAt = .now
                    point.mastery = min(1, point.mastery + 0.08)
                    point.nextReviewAt = Calendar.current.date(byAdding: .day, value: 1, to: .now)
                } label: {
                    Text("标记为已复习").font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity).padding(15)
                        .background(ZT.blue, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white)
                }
                Text("演示按钮会更新本地掌握度；正式版应根据实际作答结果和 FSRS 状态更新。")
                    .font(.system(size: 11)).foregroundStyle(ZT.muted)
            }.padding(18)
        }
        .background(ZT.paper.ignoresSafeArea())
        .navigationTitle("知识点详情")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func relation(_ title: String, detail: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(ZT.blue).frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(ZT.ink)
                Text(detail).font(.system(size: 12)).foregroundStyle(ZT.muted)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(ZT.muted)
        }
    }
}
