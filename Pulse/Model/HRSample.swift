import Foundation
import SwiftData

@Model
final class HRSample {
    var timestamp: Date
    var bpm: Int
    var workout: WorkoutRecord?

    init(timestamp: Date, bpm: Int) {
        self.timestamp = timestamp
        self.bpm = bpm
    }
}
