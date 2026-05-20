import SwiftUI
import SwiftData

/// Today's plan: a gradient header with a progress ring, then To do and Completed lists.
struct TodayView: View {
    @Environment(\.modelContext) private var modelContext

    /// Only tasks due today. The filter runs inside SwiftData, not in Swift.
    @Query private var todayTasks: [PlannerTask]

    @State private var showingNewTask = false
    @State private var taskToEdit: PlannerTask?

    init() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        _todayTasks = Query(
            filter: #Predicate<PlannerTask> { $0.dueDate >= start && $0.dueDate < end }
        )
    }

    private var pending: [PlannerTask] {
        todayTasks
            .filter { !$0.isDone }
            .sorted(by: PlannerTask.isOrderedBefore)
    }

    private var completed: [PlannerTask] {
        todayTasks
            .filter { $0.isDone }
            .sorted(by: PlannerTask.isOrderedBefore)
    }

    private var progress: Double {
        guard !todayTasks.isEmpty else { return 0 }
        return Double(completed.count) / Double(todayTasks.count)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                List {
                    if !pending.isEmpty {
                        Section("To do") {
                            ForEach(pending) { task in
                                row(for: task)
                            }
                            .onDelete { delete(pending, at: $0) }
                        }
                    }

                    if !completed.isEmpty {
                        Section("Completed") {
                            ForEach(completed) { task in
                                row(for: task)
                            }
                            .onDelete { delete(completed, at: $0) }
                        }
                    }
                }
                // Keeps the last row from hiding behind the floating + button.
                .contentMargins(.bottom, 96, for: .scrollContent)
                .overlay {
                    if todayTasks.isEmpty {
                        emptyState
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .animation(.default, value: todayTasks.count)
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottomTrailing) {
                AddTaskButton { showingNewTask = true }
                    .padding(24)
            }
            .sheet(isPresented: $showingNewTask) {
                TaskFormView()
            }
            .sheet(item: $taskToEdit) { task in
                TaskFormView(task: task)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(Date.now.formatted(.dateTime.weekday(.wide)))
                    .font(.system(size: 40, weight: .heavy, design: .rounded))

                Text(Date.now.formatted(.dateTime.month(.wide).day()))
                    .font(.title3.weight(.semibold))

                Text(summary)
                    .font(.subheadline)
                    .opacity(0.9)
                    .padding(.top, 4)
            }

            Spacer()

            ProgressRing(progress: progress)
                .frame(width: 100, height: 100)
        }
        .foregroundStyle(.white)
        .padding(24)
        .background(Theme.headerGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var summary: String {
        todayTasks.isEmpty
            ? "Nothing planned yet"
            : "\(completed.count) of \(todayTasks.count) done"
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sun.max")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text("Nothing planned for today")
                .font(.headline)
            Text("Tap + to add your first task.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 60)
    }

    private func row(for task: PlannerTask) -> some View {
        TaskRow(task: task)
            .contentShape(Rectangle())
            .onTapGesture { taskToEdit = task }
    }

    private func delete(_ tasks: [PlannerTask], at offsets: IndexSet) {
        for index in offsets {
            NotificationManager.cancel(tasks[index])
            modelContext.delete(tasks[index])
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [PlannerTask.self, TaskTag.self], inMemory: true)
}
