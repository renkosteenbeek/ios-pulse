import HealthKit
import SwiftUI

@MainActor
@Observable
final class WorkoutManager: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    var currentHR: Int = 0
    var currentZone: HeartRateZone?
    var isActive: Bool = false
    var isPaused: Bool = false
    var elapsedTime: TimeInterval = 0
    var samples: [(Date, Int)] = []
    var maxHR: Int = 190

    nonisolated(unsafe) private var cachedMaxHR: Int = 190

    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private let healthStore = HKHealthStore()

    func startWorkout() async throws {
        cachedMaxHR = maxHR

        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor

        session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
        builder = session?.associatedWorkoutBuilder() as? HKLiveWorkoutBuilder

        let dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
        builder?.dataSource = dataSource

        session?.delegate = self
        builder?.delegate = self

        let startDate = Date()
        session?.startActivity(with: startDate)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder?.beginCollection(withStart: startDate) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        isActive = true
    }

    func pauseWorkout() {
        session?.pause()
    }

    func resumeWorkout() {
        session?.resume()
    }

    func endWorkout() async throws -> (samples: [(Date, Int)], duration: TimeInterval, startDate: Date) {
        let endDate = Date()
        let startDate = builder?.startDate ?? endDate
        session?.end()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder?.endCollection(withEnd: endDate) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder?.finishWorkout { workout, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        let collected = samples
        let elapsed = builder?.elapsedTime ?? 0
        isActive = false
        isPaused = false
        currentHR = 0
        currentZone = nil
        session = nil
        builder = nil
        samples = []
        return (collected, elapsed, startDate)
    }

    var builderElapsedTime: TimeInterval {
        builder?.elapsedTime ?? 0
    }

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let hrType = HKQuantityType(.heartRate)
        guard collectedTypes.contains(hrType) else { return }

        let stats = workoutBuilder.statistics(for: hrType)
        let quantity = stats?.mostRecentQuantity()
        let bpm = quantity?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        let maxHR = cachedMaxHR

        Task { @MainActor in
            guard let bpm else { return }
            self.currentHR = Int(bpm)
            self.currentZone = HeartRateZone.zone(for: Int(bpm), maxHR: maxHR)
            self.samples.append((Date(), Int(bpm)))
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        let newState = toState
        Task { @MainActor in
            self.isPaused = (newState == .paused)
            self.isActive = (newState == .running || newState == .paused)
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
}
