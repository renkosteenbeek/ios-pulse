import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Query(sort: \WorkoutRecord.startDate, order: .reverse)
    private var workouts: [WorkoutRecord]

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    ContentUnavailableView(
                        "No Workouts Yet",
                        systemImage: "heart.text.clipboard",
                        description: Text("Complete a workout to see it here.")
                    )
                } else {
                    List(workouts) { workout in
                        NavigationLink(value: workout) {
                            workoutRow(workout)
                        }
                    }
                    .navigationDestination(for: WorkoutRecord.self) { workout in
                        RunDetailView(workout: workout)
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    private func workoutRow(_ workout: WorkoutRecord) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(zoneColor(for: workout.targetZone))
                .frame(width: 4, height: 50)

            VStack(alignment: .leading, spacing: 6) {
                Text(Formatters.dateFormatter.string(from: workout.startDate))
                    .font(.headline)
                Text(Formatters.durationLong(workout.duration))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                zoneDistributionBar(workout)
                    .frame(height: 4)
                    .clipShape(Capsule())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(workout.averageHR)")
                        .font(.title3.bold().monospacedDigit())
                    Text("avg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Circle()
                    .fill(zoneColor(for: workout.targetZone))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }

    private func zoneDistributionBar(_ workout: WorkoutRecord) -> some View {
        GeometryReader { geo in
            let total = workout.duration > 0 ? workout.duration : 1
            let zones: [(HeartRateZone, TimeInterval)] = [
                (.zone1, workout.timeInZone1),
                (.zone2, workout.timeInZone2),
                (.zone3, workout.timeInZone3),
                (.zone4, workout.timeInZone4),
                (.zone5, workout.timeInZone5),
            ]

            HStack(spacing: 1) {
                ForEach(zones, id: \.0) { zone, time in
                    let fraction = time / total
                    if fraction > 0.01 {
                        Rectangle()
                            .fill(zone.color)
                            .frame(width: geo.size.width * fraction)
                    }
                }
            }
        }
    }

    private func zoneColor(for zone: Int) -> Color {
        HeartRateZone(rawValue: zone)?.color ?? .gray
    }
}
