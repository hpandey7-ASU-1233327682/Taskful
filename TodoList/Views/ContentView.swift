import SwiftUI
import SwiftData

/// The root of the app: a tab bar with Today, Upcoming and Search.
struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            UpcomingView()
                .tabItem { Label("Upcoming", systemImage: "calendar") }

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PlannerTask.self, TaskTag.self], inMemory: true)
}
