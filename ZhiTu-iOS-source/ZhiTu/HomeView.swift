import SwiftUI
import SwiftData

struct HomeView: View {
    let points: [KnowledgePoint]
    let reviews: [ReviewRecord]
    let startLearning: () -> Void

    private var averageMastery: Int {
        guard !points.isEmpty else { return 0 }
        return Int(points.map(\.mastery).reduce(0, +) / Double(points.count) * 100)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("知图 · 今日学习").font(.system(size: 27, weight: .bold)).foregroundStyle(ZT.ink)
                            Text("把知识连起来，把学习留下来。").font(.system(size: 14)).foregroundStyle(ZT.muted)
                        }
                        Spacer()
                        Image(systemName: "sparkle").font(.title2).foregroundStyle(ZT.blue)
                            .frame(width: 44, height: 44).background(.white, in: Circle())
                    }

                    ZTCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("数据结构").font(.system(size: 21, weight: .bold))
                                    Text("最近学习 · 示例教材").font(.system(size: 13)).foregroundStyle(ZT.muted)
                                }
                                Spacer()
                                Image(systemName: "point.3.connected.trianglepath.dotted")
                                    .font(.system(size: 30)).foregroundStyle(ZT.blue)
                            }
                            HStack {
                                Label("\(points.count) 个知识点", systemImage: "circle.hexagongrid")
                                Spacer()
                                Text("整体掌握 \(averageMastery)%")
                            }.font(.system(size: 12, weight: .medium)).foregroundStyle(ZT.muted)
                            ProgressView(value: Double(averageMastery), total: 100).tint(ZT.green)
                            Button(action: startLearning) {
                                HStack {
                                    Text("继续学习")
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white).padding(14)
                                .background(ZT.blue, in: RoundedRectangle(cornerRadius: 13))
                            }.buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 10) {
                        metric("今日复习", value: "\(reviews.filter { $0.dueDate <= .now }.count)", icon: "clock")
                        metric("待巩固", value: "\(points.filter { $0.mastery < 0.4 }.count)", icon: "leaf")
                        metric("知识点", value: "\(points.count)", icon: "circle.grid.2x2")
                    }

                    SectionHeading(title: "今日待办", trailing: "按掌握度推荐")
                    ForEach(points.sorted { $0.mastery < $1.mastery }.prefix(3)) { point in
                        NavigationLink {
                            KnowledgeDetailView(point: point)
                        } label: {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 12).fill(ZT.paper).frame(width: 44, height: 44)
                                    .overlay(Image(systemName: "book.closed").foregroundStyle(ZT.blue))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(point.title).font(.system(size: 15, weight: .semibold)).foregroundStyle(ZT.ink)
                                    Text(point.chapter + " · 第 \(point.pageNumber) 页").font(.system(size: 12)).foregroundStyle(ZT.muted)
                                }
                                Spacer()
                                Text("\(Int(point.mastery * 100))%").font(.system(size: 13, weight: .semibold)).foregroundStyle(ZT.green)
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(ZT.muted)
                            }.padding(12).background(.white, in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(.plain)
                    }

                    ZTCard {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "info.circle.fill").foregroundStyle(ZT.blue)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("演示数据").font(.system(size: 14, weight: .semibold))
                                Text("当前教材、掌握度和题目用于验证界面流程。导入 PDF 和真实 AI 解析将在后续阶段接入。")
                                    .font(.system(size: 12)).foregroundStyle(ZT.muted)
                            }
                        }
                    }
                }.padding(18)
            }
            .background(ZT.paper.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func metric(_ title: String, value: String, icon: String) -> some View {
        ZTCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon).foregroundStyle(ZT.blue)
                Text(value).font(.system(size: 23, weight: .bold)).foregroundStyle(ZT.ink)
                Text(title).font(.system(size: 12)).foregroundStyle(ZT.muted)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
