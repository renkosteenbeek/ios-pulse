import SwiftUI

struct HomeView: View {
    @State private var selectedZone: HeartRateZone = .zone2
    @State private var audioEnabled = true
    @State private var showWorkout = false
    @State private var workoutManager = WorkoutManager()
    @State private var audioCoach = AudioCoach()
    private var profile = UserProfile()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemGray6), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(selectedZone.color)
                    .shadow(color: selectedZone.color.opacity(0.6), radius: 20)
                    .symbolEffect(.pulse)

                VStack(spacing: 16) {
                    Text("TARGET ZONE")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .tracking(2)

                    HStack(spacing: 8) {
                        ForEach(HeartRateZone.allCases, id: \.self) { zone in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedZone = zone
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(zone.rawValue)")
                                        .font(.title3.bold())
                                    Text(zone.name)
                                        .font(.system(size: 9))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    selectedZone == zone
                                        ? AnyShapeStyle(zone.color)
                                        : AnyShapeStyle(.clear)
                                )
                                .foregroundStyle(selectedZone == zone ? .white : .secondary)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            selectedZone == zone ? zone.color : Color.secondary.opacity(0.3),
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)

                    let range = selectedZone.bpmRange(maxHR: profile.maxHeartRate)
                    VStack(spacing: 4) {
                        Text(selectedZone.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(selectedZone.color)
                        Text("\(range.lowerBound)–\(range.upperBound) BPM")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                }

                HStack {
                    Image(systemName: audioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .foregroundStyle(audioEnabled ? .primary : .secondary)
                        .frame(width: 28)
                    Text("Audio Coaching")
                    Spacer()
                    Toggle("", isOn: $audioEnabled)
                        .labelsHidden()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)

                Spacer()

                Button {
                    workoutManager.maxHR = profile.maxHeartRate
                    audioCoach.reloadVoice()
                    audioCoach.targetZone = selectedZone
                    audioCoach.isEnabled = audioEnabled
                    showWorkout = true
                } label: {
                    Text("Start Workout")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(selectedZone.color, in: RoundedRectangle(cornerRadius: 20))
                        .shadow(color: selectedZone.color.opacity(0.4), radius: 12, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .fullScreenCover(isPresented: $showWorkout) {
            ActiveWorkoutView(
                workoutManager: workoutManager,
                audioCoach: audioCoach,
                targetZone: selectedZone,
                maxHR: profile.maxHeartRate
            )
        }
    }
}
