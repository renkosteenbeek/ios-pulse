import SwiftUI
import HealthKit

struct CooldownView: View {
    @Bindable var workoutManager: WorkoutManager
    let peakHR: Int
    let onDone: @MainActor @Sendable () -> Void

    @State private var startHR: Int = 0
    @State private var currentHR: Int = 0
    @State private var timeRemaining: Int = 120
    @State private var timer: Timer?
    @State private var hrQuery: HKAnchoredObjectQuery?

    private var recovery: Int {
        guard startHR > 0 && currentHR > 0 else { return 0 }
        return max(0, startHR - currentHR)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
                .symbolEffect(.pulse)
                .padding(.bottom, 16)

            Text("Cool Down")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Keep moving lightly")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 40)

            if currentHR > 0 {
                Text("\(currentHR)")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("BPM")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 24)

                if recovery > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down")
                            .font(.title2.bold())
                        Text("\(recovery)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.green)

                    Text("recovery from \(startHR) BPM")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            } else {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(.white)
                    .padding(.bottom, 24)

                Text("Measuring heart rate...")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            VStack(spacing: 16) {
                let minutes = timeRemaining / 60
                let seconds = timeRemaining % 60
                Text(String(format: "%d:%02d", minutes, seconds))
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))

                Button {
                    stopMonitoring()
                    onDone()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.green, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 40)
        }
        .background(.black)
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
    }

    private func startMonitoring() {
        startHR = peakHR > 0 ? peakHR : 0

        let hrType = HKQuantityType(.heartRate)
        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: HKQuery.predicateForSamples(withStart: Date(), end: nil),
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { _, samples, _, _, _ in
            processSamples(samples)
        }

        query.updateHandler = { _, samples, _, _, _ in
            processSamples(samples)
        }

        hrQuery = query
        HealthKitManager.shared.healthStore.execute(query)

        let done = onDone
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    stopMonitoring()
                    done()
                }
            }
        }
    }

    private nonisolated func processSamples(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample],
              let latest = quantitySamples.last else { return }

        let bpm = Int(latest.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
        let peak = peakHR

        Task { @MainActor in
            currentHR = bpm
            if startHR == 0 || startHR == peak {
                startHR = bpm
            }
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        if let query = hrQuery {
            HealthKitManager.shared.healthStore.stop(query)
            hrQuery = nil
        }
    }
}
