import SwiftUI

struct HealthGradeView: View {
    @Bindable var dataStore: DataStore
    var healthKitService: HealthKitService
    @State private var result: HealthScoreResult = .empty

    private func recompute() {
        result = HealthScoringService.computeFullScore(dataStore: dataStore, healthKit: healthKitService)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                scoreHero
                if !result.anomalies.isEmpty {
                    anomalySection
                }
                if !result.adherence.isEmpty {
                    adherenceSection
                }
                breakdownSection
            }
            .padding()
        }
        .onAppear { recompute() }
        .onChange(of: dataStore.healthEntries.count) { recompute() }
        .onChange(of: dataStore.biometricEntries.count) { recompute() }
        .onChange(of: dataStore.doseEntries.count) { recompute() }
    }

    // MARK: - Score Hero

    private var scoreHero: some View {
        VStack(spacing: 16) {
            ScoreRingView(score: result.breakdown.total, rank: result.rank)

            HStack(spacing: 8) {
                Text(result.rank.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(result.rank.color)
                    .clipShape(Capsule())

                if result.breakdown.confidence < 100 {
                    Text("\(result.breakdown.confidence)% data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if result.breakdown.confidence > 0 && result.breakdown.confidence < 60 {
                Text("Log more metrics for a more accurate score")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Anomaly Alerts

    private var anomalySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alerts")
                .font(.headline)

            ForEach(result.anomalies, id: \.self) { anomaly in
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(anomaly)
                        .font(.subheadline)
                }
            }
        }
    }

    // MARK: - Supplement Adherence

    private var adherenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Supplement adherence (14d)")
                .font(.headline)

            ForEach(result.adherence) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(item.taken)/\(item.total) days (\(item.rate)%)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.quaternarySystemFill))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(adherenceColor(rate: item.rate))
                                .frame(width: geo.size.width * CGFloat(item.rate) / 100.0)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
    }

    private func adherenceColor(rate: Int) -> Color {
        if rate >= 80 { return .green }
        if rate >= 50 { return .orange }
        return .red
    }

    // MARK: - Score Breakdown

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Score breakdown")
                .font(.headline)

            let metricLabels: [(key: String, label: String, max: Int)] = [
                ("sleepHours", "Sleep", 30),
                ("steps", "Steps", 22),
                ("heartRate", "Heart Rate", 22),
                ("bloodPressureSys", "Blood Pressure", 13),
                ("moodScore", "Mood", 13),
            ]

            FlowLayout(spacing: 8) {
                ForEach(metricLabels, id: \.key) { metric in
                    let score = result.breakdown.parts[metric.key] ?? nil
                    HStack(spacing: 4) {
                        Text(metric.label)
                            .font(.caption.weight(.medium))
                        if let score {
                            Text("\(score)/\(metric.max)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("--")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                }
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
