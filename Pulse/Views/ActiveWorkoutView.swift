import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var workoutManager: WorkoutManager
    @Bindable var audioCoach: AudioCoach
    let targetZone: HeartRateZone
    let maxHR: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var hasStarted = false
    @State private var showEndConfirmation = false

    private let zones = HeartRateZone.allCases.reversed() as [HeartRateZone]

    private var minBPM: Double { Double(maxHR) * 0.50 }
    private var maxBPM: Double { Double(maxHR) * 1.00 }

    var body: some View {
        ZStack {
            if !hasStarted {
                startingView
            } else {
                workoutView
            }
        }
        .background(.black)
        .task {
            do {
                try await HealthKitManager.shared.requestAuthorization()
                audioCoach.configureAudioSession()
                try await workoutManager.startWorkout()
                audioCoach.announceWorkoutStart()
                hasStarted = true
            } catch {
                dismiss()
            }
        }
        .confirmationDialog("End Workout?", isPresented: $showEndConfirmation) {
            Button("Save & End") {
                Task { await endWorkout(save: true) }
            }
            Button("Discard", role: .destructive) {
                Task { await endWorkout(save: false) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var startingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Text("Starting workout...")
                .font(.headline)
                .padding(.top)
            Spacer()
        }
        .foregroundStyle(.white)
    }

    private var workoutView: some View {
        GeometryReader { geo in
            let topInset: CGFloat = 70
            let bottomInset: CGFloat = 100
            let zoneAreaHeight = geo.size.height - topInset - bottomInset
            let zoneHeight = zoneAreaHeight / CGFloat(zones.count)

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: topInset)

                    ForEach(zones, id: \.self) { zone in
                        let range = zone.bpmRange(maxHR: maxHR)
                        let isCurrent = zone == workoutManager.currentZone
                        let isTarget = zone == targetZone
                        ZStack {
                            Rectangle()
                                .fill(zone.color)
                                .opacity(isCurrent ? 1.0 : isTarget ? 0.8 : 0.55)

                            if isCurrent {
                                Rectangle()
                                    .fill(.white.opacity(0.08))
                            }

                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("ZONE \(zone.rawValue)")
                                        .font(.system(size: isCurrent ? 17 : 15, weight: .heavy, design: .rounded))
                                        .tracking(1)
                                    Text(zone.name.uppercased())
                                        .font(.system(size: isCurrent ? 12 : 11, weight: .medium, design: .rounded))
                                        .opacity(0.8)
                                }
                                .foregroundStyle(.white)

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(range.upperBound)")
                                        .font(.system(size: isCurrent ? 15 : 13, weight: .semibold, design: .monospaced))
                                    Text("\(range.lowerBound)")
                                        .font(.system(size: isCurrent ? 15 : 13, weight: .semibold, design: .monospaced))
                                }
                                .foregroundStyle(.white.opacity(isCurrent ? 1.0 : 0.85))
                            }
                            .padding(.horizontal, 20)
                        }
                        .overlay(alignment: .top) {
                            if isCurrent {
                                Rectangle().fill(.white.opacity(0.25)).frame(height: 1)
                            }
                        }
                        .overlay(alignment: .bottom) {
                            if isCurrent {
                                Rectangle().fill(.white.opacity(0.25)).frame(height: 1)
                            }
                        }
                        .frame(height: zoneHeight)
                        .animation(.easeInOut(duration: 0.3), value: workoutManager.currentZone)
                    }

                    Color.clear.frame(height: bottomInset)
                }

                if workoutManager.currentHR > 0 {
                    let fraction = (Double(workoutManager.currentHR) - minBPM) / (maxBPM - minBPM)
                    let clampedFraction = min(max(fraction, 0), 1)
                    let yPosition = topInset + zoneAreaHeight * (1.0 - clampedFraction)

                    Rectangle()
                        .fill(.white)
                        .frame(width: geo.size.width, height: 3)
                        .shadow(color: .white.opacity(0.9), radius: 10)
                        .shadow(color: .white.opacity(0.5), radius: 20)
                        .overlay {
                            Text("\(workoutManager.currentHR)")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 5)
                                .background(.black.opacity(0.65), in: Capsule())
                        }
                        .position(x: geo.size.width / 2, y: yPosition)
                        .animation(.spring(duration: 0.4), value: workoutManager.currentHR)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white.opacity(0.5))
                            .symbolEffect(.pulse)
                        Text("Waiting for heart rate...")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(width: geo.size.width)
                    .position(x: geo.size.width / 2, y: topInset + zoneAreaHeight / 2)
                }

                VStack {
                    HStack {
                        TimelineView(.periodic(from: .now, by: 1)) { _ in
                            Text(Formatters.duration(workoutManager.builderElapsedTime))
                                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        Button {
                            audioCoach.isEnabled.toggle()
                        } label: {
                            Image(systemName: audioCoach.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.body)
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(.white.opacity(0.15), in: Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(.black.opacity(0.55))

                    Spacer()

                    HStack(spacing: 28) {
                        Button {
                            if workoutManager.isPaused {
                                workoutManager.resumeWorkout()
                            } else {
                                workoutManager.pauseWorkout()
                            }
                        } label: {
                            Image(systemName: workoutManager.isPaused ? "play.fill" : "pause.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(.white.opacity(0.2), in: Circle())
                        }

                        if workoutManager.currentHR > 0 {
                            VStack(spacing: 0) {
                                Text("\(workoutManager.currentHR)")
                                    .font(.system(size: 40, weight: .black, design: .rounded))
                                Text("BPM")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .opacity(0.7)
                            }
                            .foregroundStyle(.white)
                            .frame(width: 110)
                        }

                        Button {
                            showEndConfirmation = true
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(.red.opacity(0.8), in: Circle())
                        }
                    }
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.55))
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .ignoresSafeArea()
        .onChange(of: workoutManager.currentHR) { _, newValue in
            if newValue > 0 {
                audioCoach.processHeartRate(newValue, maxHR: maxHR)
            }
        }
    }

    private func endWorkout(save: Bool) async {
        do {
            audioCoach.announceWorkoutEnd()
            let result = try await workoutManager.endWorkout()
            if save {
                saveWorkout(samples: result.samples, duration: result.duration, startDate: result.startDate)
            }
            audioCoach.deactivateAudioSession()
            audioCoach.reset()
            dismiss()
        } catch {
            dismiss()
        }
    }

    private func saveWorkout(samples: [(Date, Int)], duration: TimeInterval, startDate: Date) {
        guard !samples.isEmpty else { return }

        let bpms = samples.map(\.1)
        let avgHR = bpms.reduce(0, +) / bpms.count
        let maxBPM = bpms.max() ?? 0
        let minBPM = bpms.min() ?? 0

        var zoneTime: [HeartRateZone: TimeInterval] = [:]
        for i in 0..<samples.count {
            let bpm = samples[i].1
            let interval: TimeInterval
            if i + 1 < samples.count {
                interval = samples[i + 1].0.timeIntervalSince(samples[i].0)
            } else {
                interval = 1
            }
            if let zone = HeartRateZone.zone(for: bpm, maxHR: maxHR) {
                zoneTime[zone, default: 0] += interval
            }
        }

        let record = WorkoutRecord(
            startDate: startDate,
            endDate: Date(),
            duration: duration,
            averageHR: avgHR,
            maxHR: maxBPM,
            minHR: minBPM,
            targetZone: targetZone.rawValue,
            userMaxHR: maxHR,
            timeInZone1: zoneTime[.zone1, default: 0],
            timeInZone2: zoneTime[.zone2, default: 0],
            timeInZone3: zoneTime[.zone3, default: 0],
            timeInZone4: zoneTime[.zone4, default: 0],
            timeInZone5: zoneTime[.zone5, default: 0]
        )

        let hrSamples = samples.map { HRSample(timestamp: $0.0, bpm: $0.1) }
        record.samples = hrSamples

        modelContext.insert(record)
        try? modelContext.save()
    }
}
