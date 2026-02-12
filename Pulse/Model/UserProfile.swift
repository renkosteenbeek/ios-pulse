import SwiftUI

struct UserProfile {
    @AppStorage("userAge") var userAge: Int = 30
    @AppStorage("manualMaxHR") var manualMaxHR: Int = 190
    @AppStorage("inputMode") var inputMode: String = "age"

    var maxHeartRate: Int {
        inputMode == "age" ? 220 - userAge : manualMaxHR
    }
}
