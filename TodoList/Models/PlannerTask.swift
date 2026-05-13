import Foundation
import SwiftData

/// One thing to do on a given day, optionally at a specific time.
/// `@Model` tells SwiftData to save it to disk.
@Model
final class PlannerTask {
    var title: String
    var notes: String
    /// The day the task is due. When `hasTime` is true this also holds the time of day.
    var dueDate: Date
    var priorityRaw: Int
    var isDone: Bool
    var completedAt: Date?
    var createdAt: Date

    /// Whether `dueDate` includes a meaningful time of day.
    /// The default value lets SwiftData upgrade tasks saved before this field existed.
    var hasTime: Bool = false

    /// How many minutes before the task's time to send a reminder. nil means no reminder.
    var reminderLeadMinutes: Int?

    /// Names this task's scheduled notification so it can be replaced or cancelled later.
    var reminderID: String?

    /// Labels on this task, like Work or Study. A tag can be on many tasks.
    @Relationship(inverse: \TaskTag.tasks) var tags: [TaskTag] = []

    /// Priority as an enum. SwiftData stores `priorityRaw`, an Int, behind the scenes.
    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    var isDueToday: Bool {
        Calendar.current.isDateInToday(dueDate)
    }

    /// When the reminder should go off, or nil if this task shouldn't have one.
    var reminderDate: Date? {
        guard hasTime, !isDone, let minutes = reminderLeadMinutes else { return nil }
        return Calendar.current.date(byAdding: .minute, value: -minutes, to: dueDate)
    }

    init(
        title: String,
        notes: String = "",
        dueDate: Date = Date(),
        priority: Priority = .medium,
        hasTime: Bool = false,
        reminderLeadMinutes: Int? = nil
    ) {
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priorityRaw = priority.rawValue
        self.isDone = false
        self.completedAt = nil
        self.createdAt = Date()
        self.hasTime = hasTime
        self.reminderLeadMinutes = reminderLeadMinutes
        self.reminderID = nil
    }

    func toggleDone() {
        isDone.toggle()
        completedAt = isDone ? Date() : nil
    }

    /// Builds the value to store in `dueDate`: the chosen day, plus the time of day if there is one.
    /// With no time, the result is midnight at the start of that day.
    static func makeDueDate(day: Date, time: Date?, calendar: Calendar = .current) -> Date {
        let startOfDay = calendar.startOfDay(for: day)
        guard let time else { return startOfDay }
        let parts = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: parts.hour ?? 0,
            minute: parts.minute ?? 0,
            second: 0,
            of: startOfDay
        ) ?? startOfDay
    }

    /// Planner order: tasks with a time come first, earliest first.
    /// Tasks without a time follow, most important first.
    static func isOrderedBefore(_ a: PlannerTask, _ b: PlannerTask) -> Bool {
        switch (a.hasTime, b.hasTime) {
        case (true, true): return a.dueDate < b.dueDate
        case (true, false): return true
        case (false, true): return false
        case (false, false): return a.priorityRaw > b.priorityRaw
        }
    }
}
