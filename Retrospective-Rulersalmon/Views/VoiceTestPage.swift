import SwiftUI

struct VoiceTestPage: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var coach = VoiceCoachViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            voicePicker
            textInput
            playbackControls
            latencyPanel
            Text(coach.voiceSampleStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(20)
        .navigationTitle("TTS Voice Test")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StatusPill(text: coach.statusText, isBusy: coach.isSpeaking)
            }
        }
        .task {
            coach.setAppActive(scenePhase == .active)
            coach.prepare()
        }
        .onChange(of: scenePhase) { _, newPhase in
            coach.setAppActive(newPhase == .active)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("목소리 선택")
                .font(.headline)
            Text("chaem, cindy, friday 중 하나를 선택하고 입력한 텍스트를 해당 목소리로 읽습니다.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var voicePicker: some View {
        Picker("목소리", selection: Binding(
            get: { coach.selectedSlot },
            set: { coach.selectSlot($0) }
        )) {
            ForEach(VoiceSlot.allCases) { slot in
                Text(slot.title).tag(slot)
            }
        }
        .pickerStyle(.segmented)
        .disabled(coach.isSpeaking)
    }

    private var textInput: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("읽을 텍스트를 입력해 주세요", text: $coach.ttsText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(4...8)
                .submitLabel(.send)
                .disabled(coach.isSpeaking)
                .onSubmit {
                    Task { await coach.speakInputText() }
                }

            Text("측정 입력 길이: \(coach.effectiveInputCharacterCount)자")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var playbackControls: some View {
        HStack(spacing: 12) {
            Button {
                Task { await coach.speakInputText() }
            } label: {
                Label("읽기", systemImage: "speaker.wave.2.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(coach.isSpeaking || coach.ttsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button {
                coach.stopSpeaking()
            } label: {
                Image(systemName: "speaker.slash.fill")
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
        }
    }

    private var latencyPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Latency")
                .font(.headline)

            if coach.latencyMetrics.isEmpty {
                Text("아직 측정값 없음")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(coach.latencyMetrics) { metric in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(metric.voiceName) · \(metric.characterCount)자")
                            .font(.caption.weight(.semibold))
                        HStack(spacing: 12) {
                            Text("합성 \(formatSeconds(metric.synthesisTime))")
                            Text("첫 재생 \(formatSeconds(metric.firstPlaybackTime))")
                            Text("완료 \(formatSeconds(metric.totalTime))")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func formatSeconds(_ value: TimeInterval) -> String {
        String(format: "%.2fs", value)
    }
}

private struct StatusPill: View {
    let text: String
    let isBusy: Bool

    var body: some View {
        HStack(spacing: 6) {
            if isBusy {
                ProgressView()
                    .controlSize(.small)
            }
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: Capsule())
    }
}

#Preview {
    NavigationStack {
        VoiceTestPage()
    }
}
