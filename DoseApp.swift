import SwiftUI
import LocalAuthentication

@main
struct DoseApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var dataStore = DataStore()
    @State private var healthKitService = HealthKitService()
    @State private var notificationService = NotificationService()
    @State private var showSplash = true
    @State private var biometryType: LABiometryType = .none
    @State private var isUnlocked = false
    @State private var isUnlocking = false
    @State private var unlockError: String?

    private var requiresUnlock: Bool {
        biometryType != .none
    }

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

                if !showSplash, requiresUnlock, !isUnlocked {
                    DoseLockView(
                        biometryType: biometryType,
                        isUnlocking: isUnlocking,
                        errorMessage: unlockError
                    ) {
                        Task {
                            await unlock()
                        }
                    }
                    .zIndex(2)
                    .transition(.opacity)
                }

                if showSplash {
                    SplashView()
                        .zIndex(1)
                        .transition(.opacity)
                }
            }
            .onAppear {
                biometryType = availableBiometryType()
                isUnlocked = !requiresUnlock
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                    if requiresUnlock {
                        await unlock()
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard requiresUnlock else { return }
                switch newPhase {
                case .background, .inactive:
                    isUnlocked = false
                case .active:
                    if !showSplash, !isUnlocked, !isUnlocking {
                        Task {
                            await unlock()
                        }
                    }
                @unknown default:
                    break
                }
            }
        }
    }

    private func availableBiometryType() -> LABiometryType {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return .none
        }
        return context.biometryType
    }

    private func unlock() async {
        guard requiresUnlock, !isUnlocking else { return }
        isUnlocking = true
        unlockError = nil
        defer { isUnlocking = false }

        let context = LAContext()
        do {
            try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Dose")
            isUnlocked = true
        } catch let error as LAError where error.code == .userCancel || error.code == .systemCancel || error.code == .appCancel {
            unlockError = nil
        } catch {
            unlockError = error.localizedDescription
        }
    }
}

private struct DoseLockView: View {
    let biometryType: LABiometryType
    let isUnlocking: Bool
    let errorMessage: String?
    let unlockAction: () -> Void

    private var biometricLabel: String {
        biometryType == .faceID ? "Face ID" : "Touch ID"
    }

    private var biometricIcon: String {
        biometryType == .faceID ? "faceid" : "touchid"
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: biometricIcon)
                    .font(.system(size: 42))
                    .foregroundStyle(.primary)

                Text("Dose is locked")
                    .font(.title2.weight(.semibold))

                Text("Authenticate with \(biometricLabel) to access your health data.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: unlockAction) {
                    HStack {
                        if isUnlocking {
                            ProgressView()
                        }
                        Text("Unlock with \(biometricLabel)")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)

                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
        }
    }
}
