import Testing
import Foundation
import SwiftData
@testable import TodoList

@MainActor
struct TaskFilterTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: PlannerTask.self, TaskTag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func sampleTasks() -> [PlannerTask] {
        let groceries = PlannerTask(title: "Buy groceries", notes: "Milk and eggs", priority: .low)
        let report = PlannerTask(title: "Finish report", notes: "Send to Priya", priority: .high)
        let gym = PlannerTask(title: "Go to the gym", priority: .medium)
        gym.toggleDone()
        return [groceries, report, gym]
    }

    @Test func emptyFilterKeepsEverythingAndIsNotActive() {
        let filter = TaskFilter()

        #expect(filter.isActive == false)
        #expect(filter.apply(to: sampleTasks()).count == 3)
    }

    @Test func searchMatchesTitleIgnoringCase() {
        var filter = TaskFilter()
        filter.searchText = "GROCERIES"

        let titles = filter.apply(to: sampleTasks()).map(\.title)

        #expect(titles == ["Buy groceries"])
    }

    @Test func searchMatchesNotes() {
        var filter = TaskFilter()
        filter.searchText = "priya"

        let titles = filter.apply(to: sampleTasks()).map(\.title)

        #expect(titles == ["Finish report"])
    }

    @Test func blankSearchDoesNotNarrowAnything() {
        var filter = TaskFilter()
        filter.searchText = "   "

        #expect(filter.isActive == false)
        #expect(filter.apply(to: sampleTasks()).count == 3)
    }

    @Test func priorityFilterKeepsOnlyThatPriority() {
        var filter = TaskFilter()
        filter.priority = .high

        let titles = filter.apply(to: sampleTasks()).map(\.title)

        #expect(filter.isActive)
        #expect(titles == ["Finish report"])
    }

    @Test func statusFilterSeparatesDoneFromToDo() {
        var filter = TaskFilter()

        filter.status = .todo
        #expect(filter.apply(to: sampleTasks()).count == 2)

        filter.status = .done
        #expect(filter.apply(to: sampleTasks()).map(\.title) == ["Go to the gym"])
    }

    @Test func filtersCombine() {
        var filter = TaskFilter()
        filter.priority = .low
        filter.status = .done

        #expect(filter.apply(to: sampleTasks()).isEmpty)
    }

    @Test func tagFilterKeepsOnlyTaggedTasks() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let work = TaskTag(name: "Work")
        let home = TaskTag(name: "Home")
        let report = PlannerTask(title: "Finish report")
        let dishes = PlannerTask(title: "Do dishes")
        context.insert(work)
        context.insert(home)
        context.insert(report)
        context.insert(dishes)
        report.tags = [work]
        dishes.tags = [home]

        var filter = TaskFilter()
        filter.tag = work

        #expect(filter.isActive)
        #expect(filter.apply(to: [report, dishes]).map(\.title) == ["Finish report"])
    }

    @Test func searchAlsoMatchesTagNames() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let study = TaskTag(name: "Study")
        let aws = PlannerTask(title: "Learn cloud basics")
        let other = PlannerTask(title: "Water plants")
        context.insert(study)
        context.insert(aws)
        context.insert(other)
        aws.tags = [study]

        var filter = TaskFilter()
        filter.searchText = "stud"

        #expect(filter.apply(to: [aws, other]).map(\.title) == ["Learn cloud basics"])
    }
}
