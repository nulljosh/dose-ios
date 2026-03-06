import SwiftUI

@main
struct DoseApp: App {
    @State private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView(dataStore: dataStore)
                    .tabItem {
                        Label("Dashboard", systemImage: "house.fill")
                    }

                LogView(dataStore: dataStore)
                    .tabItem {
                        Label("Log", systemImage: "plus.circle.fill")
                    }

                HistoryView(dataStore: dataStore)
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }

                HealthView(dataStore: dataStore)
                    .tabItem {
                        Label("Health", systemImage: "heart.fill")
                    }
            }
        }
    }
}
