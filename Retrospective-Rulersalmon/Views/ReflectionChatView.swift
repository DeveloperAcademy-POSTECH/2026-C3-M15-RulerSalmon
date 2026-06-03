//
//  ReflectionChatView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/2/26.
//

import SwiftUI

struct ReflectionChatView: View {
    @StateObject private var viewModel = ReflectionChatViewModel()

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    messageSection
                    reflectionStateSection
                }
                .padding()
            }

            composerSection
        }
        .navigationTitle("Reflection Chat")
        .navigationBarTitleDisplayMode(.inline)
        .alert("안내", isPresented: Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } }
        )) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("텍스트 회고 채팅")
                .font(.largeTitle.bold())

            Text("입력한 회고를 4L 기준으로 분석하고, 맥락에 맞는 다음 질문을 이어갈게.")
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
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Conversation")

            VStack(spacing: 10) {
                ForEach(viewModel.messages) { message in
                    ChatBubbleView(message: message)
                }

                if viewModel.isResponding {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("다음 질문을 정리하고 있어")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
        }
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

    private var composerSection: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(alignment: .bottom, spacing: 12) {
                TextField("이번 경험을 편하게 적어줘", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...6)

                Button(action: viewModel.sendMessage) {
                    Label("전송", systemImage: "paperplane.fill")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isResponding)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(.ultraThinMaterial)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
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

            Text(slot.summary ?? "아직 누적된 요약이 없어.")
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
