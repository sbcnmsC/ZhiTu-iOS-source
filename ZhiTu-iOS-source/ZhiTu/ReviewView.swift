import SwiftUI
import SwiftData

struct ReviewView: View {
    @Query(sort: \ReviewRecord.dueDate) private var reviews: [ReviewRecord]

    var body: some View {
        NavigationStack {
            List {
                Section("今天") {
                    let due = reviews.filter { $0.dueDate <= .now }
                    if due.isEmpty {
                        Text("今天没有到期的复习任务").foregroundStyle(ZT.muted)
                    } else {
                        ForEach(due) { item in
                            HStack {
                                Image(systemName: "clock.fill").foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.pointTitle).font(.system(size: 15, weight: .semibold))
                                    Text("复习状态：\(item.status)").font(.system(size: 12)).foregroundStyle(ZT.muted)
                                }
                                Spacer()
                                Text("开始").font(.system(size: 12, weight: .semibold)).foregroundStyle(ZT.blue)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
                Section("之后") {
                    ForEach(reviews.filter { $0.dueDate > .now }) { item in
                        HStack {
                            Text(item.pointTitle)
                            Spacer()
                            Text(item.dueDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 12)).foregroundStyle(ZT.muted)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ZT.paper)
            .navigationTitle("复习计划")
        }
    }
}
