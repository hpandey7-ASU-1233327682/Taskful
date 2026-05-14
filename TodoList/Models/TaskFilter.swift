import Foundation
import SwiftData

/// Which tasks to show by completion: everything, only unfinished ones, or only finished ones.
enum StatusFilter: String, CaseIterable, Identifiable {
    case all
    case todo
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .todo: return "To do"
        case .done: return "Done"
        }
    }
}

/// The search box and filter chips on the Search tab, as one value.
struct TaskFilter {
    var searchText = ""
    var priority: Priority?
    var tag: TaskTag?
    var status: StatusFilter = .all

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// True when anything is narrowing the results.
    var isActive: Bool {
        !trimmedSearch.isEmpty || priority != nil || tag != nil || status != .all
    }

    func apply(to tasks: [PlannerTask]) -> [PlannerTask] {
        tasks.filter(matches)
    }

    func matches(_ task: PlannerTask) -> Bool {
        if let priority, task.priority != priority {
            return false
        }

        if let tag, !task.tags.contains(where: { $0.persistentModelID == tag.persistentModelID }) {
            return false
        }

        switch status {
        case .all: break
        case .todo: if task.isDone { return false }
        case .done: if !task.isDone { return false }
        }

        guard !trimmedSearch.isEmpty else { return true }
        return task.title.localizedCaseInsensitiveContains(trimmedSearch)
            || task.notes.localizedCaseInsensitiveContains(trimmedSearch)
            || task.tags.contains { $0.name.localizedCaseInsensitiveContains(trimmedSearch) }
    }
}
