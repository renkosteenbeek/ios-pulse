import SwiftUI

struct UserProfile {
    @AppStorage("userAge") var userAge: Int = 30
    @AppStorage("manualMaxHR") var manualMaxHR: Int = 190
    @AppStorage("inputMode") var inputMode: String = "age"
    @AppStorage("detectedMaxHR") var detectedMaxHR: Int = 0
    @AppStorage("maxHRSource") var maxHRSource: String = "none"

    var maxHeartRate: Int {
        if maxHRSource == "detected" && detectedMaxHR > 0 {
            return detectedMaxHR
        }
        return inputMode == "age" ? 220 - userAge : manualMaxHR
    }
}
