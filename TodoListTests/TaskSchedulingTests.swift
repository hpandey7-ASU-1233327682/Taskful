import Testing
import Foundation
@testable import TodoList

@MainActor
struct TaskSchedulingTests {
    private let calendar = Calendar.current

    private func time(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    // MARK: - Due date

    @Test func dueDateWithoutATimeIsMidnight() {
        let result = PlannerTask.makeDueDate(day: time(15, 30), time: nil)

        #expect(result == calendar.startOfDay(for: result))
        #expect(calendar.isDateInToday(result))
    }

    @Test func dueDateWithATimeKeepsTheDayAndSetsTheTime() {
        let day = calendar.date(byAdding: .day, value: 3, to: Date()) ?? Date()

        let result = PlannerTask.makeDueDate(day: day, time: time(14, 45))
        let parts = calendar.dateComponents([.hour, .minute], from: result)

        #expect(calendar.isDate(result, inSameDayAs: day))
        #expect(parts.hour == 14)
        #expect(parts.minute == 45)
    }

    // MARK: - Ordering

    @Test func earlierTimedTaskComesFirst() {
        let early = PlannerTask(title: "Early", dueDate: time(8), hasTime: true)
        let late = PlannerTask(title: "Late", dueDate: time(17), hasTime: true)

        #expect(PlannerTask.isOrderedBefore(early, late))
        #expect(PlannerTask.isOrderedBefore(late, early) == false)
    }

    @Test func timedTaskComesBeforeUntimedTask() {
        let timed = PlannerTask(title: "Timed", dueDate: time(8), priority: .low, hasTime: true)
        let untimed = PlannerTask(title: "Untimed", priority: .high)

        #expect(PlannerTask.isOrderedBefore(timed, untimed))
        #expect(PlannerTask.isOrderedBefore(untimed, timed) == false)
    }

    @Test func untimedTasksAreOrderedByPriority() {
        let high = PlannerTask(title: "High", priority: .high)
        let low = PlannerTask(title: "Low", priority: .low)

        #expect(PlannerTask.isOrderedBefore(high, low))
        #expect(PlannerTask.isOrderedBefore(low, high) == false)
    }

    // MARK: - Reminders

    @Test func reminderFiresTheChosenMinutesBefore() {
        let due = time(15, 0)
        let task = PlannerTask(title: "Meeting", dueDate: due, hasTime: true, reminderLeadMinutes: 15)

        #expect(task.reminderDate == due.addingTimeInterval(-15 * 60))
    }

    @Test func reminderAtTimeFiresAtTheDueDate() {
        let due = time(15, 0)
        let task = PlannerTask(title: "Meeting", dueDate: due, hasTime: true, reminderLeadMinutes: 0)

        #expect(task.reminderDate == due)
    }

    @Test func noReminderWhenNoneWasChosen() {
        let task = PlannerTask(title: "Meeting", dueDate: time(15), hasTime: true)

        #expect(task.reminderDate == nil)
    }

    @Test func noReminderWithoutATime() {
        let task = PlannerTask(title: "Someday", reminderLeadMinutes: 5)

        #expect(task.reminderDate == nil)
    }

    @Test func noReminderOnceTheTaskIsDone() {
        let task = PlannerTask(title: "Meeting", dueDate: time(15), hasTime: true, reminderLeadMinutes: 5)
        #expect(task.reminderDate != nil)

        task.toggleDone()

        #expect(task.reminderDate == nil)
    }
}
