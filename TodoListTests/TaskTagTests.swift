import Testing
import Foundation
@testable import TodoList

@MainActor
struct TaskTagTests {
    @Test func normalizeTrimsSpaces() {
        #expect(TaskTag.normalize("  Work  ") == "Work")
    }

    @Test func normalizeDropsLeadingHash() {
        #expect(TaskTag.normalize("#Study") == "Study")
        #expect(TaskTag.normalize("  ##Home ") == "Home")
    }

    @Test func normalizeKeepsHashesInTheMiddle() {
        #expect(TaskTag.normalize("c#") == "c#")
    }

    @Test func normalizeOfNothingIsEmpty() {
        #expect(TaskTag.normalize("") == "")
        #expect(TaskTag.normalize("   ") == "")
        #expect(TaskTag.normalize("#") == "")
    }

    @Test func existingFindsATagIgnoringCase() {
        let tags = [TaskTag(name: "Work"), TaskTag(name: "Home")]

        let found = TaskTag.existing(named: "work", in: tags)

        #expect(found?.name == "Work")
    }

    @Test func existingIgnoresHashAndSpaces() {
        let tags = [TaskTag(name: "Study")]

        #expect(TaskTag.existing(named: " #STUDY ", in: tags)?.name == "Study")
    }

    @Test func existingReturnsNilWhenThereIsNoMatch() {
        let tags = [TaskTag(name: "Work")]

        #expect(TaskTag.existing(named: "Gym", in: tags) == nil)
    }
}
