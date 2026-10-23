import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("学习资料") {
                    NavigationLink {
                        BookLibraryView()
                    } label: {
                        Label("教材库 · PDF 与手动输入", systemImage: "books.vertical")
                    }
                    NavigationLink {
                        AISettingsView()
                    } label: {
                        Label("AI 服务设置", systemImage: "sparkles")
                    }
                    NavigationLink {
                        ReviewView()
                    } label: {
                        Label("复习计划", systemImage: "calendar.badge.clock")
                    }
                }
                Section("当前功能状态") {
                    Label("PDF 原文提取与页码定位", systemImage: "checkmark.circle")
                    Label("OpenAI 兼容 AI 拆解接口", systemImage: "checkmark.circle")
                    Label("扫描版 OCR（后续接入）", systemImage: "clock")
                    Label("正式 FSRS 调度（后续接入）", systemImage: "clock")
                }
                Section("数据与隐私") {
                    Label("学习记录保存在本机 SwiftData", systemImage: "internaldrive")
                    Label("API Key 使用 iOS Keychain 保存", systemImage: "key.horizontal")
                    Text("若使用云端 AI，提交分析时会将所选教材提取的文本发送到配置的接口。请仅上传你有权处理的资料。")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Section {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("知图 · 原型版").font(.system(size: 14, weight: .semibold))
                        Text("AI 输出可能存在错误，生成后请检查知识点、答案和教材证据。")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                    }.padding(.vertical, 5)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ZT.paper)
            .navigationTitle("我的")
        }
    }
}
