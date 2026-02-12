import HealthKit

final class HealthKitManager: Sendable {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()

    private init() {}

    func requestAuthorization() async throws {
        let typesToShare: Set<HKSampleType> = [HKWorkoutType.workoutType()]
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKWorkoutType.workoutType()
        ]
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }
}
