import Foundation

/// The tasks due on one day, ready to show as a section in a list.
struct DayGroup: Identifiable {
    let day: Date
    let tasks: [PlannerTask]

    var id: Date { day }

    /// A friendly heading: Today, Tomorrow, Yesterday, or the weekday and date.
    var title: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInTomorrow(day) { return "Tomorrow" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    /// Groups tasks by the day they're due. Days come out in order,
    /// and inside each day tasks with a time come first, then the most important.
    static func make(from tasks: [PlannerTask], calendar: Calendar = .current) -> [DayGroup] {
        let grouped = Dictionary(grouping: tasks) { calendar.startOfDay(for: $0.dueDate) }
        return grouped.keys.sorted().map { day in
            let dayTasks = (grouped[day] ?? []).sorted(by: PlannerTask.isOrderedBefore)
            return DayGroup(day: day, tasks: dayTasks)
        }
    }
}
