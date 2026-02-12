import AVFoundation

@Observable
final class AudioCoach {
    var isEnabled: Bool = true
    var targetZone: HeartRateZone = .zone2

    private let synthesizer = AVSpeechSynthesizer()
    private var lastAlertTime: Date = .distantPast
    private var lastPeriodicTime: Date = .distantPast
    private var wasInTargetZone: Bool = true

    func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .voicePrompt,
            options: [.duckOthers]
        )
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func processHeartRate(_ bpm: Int, maxHR: Int) {
        guard isEnabled else { return }

        let currentZone = HeartRateZone.zone(for: bpm, maxHR: maxHR)
        let isInTarget = currentZone == targetZone
        let now = Date()

        if isInTarget {
            if !wasInTargetZone {
                speak("Back in zone.")
                wasInTargetZone = true
                lastPeriodicTime = now
            } else if now.timeIntervalSince(lastPeriodicTime) >= 30 {
                speak("\(bpm) bpm.")
                lastPeriodicTime = now
            }
            lastAlertTime = .distantPast
        } else {
            wasInTargetZone = false

            if let current = currentZone {
                let tooHigh = current.rawValue > targetZone.rawValue

                if lastAlertTime == .distantPast || now.timeIntervalSince(lastAlertTime) >= 5 {
                    if now.timeIntervalSince(lastAlertTime) >= 15 || lastAlertTime == .distantPast {
                        if tooHigh {
                            speak("Heart rate too high. Slow down.")
                        } else {
                            speak("Heart rate too low. Pick it up.")
                        }
                    } else if now.timeIntervalSince(lastAlertTime) >= 5 {
                        if tooHigh {
                            speak("Still too high, \(bpm) bpm.")
                        } else {
                            speak("Still too low, \(bpm) bpm.")
                        }
                    }
                    lastAlertTime = now
                }
            }
        }
    }

    func announceWorkoutStart() {
        guard isEnabled else { return }
        speak("Workout started. Target zone \(targetZone.rawValue), \(targetZone.name).")
    }

    func announceWorkoutEnd() {
        guard isEnabled else { return }
        speak("Workout ended.")
    }

    func reset() {
        lastAlertTime = .distantPast
        lastPeriodicTime = .distantPast
        wasInTargetZone = true
    }

    private func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.1
        synthesizer.speak(utterance)
    }
}
