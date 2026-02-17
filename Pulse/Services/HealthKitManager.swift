import HealthKit

final class HealthKitManager: Sendable {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()

    private init() {}

    func requestAuthorization() async throws {
        let typesToShare: Set<HKSampleType> = [HKWorkoutType.workoutType()]
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.distanceWalkingRunning),
            HKWorkoutType.workoutType()
        ]
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }

    func fetchMaxHeartRate() async -> (bpm: Int, date: Date)? {
        let hrType = HKQuantityType(.heartRate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrType,
                predicate: nil,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, _ in
                guard let samples = results as? [HKQuantitySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let unit = HKUnit.count().unitDivided(by: .minute())
                let bpmValues = samples.map { (bpm: Int($0.quantity.doubleValue(for: unit)), date: $0.endDate) }

                if bpmValues.count > 20 {
                    let sorted = bpmValues.sorted { $0.bpm > $1.bpm }
                    let top3 = Array(sorted.prefix(3))
                    let median = top3.sorted { $0.bpm < $1.bpm }[1]
                    continuation.resume(returning: (median.bpm, median.date))
                } else {
                    let highest = bpmValues.max { $0.bpm < $1.bpm }!
                    continuation.resume(returning: (highest.bpm, highest.date))
                }
            }
            healthStore.execute(query)
        }
    }
}
