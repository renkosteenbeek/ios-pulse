import SwiftUI

struct ProfileView: View {
    @AppStorage("userAge") private var userAge = 30
    @AppStorage("manualMaxHR") private var manualMaxHR = 190
    @AppStorage("inputMode") private var inputMode = "age"

    private var maxHeartRate: Int {
        inputMode == "age" ? 220 - userAge : manualMaxHR
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("\(maxHeartRate)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                            Text("Max Heart Rate")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        Divider()

                        Picker("Method", selection: $inputMode) {
                            Text("Calculate from age").tag("age")
                            Text("Enter manually").tag("manual")
                        }
                        .pickerStyle(.segmented)

                        if inputMode == "age" {
                            Stepper("Age: \(userAge)", value: $userAge, in: 10...100)
                        } else {
                            Stepper("Max HR: \(manualMaxHR)", value: $manualMaxHR, in: 100...220)
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 0) {
                        Text("ZONE RANGES")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .tracking(1)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)

                        ForEach(HeartRateZone.allCases.reversed(), id: \.self) { zone in
                            let range = zone.bpmRange(maxHR: maxHeartRate)
                            HStack {
                                Text("Z\(zone.rawValue)")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 30)
                                Text(zone.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.85))
                                Spacer()
                                Text("\(range.lowerBound)–\(range.upperBound) BPM")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(zone.color.gradient)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(20)
            }
            .navigationTitle("Profile")
        }
    }
}
