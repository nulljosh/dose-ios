import SwiftUI

@main
struct DoseApp: App {
    @State private var dataStore = DataStore()
    @State private var healthKitService = HealthKitService()

    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView(dataStore: dataStore)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                LibraryView(dataStore: dataStore)
                    .tabItem {
                        Label("Library", systemImage: "book.fill")
                    }

                InsightsView(dataStore: dataStore)
                    .tabItem {
                        Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                    }

                BodyView(dataStore: dataStore, healthKitService: healthKitService)
                    .tabItem {
                        Label("Body", systemImage: "heart.fill")
                    }
            }
        }
    }
}
