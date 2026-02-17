import SwiftUI

struct RunDetailView: View {
    let workout: WorkoutRecord

    private var zoneTimes: [(HeartRateZone, TimeInterval)] {
        [
            (.zone1, workout.timeInZone1),
            (.zone2, workout.timeInZone2),
            (.zone3, workout.timeInZone3),
            (.zone4, workout.timeInZone4),
            (.zone5, workout.timeInZone5),
        ]
    }

    private var targetZoneTime: TimeInterval {
        zoneTimes.first { $0.0.rawValue == workout.targetZone }?.1 ?? 0
    }

    private var targetZonePercentage: Double {
        guard workout.duration > 0 else { return 0 }
        return targetZoneTime / workout.duration * 100
    }

    private var targetColor: Color {
        HeartRateZone(rawValue: workout.targetZone)?.color ?? .gray
    }

    private var formattedDistance: String {
        if workout.totalDistance >= 1000 {
            return String(format: "%.2f km", workout.totalDistance / 1000)
        }
        return String(format: "%.0f m", workout.totalDistance)
    }

    private var formattedPace: String {
        guard workout.averagePace > 0 else { return "--" }
        let minutes = Int(workout.averagePace) / 60
        let seconds = Int(workout.averagePace) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroHeader
                    .padding(.bottom, 24)

                VStack(spacing: 24) {
                    statsGrid
                    chartSection
                    zoneBreakdownSection
                    targetHitSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Workout Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroHeader: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [targetColor.opacity(0.6), targetColor.opacity(0.1), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)

            VStack(spacing: 4) {
                Text(Formatters.dateFormatter.string(from: workout.startDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let zone = HeartRateZone(rawValue: workout.targetZone) {
                    Text("Zone \(zone.rawValue) · \(zone.name)")
                        .font(.headline)
                        .foregroundStyle(targetColor)
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(value: Formatters.durationLong(workout.duration), label: "Duration")
            StatCard(value: "\(workout.averageHR)", label: "Avg HR")
            StatCard(value: "\(workout.maxHR)", label: "Max HR")
            StatCard(value: "\(workout.minHR)", label: "Min HR")
            if workout.totalDistance > 0 {
                StatCard(value: formattedDistance, label: "Distance")
                StatCard(value: formattedPace, label: "Avg Pace")
            }
            if workout.cooldownHR > 0 {
                StatCard(value: "\(workout.cooldownHR)", label: "Recovery HR")
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Heart Rate")
                .font(.headline)

            HeartRateChartView(
                samples: workout.samples.sorted { $0.timestamp < $1.timestamp },
                maxHR: workout.userMaxHR,
                targetZone: HeartRateZone(rawValue: workout.targetZone)
            )
            .frame(height: 240)
            .padding(12)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var zoneBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zone Breakdown")
                .font(.headline)

            let total = workout.duration > 0 ? workout.duration : 1

            ForEach(zoneTimes, id: \.0) { zone, time in
                let percentage = time / total * 100
                HStack(spacing: 12) {
                    Text("Z\(zone.rawValue)")
                        .font(.caption.bold())
                        .frame(width: 24)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(zone.color)
                                .frame(width: max(4, geo.size.width * (time / total)))
                        }
                    }
                    .frame(height: 24)

                    Text(String(format: "%.0f%%", percentage))
                        .font(.caption.bold().monospacedDigit())
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }

    private var targetHitSection: some View {
        VStack(spacing: 16) {
            Text("Target Zone Hit")
                .font(.headline)

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: min(targetZonePercentage / 100, 1.0))
                    .stroke(targetColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", targetZonePercentage))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(targetColor)
                    Text("in target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14))
    }
}
