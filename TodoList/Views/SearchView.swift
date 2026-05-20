import SwiftUI
import SwiftData

/// Find tasks by text, and narrow them by priority, tag and done/not done.
struct SearchView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PlannerTask.dueDate, order: .reverse) private var allTasks: [PlannerTask]
    @Query(sort: \TaskTag.name) private var allTags: [TaskTag]

    @State private var filter = TaskFilter()
    @State private var taskToEdit: PlannerTask?

    /// Matching tasks grouped by day, newest day first.
    private var groups: [DayGroup] {
        Array(DayGroup.make(from: filter.apply(to: allTasks)).reversed())
    }

    /// Only tags that at least one task uses are worth filtering by.
    private var usedTags: [TaskTag] {
        allTags.filter { !$0.tasks.isEmpty }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    filterControls
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

                ForEach(groups) { group in
                    Section(group.title) {
                        ForEach(group.tasks) { task in
                            TaskRow(task: task)
                                .contentShape(Rectangle())
                                .onTapGesture { taskToEdit = task }
                        }
                        .onDelete { delete(group.tasks, at: $0) }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $filter.searchText, prompt: "Search tasks, notes and tags")
            .overlay {
                if groups.isEmpty {
                    emptyState
                }
            }
            .sheet(item: $taskToEdit) { task in
                TaskFormView(task: task)
            }
        }
    }

    private var filterControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All priorities",
                        color: Theme.accent,
                        isSelected: filter.priority == nil
                    ) {
                        filter.priority = nil
                    }

                    ForEach(Priority.allCases.reversed()) { priority in
                        FilterChip(
                            title: priority.title,
                            color: priority.color,
                            isSelected: filter.priority == priority
                        ) {
                            filter.priority = (filter.priority == priority) ? nil : priority
                        }
                    }
                }
            }

            if !usedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "All tags",
                            color: Theme.accent,
                            isSelected: filter.tag == nil
                        ) {
                            filter.tag = nil
                        }

                        ForEach(usedTags) { tag in
                            let selected = filter.tag?.persistentModelID == tag.persistentModelID
                            FilterChip(
                                title: "#" + tag.name,
                                color: Theme.accent,
                                isSelected: selected
                            ) {
                                filter.tag = selected ? nil : tag
                            }
                        }
                    }
                }
            }

            Picker("Status", selection: $filter.status) {
                ForEach(StatusFilter.allCases) { status in
                    Text(status.title).tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text(filter.isActive ? "No matching tasks" : "No tasks yet")
                .font(.headline)
            Text(filter.isActive ? "Try a different search or clear a filter." : "Tasks you add will show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 120)
    }

    private func delete(_ tasks: [PlannerTask], at offsets: IndexSet) {
        for index in offsets {
            NotificationManager.cancel(tasks[index])
            modelContext.delete(tasks[index])
        }
    }
}

/// A pill-shaped toggle button. Filled when selected, tinted when not.
private struct FilterChip: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(isSelected ? Color.white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? color : color.opacity(0.15), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SearchView()
        .modelContainer(for: [PlannerTask.self, TaskTag.self], inMemory: true)
}
