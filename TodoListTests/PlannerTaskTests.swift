import Testing
import Foundation
import SwiftData
@testable import TodoList

@MainActor
struct PlannerTaskTests {
    /// The container must stay alive while the context is used, so return the container.
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: PlannerTask.self, TaskTag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func newTaskStartsNotDone() {
        let task = PlannerTask(title: "Buy milk")

        #expect(task.title == "Buy milk")
        #expect(task.isDone == false)
        #expect(task.completedAt == nil)
        #expect(task.priority == .medium)
        #expect(task.hasTime == false)
    }

    @Test func toggleDoneSetsAndClearsCompletedAt() {
        let task = PlannerTask(title: "Call Sam")

        task.toggleDone()
        #expect(task.isDone)
        #expect(task.completedAt != nil)

        task.toggleDone()
        #expect(task.isDone == false)
        #expect(task.completedAt == nil)
    }

    @Test func priorityIsStoredAsAnInt() {
        let task = PlannerTask(title: "Pay rent", priority: .high)
        #expect(task.priorityRaw == 2)

        task.priority = .low
        #expect(task.priorityRaw == 0)
        #expect(task.priority == .low)
    }

    @Test func unknownPriorityFallsBackToMedium() {
        let task = PlannerTask(title: "Mystery")
        task.priorityRaw = 99

        #expect(task.priority == .medium)
    }

    @Test func isDueTodayIsTrueForTodayOnly() {
        let today = PlannerTask(title: "Now", dueDate: Date())
        let tomorrow = PlannerTask(
            title: "Later",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        )

        #expect(today.isDueToday)
        #expect(tomorrow.isDueToday == false)
    }

    @Test func savedTaskCanBeFetchedBack() throws {
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(PlannerTask(title: "Write tests", priority: .high))
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<PlannerTask>())
        #expect(tasks.count == 1)
        #expect(tasks.first?.title == "Write tests")
        #expect(tasks.first?.priority == .high)
    }

    @Test func deletedTaskIsGone() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let task = PlannerTask(title: "Temporary")
        context.insert(task)
        try context.save()

        context.delete(task)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<PlannerTask>())
        #expect(tasks.isEmpty)
    }

    @Test func tagsAreSharedBetweenTasks() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let tag = TaskTag(name: "Work")
        let first = PlannerTask(title: "Report")
        let second = PlannerTask(title: "Email")
        context.insert(tag)
        context.insert(first)
        context.insert(second)
        first.tags = [tag]
        second.tags = [tag]
        try context.save()

        #expect(tag.tasks.count == 2)
    }
}
