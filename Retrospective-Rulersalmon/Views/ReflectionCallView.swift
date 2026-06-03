//
//  ReflectionCallView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import SwiftUI

struct ReflectionCallView: View {
    @StateObject private var viewModel = ReflectionCallViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroSection

                controlSection

                transcriptSection

                reflectionStateSection

                messageSection

                chunkSection
            }
            .padding()
        }
        .navigationTitle("Reflection Lab")
        .alert("안내", isPresented: Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } }
        )) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("회고 통화형 AI")
                .font(.largeTitle.bold())

            Text("STT로 들어온 말을 4L 기준으로 누적하고, 부족한 부분이 보이면 짧게 질문합니다.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.indigo.opacity(0.24),
                    Color.teal.opacity(0.18),
                    Color.cyan.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    viewModel.toggleRecording()
                } label: {
                    Label(viewModel.isRecording ? "중지" : "시작", systemImage: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    viewModel.sendManualText()
                } label: {
                    Label("반영", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            TextField("직접 회고를 입력해도 됩니다", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            if let question = viewModel.activeQuestion {
                questionSection(question)
            }

            HStack {
                statusPill(title: viewModel.isRecording ? "Listening" : "Idle", color: viewModel.isRecording ? .green : .gray)
                statusPill(title: "Chunks \(viewModel.chunks.count)", color: .blue)
                statusPill(title: "Questions \(viewModel.reflectionState.askedQuestions.count)", color: .purple)
            }
        }
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Live Transcript")

            Text(viewModel.liveTranscript.isEmpty ? "대기 중..." : viewModel.liveTranscript)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func questionSection(_ question: String) -> some View {
        Text(question)
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
    }

    private var reflectionStateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("4L State")

            VStack(spacing: 12) {
                reflectionCard(
                    title: ReflectionDimension.liked.description,
                    confidence: viewModel.likedProgressText,
                    fidelity: viewModel.likedFidelityText,
                    slot: viewModel.reflectionState.liked
                )
                reflectionCard(
                    title: ReflectionDimension.learned.description,
                    confidence: viewModel.learnedProgressText,
                    fidelity: viewModel.learnedFidelityText,
                    slot: viewModel.reflectionState.learned
                )
                reflectionCard(
                    title: ReflectionDimension.lacked.description,
                    confidence: viewModel.lackedProgressText,
                    fidelity: viewModel.lackedFidelityText,
                    slot: viewModel.reflectionState.lacked
                )
                reflectionCard(
                    title: ReflectionDimension.longedFor.description,
                    confidence: viewModel.longedForProgressText,
                    fidelity: viewModel.longedForFidelityText,
                    slot: viewModel.reflectionState.longedFor
                )
            }
        }
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Conversation")

            VStack(spacing: 10) {
                ForEach(viewModel.messages) { message in
                    ChatBubbleView(message: message)
                }
            }
        }
    }

    private var chunkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Chunks")

            VStack(spacing: 10) {
                ForEach(Array(viewModel.analyses.enumerated()), id: \.offset) { index, analysis in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Chunk \(index + 1)")
                                .font(.headline)
                            Spacer()
                            Text("\(Int((analysis.confidence * 100).rounded()))%")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        Text(analysis.cleanedText)
                            .font(.subheadline)

                        Text(analysis.summary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
    }

    private func statusPill(title: String, color: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func reflectionCard(title: String, confidence: String, fidelity: String, slot: ReflectionSlot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                HStack(spacing: 8) {
                    metricPill(title: "Confidence", value: confidence)
                    metricPill(title: "Fidelity", value: fidelity)
                }
            }

            ProgressView(value: slot.confidence)
            ProgressView(value: slot.fidelity)

            Text(slot.summary ?? "아직 누적된 요약이 없습니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !slot.evidence.isEmpty {
                Text(slot.evidence.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func metricPill(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
            Text(value)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 48)
            } else {
                Spacer(minLength: 48)
                bubble
            }
        }
    }

    private var bubble: some View {
        Text(message.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundColor(message.role == .assistant ? .primary : .white)
            .background(message.role == .assistant ? Color(.secondarySystemBackground) : Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
