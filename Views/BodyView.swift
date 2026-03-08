import SwiftUI

struct BodyView: View {
    @Bindable var dataStore: DataStore
    var healthKitService: HealthKitService
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedTab) {
                    Text("Biometrics").tag(0)
                    Text("Health").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    BiometricsTab(dataStore: dataStore, healthKitService: healthKitService)
                } else {
                    HealthTab(dataStore: dataStore)
                }
            }
            .navigationTitle("Body")
        }
    }
}

private struct BiometricsTab: View {
    @Bindable var dataStore: DataStore
    var healthKitService: HealthKitService
    @State private var weight = ""
    @State private var bpSystolic = ""
    @State private var bpDiastolic = ""
    @State private var heartRate = ""
    @State private var sleepHours = 8.0
    @State private var steps = ""
    @State private var notes = ""

    private var recentEntries: [BiometricEntry] {
        Array(dataStore.biometricEntries.sorted { $0.date > $1.date }.prefix(10))
    }

    var body: some View {
        Form {
            if HealthKitService.isAvailable {
                Section("Apple Health") {
                    if healthKitService.isAuthorized {
                        healthDataGrid
                    } else {
                        Button("Connect Apple Health") {
                            Task { await healthKitService.requestAuthorization() }
                        }
                    }
                }
            }

            Section("Log Biometrics") {
                HStack {
                    Text("Weight (lbs)")
                    Spacer()
                    TextField("--", text: $weight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                HStack {
                    Text("Blood Pressure")
                    Spacer()
                    TextField("sys", text: $bpSystolic)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 50)
                    Text("/")
                    TextField("dia", text: $bpDiastolic)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 50)
                }

                HStack {
                    Text("Heart Rate (bpm)")
                    Spacer()
                    TextField("--", text: $heartRate)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                VStack(alignment: .leading) {
                    Text("Sleep: \(sleepHours, specifier: "%.1f") hrs")
                    Slider(value: $sleepHours, in: 0...12, step: 0.5)
                }

                HStack {
                    Text("Steps")
                    Spacer()
                    TextField("--", text: $steps)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            Section {
                Button("Save Biometrics") {
                    let entry = BiometricEntry(
                        weight: Double(weight),
                        bpSystolic: Int(bpSystolic),
                        bpDiastolic: Int(bpDiastolic),
                        heartRate: Int(heartRate),
                        sleepHours: sleepHours,
                        steps: Int(steps),
                        notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    dataStore.addBiometricEntry(entry)
                    clearForm()
                }
            }

            if !recentEntries.isEmpty {
                Section("Recent") {
                    ForEach(recentEntries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date, style: .date)
                                .font(.subheadline.weight(.semibold))
                            HStack(spacing: 12) {
                                if let w = entry.weight {
                                    Label("\(w, specifier: "%.1f") lbs", systemImage: "scalemass")
                                }
                                if let hr = entry.heartRate {
                                    Label("\(hr) bpm", systemImage: "heart")
                                }
                                if let s = entry.steps {
                                    Label("\(s)", systemImage: "figure.walk")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            if let sys = entry.bpSystolic, let dia = entry.bpDiastolic {
                                Text("BP: \(sys)/\(dia)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let sl = entry.sleepHours {
                                Text("Sleep: \(sl, specifier: "%.1f") hrs")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var healthDataGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            healthCard("Heart Rate", value: healthKitService.heartRate.map { "\(Int($0)) bpm" }, icon: "heart.fill", color: .red)
            healthCard("Resting HR", value: healthKitService.restingHeartRate.map { "\(Int($0)) bpm" }, icon: "heart", color: .red)
            healthCard("HRV", value: healthKitService.hrv.map { "\(Int($0)) ms" }, icon: "waveform.path.ecg", color: .purple)
            healthCard("SpO2", value: healthKitService.bloodOxygen.map { "\(Int($0))%" }, icon: "lungs.fill", color: .blue)
            healthCard("Respiratory", value: healthKitService.respiratoryRate.map { "\(Int($0))/min" }, icon: "wind", color: .teal)
            healthCard("Sleep", value: healthKitService.sleepHours.map { String(format: "%.1fh", $0) }, icon: "bed.double.fill", color: .indigo)
            healthCard("Steps", value: healthKitService.steps.map { "\($0)" }, icon: "figure.walk", color: .green)
            healthCard("Energy", value: healthKitService.activeEnergy.map { "\(Int($0)) kcal" }, icon: "flame.fill", color: .orange)
            healthCard("Distance", value: healthKitService.walkingDistance.map { String(format: "%.1f mi", $0) }, icon: "map.fill", color: .cyan)
            healthCard("Weight", value: healthKitService.bodyMass.map { String(format: "%.1f lbs", $0) }, icon: "scalemass.fill", color: .brown)
        }
        if let sys = healthKitService.systolicBP, let dia = healthKitService.diastolicBP {
            HStack {
                Image(systemName: "stethoscope")
                    .foregroundStyle(.pink)
                Text("Blood Pressure")
                Spacer()
                Text("\(sys)/\(dia) mmHg")
                    .fontWeight(.semibold)
            }
        }
        Button("Refresh") {
            Task { await healthKitService.fetchAll() }
        }
    }

    private func healthCard(_ title: String, value: String?, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            Text(value ?? "--")
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func clearForm() {
        weight = ""
        bpSystolic = ""
        bpDiastolic = ""
        heartRate = ""
        sleepHours = 8.0
        steps = ""
        notes = ""
    }
}

private struct HealthTab: View {
    @Bindable var dataStore: DataStore
    @State private var mood = 3.0
    @State private var energy = 3.0
    @State private var sleepHours = 8.0
    @State private var notes = ""

    private var recentEntries: [HealthEntry] {
        Array(dataStore.healthEntries.sorted { $0.date > $1.date }.prefix(10))
    }

    var body: some View {
        Form {
            Section("Daily Check-In") {
                VStack(alignment: .leading) {
                    Text("Mood: \(Int(mood))")
                    Slider(value: $mood, in: 1...5, step: 1)
                }

                VStack(alignment: .leading) {
                    Text("Energy: \(Int(energy))")
                    Slider(value: $energy, in: 1...5, step: 1)
                }

                VStack(alignment: .leading) {
                    Text("Sleep: \(sleepHours, specifier: "%.1f") hrs")
                    Slider(value: $sleepHours, in: 0...12, step: 0.5)
                }

                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            Section {
                Button("Save Health Entry") {
                    dataStore.addHealthEntry(
                        HealthEntry(
                            mood: Int(mood),
                            energy: Int(energy),
                            sleepHours: sleepHours,
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    )
                    notes = ""
                }
            }

            if !recentEntries.isEmpty {
                Section("Recent") {
                    ForEach(recentEntries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date, style: .date)
                                .font(.subheadline.weight(.semibold))
                            HStack(spacing: 12) {
                                Text("Mood: \(entry.mood)/5")
                                Text("Energy: \(entry.energy)/5")
                                Text("Sleep: \(entry.sleepHours, specifier: "%.1f")h")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
