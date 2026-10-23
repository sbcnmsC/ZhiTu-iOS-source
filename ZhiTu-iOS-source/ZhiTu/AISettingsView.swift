import SwiftUI

struct AISettingsView: View {
    @AppStorage("aiEndpoint") private var endpoint = ""
    @AppStorage("aiModel") private var model = "deepseek-chat"
    @State private var apiKey = SecretStore.read()
    @State private var notice: String?
    @State private var showKey = false

    var body: some View {
        Form {
            Section("兼容 OpenAI Chat Completions 的接口") {
                TextField("接口完整地址", text: $endpoint, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                TextField("模型名称", text: $model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                HStack {
                    Group {
                        if showKey {
                            TextField("API Key（可留空）", text: $apiKey)
                        } else {
                            SecureField("API Key（可留空）", text: $apiKey)
                        }
                    }
                    Button(showKey ? "隐藏" : "显示") { showKey.toggle() }
                        .font(.system(size: 12, weight: .medium))
                }
                Button("保存设置") {
                    do {
                        try SecretStore.write(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
                        notice = "设置已保存。"
                    } catch {
                        notice = "保存密钥失败：\(error.localizedDescription)"
                    }
                }
                .fontWeight(.semibold)
            }

            Section("安全与兼容性") {
                Text("建议填写你控制的 HTTPS 后端代理地址，由服务端保管供应商密钥。直接连接第三方模型虽然可用于个人原型，但会把调用权限放在客户端环境中；不要将生产密钥写进源码或公开仓库。")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
                Text("接口需兼容 POST /v1/chat/completions 风格的请求，并返回 choices[0].message.content。不同供应商可能存在格式差异。")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
            }

            Section {
                Button("清除本机 API Key", role: .destructive) {
                    SecretStore.clear()
                    apiKey = ""
                    notice = "本机 Key 已清除。"
                }
            }
        }
        .navigationTitle("AI 服务设置")
        .navigationBarTitleDisplayMode(.inline)
        .alert("AI 服务设置", isPresented: Binding(
            get: { notice != nil },
            set: { if !$0 { notice = nil } }
        )) {
            Button("确定", role: .cancel) { notice = nil }
        } message: {
            Text(notice ?? "")
        }
    }
}
