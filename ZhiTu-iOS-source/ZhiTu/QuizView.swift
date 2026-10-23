import SwiftUI
import SwiftData

struct QuizView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \StudyQuestion.pointTitle) private var questions: [StudyQuestion]
    @State private var index = 0
    @State private var selected: String?
    @State private var submitted = false

    private var question: StudyQuestion? {
        guard !questions.isEmpty else { return nil }
        return questions[index % questions.count]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("学习抽查").font(.system(size: 27, weight: .bold)).foregroundStyle(ZT.ink)
                            Text("先独立思考，再查看解析").font(.system(size: 13)).foregroundStyle(ZT.muted)
                        }
                        Spacer()
                        Image(systemName: "sparkles").font(.title2).foregroundStyle(ZT.blue)
                    }

                    if let question {
                        HStack {
                            Text(question.pointTitle).font(.system(size: 12, weight: .semibold)).foregroundStyle(ZT.blue)
                            Spacer()
                            Text("第 \(index + 1) 题").font(.system(size: 12)).foregroundStyle(ZT.muted)
                        }
                        Text(question.stem).font(.system(size: 21, weight: .bold)).foregroundStyle(ZT.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        ForEach(question.options, id: \.self) { option in
                            Button {
                                guard !submitted else { return }
                                selected = option
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selected == option ? "largecircle.fill.circle" : "circle")
                                        .foregroundStyle(selected == option ? ZT.blue : ZT.muted)
                                    Text(option).font(.system(size: 15)).foregroundStyle(ZT.ink)
                                    Spacer()
                                    if submitted && option == question.correctAnswer {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(ZT.green)
                                    }
                                }.padding(15)
                                    .background(selected == option ? ZT.blue.opacity(0.08) : .white,
                                                in: RoundedRectangle(cornerRadius: 15))
                                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(selected == option ? ZT.blue : ZT.line, lineWidth: 1))
                            }.buttonStyle(.plain)
                        }

                        if submitted {
                            ZTCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label(selected == question.correctAnswer ? "回答正确" : "再巩固一下",
                                          systemImage: selected == question.correctAnswer ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(selected == question.correctAnswer ? ZT.green : .orange)
                                    Text(question.explanation).font(.system(size: 14)).foregroundStyle(ZT.ink)
                                    if !question.sourceEvidence.isEmpty {
                                        Text("教材证据：“\(question.sourceEvidence)”")
                                            .font(.system(size: 13))
                                            .foregroundStyle(ZT.ink)
                                            .padding(10)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(ZT.paper, in: RoundedRectangle(cornerRadius: 10))
                                    }
                                    Divider()
                                    Label("来源：\(question.sourceBook) · 第 \(question.sourcePage) 页",
                                          systemImage: "doc.text")
                                        .font(.system(size: 11)).foregroundStyle(ZT.muted)
                                }
                            }
                        }

                        Button {
                            if submitted {
                                index = (index + 1) % max(questions.count, 1)
                                selected = nil
                                submitted = false
                            } else if let selected {
                                context.insert(AnswerAttempt(questionID: question.id, questionStem: question.stem,
                                                             selectedAnswer: selected, isCorrect: selected == question.correctAnswer))
                                submitted = true
                            }
                        } label: {
                            Text(submitted ? "下一题" : "提交答案")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity).padding(15)
                                .background((selected == nil && !submitted) ? ZT.muted.opacity(0.4) : ZT.blue,
                                            in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }.buttonStyle(.plain).disabled(selected == nil && !submitted)
                    } else {
                        ContentUnavailableView("还没有题目", systemImage: "questionmark.folder",
                                               description: Text("后续可由教材自动生成题目，当前可先检查示例数据是否已初始化。"))
                    }
                }.padding(18)
            }
            .background(ZT.paper.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
