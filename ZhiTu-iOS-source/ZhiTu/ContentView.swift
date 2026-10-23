import SwiftUI
import SwiftData

enum MainTab: String, CaseIterable {
    case home = "首页"
    case graph = "图谱"
    case learn = "学习"
    case mistakes = "错题"
    case profile = "我的"

    var icon: String {
        switch self {
        case .home: "house"
        case .graph: "point.3.connected.trianglepath.dotted"
        case .learn: "book.closed"
        case .mistakes: "square.stack.3d.up"
        case .profile: "person.crop.circle"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \KnowledgePoint.title) private var points: [KnowledgePoint]
    @Query(sort: \AnswerAttempt.answeredAt, order: .reverse) private var attempts: [AnswerAttempt]
    @Query(sort: \ReviewRecord.dueDate) private var reviews: [ReviewRecord]
    @State private var selectedTab: MainTab = .home
    @State private var seeded = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(points: points, reviews: reviews) { selectedTab = .learn }
                .tabItem { Label(MainTab.home.rawValue, systemImage: MainTab.home.icon) }
                .tag(MainTab.home)
            GraphView(points: points)
                .tabItem { Label(MainTab.graph.rawValue, systemImage: MainTab.graph.icon) }
                .tag(MainTab.graph)
            QuizView()
                .tabItem { Label(MainTab.learn.rawValue, systemImage: MainTab.learn.icon) }
                .tag(MainTab.learn)
            MistakesView(attempts: attempts)
                .tabItem { Label(MainTab.mistakes.rawValue, systemImage: MainTab.mistakes.icon) }
                .tag(MainTab.mistakes)
            ProfileView()
                .tabItem { Label(MainTab.profile.rawValue, systemImage: MainTab.profile.icon) }
                .tag(MainTab.profile)
        }
        .tint(ZT.blue)
        .task {
            guard !seeded else { return }
            seeded = true
            seedDemoIfNeeded()
        }
    }

    private func seedDemoIfNeeded() {
        guard points.isEmpty else { return }
        let demoPoints = [
            KnowledgePoint(title: "数据结构", summary: "数据组织、存储与操作方式的抽象。", mastery: 0.42, chapter: "第一章", pageNumber: 12),
            KnowledgePoint(title: "线性表", summary: "由 n 个数据元素构成的有限序列。", mastery: 0.68, chapter: "第二章", pageNumber: 26),
            KnowledgePoint(title: "顺序表", summary: "使用连续存储单元依次存储元素。", mastery: 0.76, chapter: "第二章", pageNumber: 29),
            KnowledgePoint(title: "链表", summary: "通过结点和指针建立逻辑上的线性关系。", mastery: 0.31, chapter: "第二章", pageNumber: 36),
            KnowledgePoint(title: "栈", summary: "遵循后进先出原则的线性数据结构。", mastery: 0.22, chapter: "第三章", pageNumber: 51),
            KnowledgePoint(title: "队列", summary: "遵循先进先出原则的线性数据结构。", mastery: 0.54, chapter: "第三章", pageNumber: 63),
            KnowledgePoint(title: "树", summary: "用于表示层次关系的非线性数据结构。", mastery: 0.15, chapter: "第五章", pageNumber: 90)
        ]
        demoPoints.forEach { context.insert($0) }
        context.insert(StudyQuestion(
            pointTitle: "链表",
            stem: "单链表中，访问第 i 个结点通常需要什么操作？",
            options: ["直接按下标随机访问", "从头结点开始逐个遍历", "对所有结点进行排序", "将链表转换成树"],
            correctAnswer: "从头结点开始逐个遍历",
            explanation: "单链表结点通常不支持按下标直接访问，需要从头结点沿 next 指针逐个移动。",
            sourcePage: 36
        ))
        context.insert(StudyQuestion(
            pointTitle: "栈",
            stem: "栈的典型访问规则是什么？",
            options: ["先进先出", "后进先出", "随机访问", "按优先级访问"],
            correctAnswer: "后进先出",
            explanation: "栈在一端进行插入和删除，最后入栈的元素最先出栈。",
            sourcePage: 51
        ))
        context.insert(ReviewRecord(pointTitle: "链表", dueDate: .now, stability: 0.8, difficulty: 7))
        context.insert(ReviewRecord(pointTitle: "栈", dueDate: .now, stability: 0.5, difficulty: 8))
        context.insert(ReviewRecord(pointTitle: "线性表", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now, stability: 2, difficulty: 5))
    }
}
