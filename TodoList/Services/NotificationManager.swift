import Foundation
import UserNotifications

/// Schedules and cancels the reminder notification for a task.
@MainActor
enum NotificationManager {
    private static var center: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }

    /// Asks iOS for permission to show alerts. Safe to call more than once;
    /// iOS only shows the permission prompt the first time.
    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Makes the scheduled notification match the task: replaces the old one,
    /// or removes it when the task no longer needs a reminder.
    static func sync(_ task: PlannerTask) {
        cancel(task)

        guard let fireDate = task.reminderDate, fireDate > Date() else {
            task.reminderID = nil
            return
        }

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = body(for: task)
        content.sound = .default

        let parts = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)

        let id = UUID().uuidString
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        task.reminderID = id
    }

    /// Removes a task's pending notification. Call this before deleting the task.
    static func cancel(_ task: PlannerTask) {
        guard let id = task.reminderID else { return }
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    private static func body(for task: PlannerTask) -> String {
        let time = task.dueDate.formatted(date: .omitted, time: .shortened)
        switch task.reminderLeadMinutes ?? 0 {
        case 0: return "Now, \(time)"
        case 60: return "In 1 hour, \(time)"
        case let minutes: return "In \(minutes) minutes, \(time)"
        }
    }
}
