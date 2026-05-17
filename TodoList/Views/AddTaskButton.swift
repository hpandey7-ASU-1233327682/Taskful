import SwiftUI

/// The round floating + button shown on the Today and Upcoming screens.
struct AddTaskButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Theme.headerGradient, in: Circle())
                .shadow(color: Theme.accent.opacity(0.4), radius: 10, y: 5)
        }
        .accessibilityLabel("Add task")
    }
}
