import SwiftUI

enum HeartRateZone: Int, CaseIterable, Sendable, Codable {
    case zone1 = 1, zone2, zone3, zone4, zone5

    var name: String {
        switch self {
        case .zone1: "Very Light"
        case .zone2: "Fat Burn"
        case .zone3: "Aerobic"
        case .zone4: "Anaerobic"
        case .zone5: "Maximum"
        }
    }

    var color: Color {
        switch self {
        case .zone1: .blue
        case .zone2: .green
        case .zone3: .yellow
        case .zone4: .orange
        case .zone5: .red
        }
    }

    var percentageRange: ClosedRange<Double> {
        switch self {
        case .zone1: 0.50...0.60
        case .zone2: 0.60...0.70
        case .zone3: 0.70...0.80
        case .zone4: 0.80...0.90
        case .zone5: 0.90...1.00
        }
    }

    func bpmRange(maxHR: Int) -> ClosedRange<Int> {
        let lower = Int(Double(maxHR) * percentageRange.lowerBound)
        let upper = Int(Double(maxHR) * percentageRange.upperBound)
        return lower...upper
    }

    static func zone(for bpm: Int, maxHR: Int) -> HeartRateZone? {
        for zone in HeartRateZone.allCases.reversed() {
            if bpm >= Int(Double(maxHR) * zone.percentageRange.lowerBound) {
                return zone
            }
        }
        return nil
    }
}
