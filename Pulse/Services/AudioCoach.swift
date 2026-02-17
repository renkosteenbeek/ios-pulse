import AVFoundation

struct VoiceInfo: Identifiable {
    let id: String
    let name: String
    let quality: String
    let language: String
    let qualityRank: Int
}

@Observable
final class AudioCoach: @unchecked Sendable {
    var isEnabled: Bool = true
    var targetZone: HeartRateZone = .zone2

    private let synthesizer = AVSpeechSynthesizer()
    private(set) var preferredVoice: AVSpeechSynthesisVoice?
    private var lastSpokenTime: Date = .distantPast
    private var lastSpokenMessage: String = ""
    private var outOfZoneSince: Date?
    private var wasInTargetZone: Bool = true

    var selectedVoiceId: String {
        get { UserDefaults.standard.string(forKey: "selectedVoiceId") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "selectedVoiceId") }
    }

    private let inZoneMessages = [
        "{bpm}. Looking good.",
        "Holding steady. {bpm}.",
        "Right on track.",
        "{bpm}, nice pace.",
        "Zone {zone}, {bpm}.",
    ]

    private let tooHighMessages = [
        "A bit high. {bpm}.",
        "{bpm}, ease off slightly.",
        "Drifting up, {bpm}.",
    ]

    private let tooLowMessages = [
        "Dropping a little. {bpm}.",
        "{bpm}, push a touch.",
        "Creeping low, {bpm}.",
    ]

    private let farTooHighMessages = [
        "Zone {zone} now. Get back to zone {target}.",
        "{bpm}, way too high. Slow down.",
    ]

    private let farTooLowMessages = [
        "Zone {zone} now. Get back to zone {target}.",
        "{bpm}, way too low. Push harder.",
    ]

    private let returnMessages = [
        "That's it, back in zone.",
        "Nice, zone {zone} again.",
        "Back on track. {bpm}.",
        "There we go.",
    ]

    init() {
        selectBestVoice()
    }

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
                let msg = pickMessage(from: returnMessages, bpm: bpm, zone: targetZone.rawValue, target: targetZone.rawValue)
                speak(msg)
                lastSpokenTime = now
                outOfZoneSince = nil
            } else if now.timeIntervalSince(lastSpokenTime) >= 45 {
                let msg = pickMessage(from: inZoneMessages, bpm: bpm, zone: targetZone.rawValue, target: targetZone.rawValue)
                speak(msg)
                lastSpokenTime = now
            }
            wasInTargetZone = true
        } else {
            if wasInTargetZone {
                outOfZoneSince = now
                wasInTargetZone = false
            }

            guard let current = currentZone else { return }
            let zoneDiff = abs(current.rawValue - targetZone.rawValue)
            let tooHigh = current.rawValue > targetZone.rawValue
            let timeOutOfZone = now.timeIntervalSince(outOfZoneSince ?? now)

            if zoneDiff >= 2 {
                if timeOutOfZone >= 10 && now.timeIntervalSince(lastSpokenTime) >= 15 {
                    let pool = tooHigh ? farTooHighMessages : farTooLowMessages
                    let msg = pickMessage(from: pool, bpm: bpm, zone: current.rawValue, target: targetZone.rawValue)
                    speak(msg)
                    lastSpokenTime = now
                }
            } else {
                if timeOutOfZone >= 20 && now.timeIntervalSince(lastSpokenTime) >= 25 {
                    let pool = tooHigh ? tooHighMessages : tooLowMessages
                    let msg = pickMessage(from: pool, bpm: bpm, zone: current.rawValue, target: targetZone.rawValue)
                    speak(msg)
                    lastSpokenTime = now
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
        lastSpokenTime = .distantPast
        lastSpokenMessage = ""
        outOfZoneSince = nil
        wasInTargetZone = true
    }

    static func availableVoices() -> [VoiceInfo] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
            .map { voice in
                let qualityLabel: String
                let rank: Int
                switch voice.quality {
                case .premium:
                    qualityLabel = "Premium"
                    rank = 3
                case .enhanced:
                    qualityLabel = "Enhanced"
                    rank = 2
                default:
                    qualityLabel = "Default"
                    rank = 1
                }
                return VoiceInfo(
                    id: voice.identifier,
                    name: voice.name,
                    quality: qualityLabel,
                    language: voice.language,
                    qualityRank: rank
                )
            }
    }

    func setVoice(identifier: String) {
        selectedVoiceId = identifier
        preferredVoice = AVSpeechSynthesisVoice(identifier: identifier)
        previewVoice()
    }

    func previewVoice() {
        speak("Heart rate 142, zone 2.")
    }

    func reloadVoice() {
        selectBestVoice()
    }

    private func selectBestVoice() {
        let stored = selectedVoiceId
        if !stored.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: stored) {
            preferredVoice = voice
            return
        }
        let english = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
        preferredVoice = english.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    private func pickMessage(from pool: [String], bpm: Int, zone: Int, target: Int) -> String {
        let formatted = pool.map {
            $0.replacingOccurrences(of: "{bpm}", with: "\(bpm)")
              .replacingOccurrences(of: "{zone}", with: "\(zone)")
              .replacingOccurrences(of: "{target}", with: "\(target)")
        }

        let candidates = formatted.filter { $0 != lastSpokenMessage }
        let chosen = candidates.randomElement() ?? formatted.randomElement() ?? "\(bpm)"
        lastSpokenMessage = chosen
        return chosen
    }

    private func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredVoice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }
}
