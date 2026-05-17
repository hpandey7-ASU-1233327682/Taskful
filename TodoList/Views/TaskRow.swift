import SwiftUI

/// One task in a list: checkbox, title, time and notes, tags, and a priority badge.
struct TaskRow: View {
    let task: PlannerTask

    var body: some View {
        HStack(spacing: 14) {
            Button(action: toggle) {
                checkbox
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? .secondary : .primary)

                if task.hasTime || !task.notes.isEmpty {
                    HStack(spacing: 6) {
                        if task.hasTime {
                            HStack(spacing: 4) {
                                Image(systemName: task.reminderLeadMinutes == nil ? "clock" : "bell.fill")
                                Text(task.dueDate.formatted(date: .omitted, time: .shortened))
                            }
                        }
                        if !task.notes.isEmpty {
                            Text(task.notes)
                                .lineLimit(1)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if !task.tags.isEmpty {
                    Text(task.tags.map { "#" + $0.name }.sorted().joined(separator: " "))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(task.priority.title)
                .font(.caption.weight(.bold))
                .foregroundStyle(task.priority.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(task.priority.color.opacity(0.15), in: Capsule())
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var checkbox: some View {
        if task.isDone {
            Image(systemName: "checkmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Theme.low)
                .font(.system(size: 28))
        } else {
            Circle()
                .stroke(task.priority.color, lineWidth: 2)
                .frame(width: 26, height: 26)
                .padding(1)
        }
    }

    private func toggle() {
        withAnimation {
            task.toggleDone()
        }
        // A finished task shouldn't remind you, and an unfinished one should again.
        NotificationManager.sync(task)
    }
}
