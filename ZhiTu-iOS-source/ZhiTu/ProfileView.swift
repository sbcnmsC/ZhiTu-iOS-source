import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("学习资料") {
                    Label("教材管理", systemImage: "books.vertical")
                    Label("导入 PDF（开发中）", systemImage: "doc.badge.plus")
                    Label("手动添加知识点（开发中）", systemImage: "square.and.pencil")
                }
                Section("AI 与复习") {
                    Label("AI 服务配置（开发中）", systemImage: "sparkles")
                    Label("FSRS 复习设置（开发中）", systemImage: "calendar.badge.clock")
                }
                Section("数据与隐私") {
                    Label("本地数据存储", systemImage: "internaldrive")
                    Label("导出与备份（开发中）", systemImage: "square.and.arrow.up")
                }
                Section {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("知图 · 原型版").font(.system(size: 14, weight: .semibold))
                        Text("当前版本使用本地演示数据。请勿将示例页码当作真实教材引用。")
                            .font(.system(size: 12)).foregroundStyle(ZT.muted)
                    }.padding(.vertical, 5)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ZT.paper)
            .navigationTitle("我的")
        }
    }
}
