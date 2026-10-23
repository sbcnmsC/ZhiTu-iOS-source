import SwiftUI
import SwiftData

@main
struct ZhiTuApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StudyBook.self,
            BookPage.self,
            KnowledgePoint.self,
            KnowledgeEdge.self,
            StudyQuestion.self,
            AnswerAttempt.self,
            ReviewRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
