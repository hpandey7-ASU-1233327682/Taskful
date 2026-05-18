import SwiftUI
import SwiftData

/// The sheet for adding a new task or editing an existing one.
/// Pass a task to edit it; pass nothing to create a new one.
struct TaskFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \TaskTag.name) private var allTags: [TaskTag]

    private let task: PlannerTask?

    @State private var title: String
    @State private var notes: String
    @State private var day: Date
    @State private var hasTime: Bool
    @State private var time: Date
    @State private var reminderLead: Int?
    @State private var priority: Priority
    @State private var selectedTags: [TaskTag]
    @State private var newTagName = ""

    /// The choices in the "Remind me" menu. nil means no reminder.
    private static let reminderOptions: [(minutes: Int?, label: String)] = [
        (nil, "Never"),
        (0, "At time of task"),
        (5, "5 minutes before"),
        (15, "15 minutes before"),
        (30, "30 minutes before"),
        (60, "1 hour before"),
    ]

    init(task: PlannerTask? = nil, defaultDay: Date = Date()) {
        self.task = task
        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.notes ?? "")
        _day = State(initialValue: task?.dueDate ?? defaultDay)
        _hasTime = State(initialValue: task?.hasTime ?? false)
        _time = State(initialValue: task?.dueDate ?? Date())
        _reminderLead = State(initialValue: task?.reminderLeadMinutes)
        _priority = State(initialValue: task?.priority ?? .medium)
        _selectedTags = State(initialValue: task?.tags ?? [])
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Every tag to offer as a chip, including ones just created in this form.
    private var chipTags: [TaskTag] {
        var tags = allTags
        for tag in selectedTags where !tags.contains(where: { $0.persistentModelID == tag.persistentModelID }) {
            tags.append(tag)
        }
        return tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    DatePicker("Day", selection: $day, displayedComponents: .date)

                    Toggle("Add a time", isOn: $hasTime.animation())

                    if hasTime {
                        DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)

                        Picker("Remind me", selection: $reminderLead) {
                            ForEach(Self.reminderOptions, id: \.label) { option in
                                Text(option.label).tag(option.minutes)
                            }
                        }
                    }
                }

                Section {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { priority in
                            Text(priority.title).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Tags") {
                    if !chipTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(chipTags) { tag in
                                    tagChip(tag)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    HStack {
                        TextField("New tag", text: $newTagName)
                            .textInputAutocapitalization(.never)
                            .submitLabel(.done)
                            .onSubmit(addTag)
                        Button("Add", action: addTag)
                            .disabled(TaskTag.normalize(newTagName).isEmpty)
                    }
                }
            }
            .navigationTitle(task == nil ? "New task" : "Edit task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(trimmedTitle.isEmpty)
                }
            }
        }
        // The full form is tall; open it at full height so no field is hidden.
        .presentationDetents([.large])
    }

    private func tagChip(_ tag: TaskTag) -> some View {
        let selected = isSelected(tag)
        return Button {
            toggle(tag)
        } label: {
            Text("#" + tag.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? Color.white : Theme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? Theme.accent : Theme.accent.opacity(0.15), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func isSelected(_ tag: TaskTag) -> Bool {
        selectedTags.contains { $0.persistentModelID == tag.persistentModelID }
    }

    private func toggle(_ tag: TaskTag) {
        if isSelected(tag) {
            selectedTags.removeAll { $0.persistentModelID == tag.persistentModelID }
        } else {
            selectedTags.append(tag)
        }
    }

    /// Adds the typed tag (or picks the existing one with the same name) and selects it.
    private func addTag() {
        let name = TaskTag.normalize(newTagName)
        guard !name.isEmpty else { return }

        let tag: TaskTag
        if let existing = TaskTag.existing(named: name, in: chipTags) {
            tag = existing
        } else {
            tag = TaskTag(name: name)
            modelContext.insert(tag)
        }

        if !isSelected(tag) {
            selectedTags.append(tag)
        }
        newTagName = ""
    }

    private func save() {
        let dueDate = PlannerTask.makeDueDate(day: day, time: hasTime ? time : nil)
        let lead = hasTime ? reminderLead : nil

        let saved: PlannerTask
        if let task {
            task.title = trimmedTitle
            task.notes = notes
            task.dueDate = dueDate
            task.priority = priority
            task.hasTime = hasTime
            task.reminderLeadMinutes = lead
            saved = task
        } else {
            saved = PlannerTask(
                title: trimmedTitle,
                notes: notes,
                dueDate: dueDate,
                priority: priority,
                hasTime: hasTime,
                reminderLeadMinutes: lead
            )
            modelContext.insert(saved)
        }
        saved.tags = selectedTags

        dismiss()

        // Ask for notification permission the first time a reminder is chosen,
        // then schedule (or clear) this task's notification.
        Task { @MainActor in
            if lead != nil {
                _ = await NotificationManager.requestAuthorization()
            }
            NotificationManager.sync(saved)
        }
    }
}

#Preview {
    TaskFormView()
        .modelContainer(for: [PlannerTask.self, TaskTag.self], inMemory: true)
}
