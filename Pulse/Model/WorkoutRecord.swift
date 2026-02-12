import Foundation
import SwiftData

@Model
final class WorkoutRecord {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval
    var averageHR: Int
    var maxHR: Int
    var minHR: Int
    var targetZone: Int
    var userMaxHR: Int
    var timeInZone1: TimeInterval
    var timeInZone2: TimeInterval
    var timeInZone3: TimeInterval
    var timeInZone4: TimeInterval
    var timeInZone5: TimeInterval

    @Relationship(deleteRule: .cascade, inverse: \HRSample.workout)
    var samples: [HRSample] = []

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        averageHR: Int,
        maxHR: Int,
        minHR: Int,
        targetZone: Int,
        userMaxHR: Int,
        timeInZone1: TimeInterval,
        timeInZone2: TimeInterval,
        timeInZone3: TimeInterval,
        timeInZone4: TimeInterval,
        timeInZone5: TimeInterval
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.averageHR = averageHR
        self.maxHR = maxHR
        self.minHR = minHR
        self.targetZone = targetZone
        self.userMaxHR = userMaxHR
        self.timeInZone1 = timeInZone1
        self.timeInZone2 = timeInZone2
        self.timeInZone3 = timeInZone3
        self.timeInZone4 = timeInZone4
        self.timeInZone5 = timeInZone5
    }
}
