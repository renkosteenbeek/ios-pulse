import SwiftUI

struct ProfileView: View {
    @AppStorage("userAge") private var userAge = 30
    @AppStorage("manualMaxHR") private var manualMaxHR = 190
    @AppStorage("inputMode") private var inputMode = "age"
    @AppStorage("detectedMaxHR") private var detectedMaxHR = 0
    @AppStorage("maxHRSource") private var maxHRSource = "none"
    @AppStorage("selectedVoiceId") private var selectedVoiceId = ""

    @State private var showDetectionSheet = false
    @State private var isAnalyzing = false
    @State private var analysisResult: (bpm: Int, date: Date)?
    @State private var audioCoach = AudioCoach()

    private var maxHeartRate: Int {
        if maxHRSource == "detected" && detectedMaxHR > 0 {
            return detectedMaxHR
        }
        return inputMode == "age" ? 220 - userAge : manualMaxHR
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
                            if maxHRSource == "detected" {
                                Text("Auto-detected from HealthKit")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        Divider()

                        Button {
                            isAnalyzing = true
                            analysisResult = nil
                            showDetectionSheet = true
                            Task {
                                try? await HealthKitManager.shared.requestAuthorization()
                                let result = await HealthKitManager.shared.fetchMaxHeartRate()
                                try? await Task.sleep(for: .seconds(2))
                                analysisResult = result
                                isAnalyzing = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: "waveform.path.ecg")
                                Text("Detect from HealthKit")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.red)
                        }

                        if maxHRSource == "detected" {
                            Button {
                                maxHRSource = "none"
                            } label: {
                                Text("Clear detected value")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()

                        Picker("Method", selection: $inputMode) {
                            Text("Calculate from age").tag("age")
                            Text("Enter manually").tag("manual")
                        }
                        .pickerStyle(.segmented)
                        .disabled(maxHRSource == "detected")
                        .opacity(maxHRSource == "detected" ? 0.5 : 1)

                        if inputMode == "age" {
                            Stepper("Age: \(userAge)", value: $userAge, in: 10...100)
                                .disabled(maxHRSource == "detected")
                                .opacity(maxHRSource == "detected" ? 0.5 : 1)
                        } else {
                            Stepper("Max HR: \(manualMaxHR)", value: $manualMaxHR, in: 100...220)
                                .disabled(maxHRSource == "detected")
                                .opacity(maxHRSource == "detected" ? 0.5 : 1)
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

                    voicePickerSection
                }
                .padding(20)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showDetectionSheet) {
                detectionSheet
            }
        }
    }

    private var selectedVoiceName: String {
        let voices = AudioCoach.availableVoices()
        if let match = voices.first(where: { $0.id == selectedVoiceId }) {
            return match.name
        }
        return voices.first?.name ?? "Default"
    }

    private var voicePickerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("COACHING VOICE")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .tracking(1)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            NavigationLink {
                VoicePickerView(audioCoach: audioCoach, selectedVoiceId: $selectedVoiceId)
            } label: {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundStyle(.red)
                    Text("Voice")
                        .font(.subheadline)
                    Spacer()
                    Text(selectedVoiceName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var detectionSheet: some View {
        VStack(spacing: 28) {
            Spacer()

            if isAnalyzing {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse)

                ProgressView()
                    .scaleEffect(1.3)
                    .tint(.red)

                Text("Analyzing your heart rate history...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else if let result = analysisResult {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.red)

                VStack(spacing: 8) {
                    Text("\(result.bpm)")
                        .font(.system(size: 56, weight: .black, design: .rounded))

                    Text("BPM detected")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Based on a workout on \(Formatters.shortDateFormatter.string(from: result.date))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Button {
                    detectedMaxHR = result.bpm
                    maxHRSource = "detected"
                    showDetectionSheet = false
                } label: {
                    Text("Use This")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.red, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)

                Button {
                    showDetectionSheet = false
                } label: {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "heart.slash")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)

                Text("No heart rate data found")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Button {
                    showDetectionSheet = false
                } label: {
                    Text("OK")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray3), in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isAnalyzing)
    }
}
