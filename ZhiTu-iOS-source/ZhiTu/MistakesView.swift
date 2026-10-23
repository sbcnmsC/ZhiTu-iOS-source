import SwiftUI

struct MistakesView: View {
    let attempts: [AnswerAttempt]
    private var mistakes: [AnswerAttempt] { attempts.filter { !$0.isCorrect } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("错题本").font(.system(size: 27, weight: .bold)).foregroundStyle(ZT.ink)
                    Text("把错误变成下一次学习的线索。").font(.system(size: 13)).foregroundStyle(ZT.muted)

                    HStack(spacing: 10) {
                        stat("错题记录", value: "\(mistakes.count)", color: .orange)
                        stat("已作答", value: "\(attempts.count)", color: ZT.blue)
                        stat("正确率", value: attempts.isEmpty ? "—" : "\(Int(Double(attempts.filter(\.isCorrect).count) / Double(attempts.count) * 100))%", color: ZT.green)
                    }

                    if mistakes.isEmpty {
                        ZTCard {
                            VStack(spacing: 10) {
                                Image(systemName: "checkmark.seal").font(.system(size: 32)).foregroundStyle(ZT.green)
                                Text("目前还没有错题").font(.system(size: 16, weight: .semibold))
                                Text("完成学习抽查后，答错的题目会自动出现在这里。")
                                    .font(.system(size: 12)).foregroundStyle(ZT.muted).multilineTextAlignment(.center)
                            }.frame(maxWidth: .infinity).padding(.vertical, 16)
                        }
                    } else {
                        ForEach(mistakes) { item in
                            ZTCard {
                                VStack(alignment: .leading, spacing: 9) {
                                    Text(item.questionStem).font(.system(size: 15, weight: .semibold)).foregroundStyle(ZT.ink)
                                    Label("你的答案：\(item.selectedAnswer)", systemImage: "xmark.circle")
                                        .font(.system(size: 12)).foregroundStyle(.orange)
                                    Text(item.answeredAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 11)).foregroundStyle(ZT.muted)
                                }
                            }
                        }
                    }
                }.padding(18)
            }.background(ZT.paper.ignoresSafeArea()).toolbar(.hidden, for: .navigationBar)
        }
    }

    private func stat(_ title: String, value: String, color: Color) -> some View {
        ZTCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(value).font(.system(size: 22, weight: .bold)).foregroundStyle(color)
                Text(title).font(.system(size: 12)).foregroundStyle(ZT.muted)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
