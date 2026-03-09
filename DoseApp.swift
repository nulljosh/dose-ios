import SwiftUI

@main
struct DoseApp: App {
    @State private var dataStore = DataStore()
    @State private var healthKitService = HealthKitService()
    @State private var notificationService = NotificationService()
    @State private var showSplash = true
    var body: some Scene {
        WindowGroup {
            ZStack {
                TabView {
                    DashboardView(dataStore: dataStore, notificationService: notificationService)
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
                .task {
                    if HealthKitService.isAvailable {
                        await healthKitService.requestAuthorization()
                    }
                }

                if showSplash {
                    SplashView()
                        .zIndex(1)
                        .transition(.opacity)
                }
            }
            .onAppear {
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
