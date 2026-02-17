import SwiftUI

struct VoicePickerView: View {
    var audioCoach: AudioCoach
    @Binding var selectedVoiceId: String

    private var grouped: [(tier: Int, name: String, voices: [VoiceInfo])] {
        let voices = AudioCoach.availableVoices()
        let dict = Dictionary(grouping: voices) { $0.qualityRank }
        return dict.keys.sorted(by: >).map { tier in
            let items = dict[tier] ?? []
            return (tier: tier, name: items.first?.quality ?? "", voices: items)
        }
    }

    var body: some View {
        List {
            ForEach(grouped, id: \.tier) { group in
                Section(group.name) {
                    ForEach(group.voices) { voice in
                        Button {
                            audioCoach.setVoice(identifier: voice.id)
                            selectedVoiceId = voice.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(voice.name)
                                        .font(.body)
                                    Text(voice.language)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedVoiceId == voice.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.red)
                                        .fontWeight(.bold)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Coaching Voice")
        .navigationBarTitleDisplayMode(.inline)
    }
}
