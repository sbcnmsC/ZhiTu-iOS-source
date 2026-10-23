import SwiftUI

struct GraphView: View {
    let points: [KnowledgePoint]
    @State private var selectedPoint: KnowledgePoint?
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var showPrerequisites = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("知识图谱").font(.system(size: 26, weight: .bold)).foregroundStyle(ZT.ink)
                        Text("点选节点，逐层探索知识关系").font(.system(size: 13)).foregroundStyle(ZT.muted)
                    }
                    Spacer()
                    Button {
                        showPrerequisites.toggle()
                    } label: {
                        Image(systemName: showPrerequisites ? "point.3.connected.trianglepath.dotted" : "circle.grid.2x2")
                            .padding(11).background(.white, in: Circle())
                    }
                    .tint(ZT.blue)
                    .accessibilityLabel(showPrerequisites ? "显示知识关系" : "隐藏知识关系")
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 10)

                GeometryReader { proxy in
                    let positions = nodePositions(in: proxy.size)
                    ZStack {
                        Canvas { context, _ in
                            for (a, b) in graphEdges {
                                guard let p1 = positions[a], let p2 = positions[b] else { continue }
                                var path = Path()
                                path.move(to: p1)
                                path.addLine(to: p2)
                                context.stroke(path, with: .color(ZT.blue.opacity(showPrerequisites ? 0.35 : 0.08)), lineWidth: 1.4)
                            }
                        }

                        ForEach(graphTitles.indices, id: \.self) { index in
                            let title = graphTitles[index]
                            let point = pointFor(title)
                            let position = positions[index] ?? CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                            Button {
                                selectedPoint = point
                            } label: {
                                VStack(spacing: 5) {
                                    Circle()
                                        .fill(point.map { $0.mastery < 0.4 ? Color.orange.opacity(0.85) : ZT.blue } ?? ZT.green)
                                        .frame(width: index == 0 ? 64 : 48, height: index == 0 ? 64 : 48)
                                        .overlay {
                                            Image(systemName: index == 0 ? "circle.grid.3x3.fill" : "circle.fill")
                                                .font(.system(size: 10))
                                                .foregroundStyle(.white.opacity(0.8))
                                        }
                                        .shadow(color: ZT.blue.opacity(0.15), radius: 8, y: 3)
                                    Text(title)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(ZT.ink)
                                        .lineLimit(1)
                                }
                                .frame(width: 78)
                            }
                            .buttonStyle(.plain)
                            .position(x: position.x, y: position.y)
                        }
                    }
                    .scaleEffect(scale)
                    .offset(offset)
                    .contentShape(Rectangle())
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = min(max(value, 0.75), 1.6)
                            }
                            .simultaneously(
                                with: DragGesture()
                                    .onChanged { value in offset = value.translation }
                            )
                    )
                }
                .background(
                    RadialGradient(colors: [.white, ZT.paper], center: .center, startRadius: 10, endRadius: 360)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 12)

                HStack(spacing: 14) {
                    legend(color: ZT.blue, label: "掌握较好")
                    legend(color: .orange, label: "需要巩固")
                    legend(color: ZT.green, label: "当前主题")
                    Spacer()
                    Button("重置视图") {
                        scale = 1
                        offset = .zero
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .padding(16)
            }
            .background(ZT.paper.ignoresSafeArea())
            .sheet(item: $selectedPoint) { point in
                NavigationStack {
                    KnowledgeDetailView(point: point)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("完成") { selectedPoint = nil }
                            }
                        }
                }
            }
        }
    }

    private var graphTitles: [String] {
        let preferred = ["数据结构", "线性表", "顺序表", "链表", "栈", "队列", "树"]
        let existing = points.map(\.title)
        let result = preferred.filter { existing.contains($0) }
        return result.isEmpty ? Array(existing.prefix(7)) : result
    }

    private var graphEdges: [(Int, Int)] {
        graphTitles.count > 1 ? (1..<graphTitles.count).map { (0, $0) } : []
    }

    private func nodePositions(in size: CGSize) -> [Int: CGPoint] {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        var result: [Int: CGPoint] = [0: center]
        let count = max(graphTitles.count - 1, 1)
        for index in 1..<graphTitles.count {
            let angle = (Double(index - 1) / Double(count)) * 2 * Double.pi - Double.pi / 2
            result[index] = CGPoint(
                x: center.x + cos(angle) * min(size.width * 0.34, 130),
                y: center.y + sin(angle) * min(size.height * 0.31, 190)
            )
        }
        return result
    }

    private func pointFor(_ title: String) -> KnowledgePoint? {
        points.first { $0.title == title }
    }

    private func legend(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.system(size: 10)).foregroundStyle(ZT.muted)
        }
    }
}
