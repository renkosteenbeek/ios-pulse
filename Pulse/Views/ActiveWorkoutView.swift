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
    @State private var showCooldown = false
    @State private var savedWorkoutPeakHR: Int = 0
    @State private var audioTimer: Timer?

    private let zones = HeartRateZone.allCases.reversed() as [HeartRateZone]

    private var minBPM: Double { Double(maxHR) * 0.50 }
    private var maxBPM: Double { Double(maxHR) * 1.00 }

    var body: some View {
        ZStack {
            if showCooldown {
                CooldownView(
                    workoutManager: workoutManager,
                    peakHR: savedWorkoutPeakHR
                ) {
                    cleanupAndDismiss()
                }
            } else if !hasStarted {
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
                startAudioTimer()
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
        VStack(spacing: 0) {
            topBar

            GeometryReader { geo in
                let weights = zoneWeights()
                let totalWeight = weights.reduce(0, +)
                let totalHeight = geo.size.height

                ZStack {
                    VStack(spacing: 0) {
                        ForEach(Array(zones.enumerated()), id: \.element) { index, zone in
                            let range = zone.bpmRange(maxHR: maxHR)
                            let isCurrent = zone == workoutManager.currentZone
                            let distance = workoutManager.currentZone.map { abs(zone.rawValue - $0.rawValue) } ?? 0
                            let height = totalHeight * (weights[index] / totalWeight)
                            let zoneOpacity = isCurrent ? 1.0 : max(0.85 - Double(distance) * 0.15, 0.35)

                            ZStack {
                                Rectangle()
                                    .fill(zone.color)
                                    .opacity(zoneOpacity)

                                if isCurrent {
                                    Rectangle()
                                        .fill(.white.opacity(0.08))
                                }

                                LinearGradient(
                                    colors: [.black.opacity(0.15), .clear, .black.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )

                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: isCurrent ? 4 : 2) {
                                        Text("ZONE \(zone.rawValue)")
                                            .font(.system(size: isCurrent ? 22 : 14, weight: .heavy, design: .rounded))
                                            .tracking(1)
                                        Text(zone.name.uppercased())
                                            .font(.system(size: isCurrent ? 13 : 10, weight: .medium, design: .rounded))
                                            .opacity(0.8)
                                    }
                                    .foregroundStyle(.white)

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(range.upperBound)")
                                            .font(.system(size: isCurrent ? 17 : 12, weight: .semibold, design: .monospaced))
                                        Text("\(range.lowerBound)")
                                            .font(.system(size: isCurrent ? 17 : 12, weight: .semibold, design: .monospaced))
                                    }
                                    .foregroundStyle(.white.opacity(isCurrent ? 1.0 : 0.7))
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
                            .frame(height: height)
                        }
                    }
                    .animation(.spring(duration: 0.5), value: workoutManager.currentZone)

                    if workoutManager.currentHR > 0 {
                        let fraction = (Double(workoutManager.currentHR) - minBPM) / (maxBPM - minBPM)
                        let clampedFraction = min(max(fraction, 0), 1)
                        let yPosition = totalHeight * (1.0 - clampedFraction)

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
                    }
                }
            }

            bottomBar
        }
        .background(.black)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private func zoneWeights() -> [Double] {
        guard let currentZone = workoutManager.currentZone else {
            return zones.map { _ in 1.0 }
        }

        return zones.map { zone in
            let distance = abs(zone.rawValue - currentZone.rawValue)
            return max(3.5 - Double(distance) * 0.8, 0.5)
        }
    }

    private var topBar: some View {
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
    }

    private var bottomBar: some View {
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

    private func startAudioTimer() {
        let wm = workoutManager
        let ac = audioCoach
        let mhr = maxHR
        audioTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            MainActor.assumeIsolated {
                let hr = wm.currentHR
                if hr > 0 {
                    ac.processHeartRate(hr, maxHR: mhr)
                }
            }
        }
    }

    private func stopAudioTimer() {
        audioTimer?.invalidate()
        audioTimer = nil
    }

    private func endWorkout(save: Bool) async {
        stopAudioTimer()
        do {
            audioCoach.announceWorkoutEnd()
            let result = try await workoutManager.endWorkout()
            if save {
                let peakHR = result.samples.map(\.1).max() ?? 0
                saveWorkout(samples: result.samples, duration: result.duration, startDate: result.startDate, distance: result.distance)
                savedWorkoutPeakHR = peakHR
                audioCoach.deactivateAudioSession()
                audioCoach.reset()
                showCooldown = true
            } else {
                audioCoach.deactivateAudioSession()
                audioCoach.reset()
                dismiss()
            }
        } catch {
            dismiss()
        }
    }

    private func cleanupAndDismiss() {
        UIApplication.shared.isIdleTimerDisabled = false
        dismiss()
    }

    private func saveWorkout(samples: [(Date, Int)], duration: TimeInterval, startDate: Date, distance: Double?) {
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

        let totalDistance = distance ?? 0
        let avgPace = (totalDistance > 0 && duration > 0) ? (duration / (totalDistance / 1000)) : 0

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
            timeInZone5: zoneTime[.zone5, default: 0],
            totalDistance: totalDistance,
            averagePace: avgPace
        )

        let hrSamples = samples.map { HRSample(timestamp: $0.0, bpm: $0.1) }
        record.samples = hrSamples

        modelContext.insert(record)
        try? modelContext.save()
    }
}
