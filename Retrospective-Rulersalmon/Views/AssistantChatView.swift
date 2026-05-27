//
//  AssistantChatView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/21/26.
//

import SwiftUI

struct AssistantChatView: View {
    @StateObject private var viewModel = AssistantChatViewModel()

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        ChatBubbleView(message: message)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical)
            }

            VStack(spacing: 12) {
                TextField("메시지를 입력하세요", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                HStack(spacing: 12) {
                    Button {
                        viewModel.toggleRecording()
                    } label: {
                        Label(viewModel.isRecording ? "중지" : "STT", systemImage: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        viewModel.sendCurrentText()
                    } label: {
                        Label("전송", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isResponding)
                }
            }
            .padding(.bottom)
        }
        .padding()
        .navigationTitle("Assistant Demo")
        .alert("안내", isPresented: Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } }
        )) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
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
