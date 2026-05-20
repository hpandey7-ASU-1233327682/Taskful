import SwiftUI
import SwiftData
import UserNotifications

@main
struct TodoListApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Creates the database and hands it to every view in the app.
        .modelContainer(for: [PlannerTask.self, TaskTag.self])
    }
}
