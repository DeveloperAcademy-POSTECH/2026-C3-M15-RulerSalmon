//
//  ChatComposerView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import SwiftUI

struct ChatComposerView: View {
    @Binding var text: String
    @FocusState.Binding var isInputFocused: Bool
    let isResponding: Bool
    let onSend: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                TextField("회고를 입력해주세요.", text: $text)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit(onSend)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .glassEffect(in: Capsule())

                Button(action: onSend) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 20, weight: .regular))
                        .frame(width: 24, height: 32)
                }
                .buttonStyle(.glassProminent)
                .disabled(trimmedText.isEmpty || isResponding)
                .opacity(trimmedText.isEmpty || isResponding ? 0.5 : 1)
            }
        }
        .padding(.horizontal, AppLayout.screenHorizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(Color.white)
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ChatComposerPreviewContainer: View {
    @State private var text = "오늘 회고를 조금 더 정리해보고 싶어."
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack {
                Spacer()

                ChatComposerView(
                    text: $text,
                    isInputFocused: $isInputFocused,
                    isResponding: false,
                    onSend: { }
                )
            }
        }
    }
}

struct ChatComposerView_Previews: PreviewProvider {
    static var previews: some View {
        ChatComposerPreviewContainer()
            .previewDisplayName("Chat Composer")
    }
}
