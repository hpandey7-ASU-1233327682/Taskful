import SwiftUI
import SwiftData

/// Everything that isn't today: an Overdue section, then one section per upcoming day.
struct UpcomingView: View {
    @Environment(\.modelContext) private var modelContext

    /// Unfinished tasks from before today.
    @Query private var overdue: [PlannerTask]

    /// Tasks from tomorrow onward.
    @Query private var upcoming: [PlannerTask]

    @State private var showingNewTask = false
    @State private var taskToEdit: PlannerTask?

    init() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        _overdue = Query(
            filter: #Predicate<PlannerTask> { $0.dueDate < today && !$0.isDone },
            sort: \PlannerTask.dueDate
        )
        _upcoming = Query(
            filter: #Predicate<PlannerTask> { $0.dueDate >= tomorrow },
            sort: \PlannerTask.dueDate
        )
    }

    private var groups: [DayGroup] {
        DayGroup.make(from: upcoming)
    }

    var body: some View {
        NavigationStack {
            List {
                if !overdue.isEmpty {
                    Section {
                        ForEach(overdue) { task in
                            row(for: task)
                        }
                        .onDelete { delete(overdue, at: $0) }
                    } header: {
                        Text("Overdue")
                            .foregroundStyle(Theme.high)
                    }
                }

                ForEach(groups) { group in
                    Section(group.title) {
                        ForEach(group.tasks) { task in
                            row(for: task)
                        }
                        .onDelete { delete(group.tasks, at: $0) }
                    }
                }
            }
            // Keeps the last row from hiding behind the floating + button.
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("Upcoming")
            .overlay {
                if overdue.isEmpty && upcoming.isEmpty {
                    emptyState
                }
            }
            .overlay(alignment: .bottomTrailing) {
                AddTaskButton { showingNewTask = true }
                    .padding(24)
            }
            .sheet(isPresented: $showingNewTask) {
                TaskFormView(defaultDay: tomorrow)
            }
            .sheet(item: $taskToEdit) { task in
                TaskFormView(task: task)
            }
        }
    }

    private var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    private func row(for task: PlannerTask) -> some View {
        TaskRow(task: task)
            .contentShape(Rectangle())
            .onTapGesture { taskToEdit = task }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text("Nothing coming up")
                .font(.headline)
            Text("Tasks you plan for later days show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func delete(_ tasks: [PlannerTask], at offsets: IndexSet) {
        for index in offsets {
            NotificationManager.cancel(tasks[index])
            modelContext.delete(tasks[index])
        }
    }
}

#Preview {
    UpcomingView()
        .modelContainer(for: [PlannerTask.self, TaskTag.self], inMemory: true)
}
