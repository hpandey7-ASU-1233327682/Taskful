import Testing
import Foundation
@testable import TodoList

@MainActor
struct DayGroupTests {
    private let calendar = Calendar.current

    private func day(_ offset: Int) -> Date {
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: offset, to: today) ?? today
    }

    @Test func noTasksMakeNoGroups() {
        #expect(DayGroup.make(from: []).isEmpty)
    }

    @Test func tasksAreGroupedByDayInDateOrder() {
        let tasks = [
            PlannerTask(title: "C", dueDate: day(2)),
            PlannerTask(title: "A", dueDate: day(1)),
            PlannerTask(title: "B", dueDate: day(1)),
        ]

        let groups = DayGroup.make(from: tasks)

        #expect(groups.count == 2)
        #expect(groups[0].day == day(1))
        #expect(groups[0].tasks.count == 2)
        #expect(groups[1].day == day(2))
        #expect(groups[1].tasks.count == 1)
    }

    @Test func importantTasksComeFirstWithinADay() {
        let tasks = [
            PlannerTask(title: "Low", dueDate: day(1), priority: .low),
            PlannerTask(title: "High", dueDate: day(1), priority: .high),
            PlannerTask(title: "Medium", dueDate: day(1), priority: .medium),
        ]

        let titles = DayGroup.make(from: tasks)[0].tasks.map(\.title)

        #expect(titles == ["High", "Medium", "Low"])
    }

    @Test func timedTasksComeBeforeUntimedOnes() {
        let nine = PlannerTask.makeDueDate(day: day(1), time: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()))
        let noon = PlannerTask.makeDueDate(day: day(1), time: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()))

        let tasks = [
            PlannerTask(title: "Untimed high", dueDate: day(1), priority: .high),
            PlannerTask(title: "Noon", dueDate: noon, hasTime: true),
            PlannerTask(title: "Nine", dueDate: nine, hasTime: true),
        ]

        let titles = DayGroup.make(from: tasks)[0].tasks.map(\.title)

        #expect(titles == ["Nine", "Noon", "Untimed high"])
    }

    @Test func titlesAreFriendly() {
        #expect(DayGroup(day: day(0), tasks: []).title == "Today")
        #expect(DayGroup(day: day(1), tasks: []).title == "Tomorrow")
        #expect(DayGroup(day: day(-1), tasks: []).title == "Yesterday")
        #expect(DayGroup(day: day(5), tasks: []).title != "Today")
    }
}
