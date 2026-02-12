import SwiftUI
import Charts

struct HeartRateChartView: View {
    let samples: [HRSample]
    let maxHR: Int
    var targetZone: HeartRateZone?

    var body: some View {
        Chart {
            ForEach(HeartRateZone.allCases, id: \.self) { zone in
                let range = zone.bpmRange(maxHR: maxHR)
                RectangleMark(
                    xStart: .value("Start", samples.first?.timestamp ?? Date()),
                    xEnd: .value("End", samples.last?.timestamp ?? Date()),
                    yStart: .value("Low", range.lowerBound),
                    yEnd: .value("High", range.upperBound)
                )
                .foregroundStyle(zone.color.opacity(zone == targetZone ? 0.25 : 0.1))
            }

            ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
                let zone = HeartRateZone.zone(for: sample.bpm, maxHR: maxHR)
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("BPM", sample.bpm)
                )
                .foregroundStyle(zone?.color ?? .gray)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5))
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel(format: .dateTime.minute().second())
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
