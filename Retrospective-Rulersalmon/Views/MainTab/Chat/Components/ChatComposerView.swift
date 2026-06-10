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
    let bubbleShadowColor: Color
    let onSend: () -> Void
    let onFinish: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            TextField("회고를 입력해주세요.", text: $text)
                .focused($isInputFocused)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.gray900)
                .padding(.horizontal, 20)
                .frame(height: 40)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 100, style: .continuous))
                .shadow(color: bubbleShadowColor, radius: 28, x: 0, y: 10)

            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 40, height: 40)
                    .background(Color.blue500)
                    .clipShape(Circle())
            }
            .disabled(trimmedText.isEmpty || isResponding)
            .opacity(trimmedText.isEmpty || isResponding ? 0.5 : 1)
            .shadow(color: bubbleShadowColor, radius: 28, x: 0, y: 10)

            Button(action: onFinish) {
                Image(systemName: "power")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.gray900)
                    .frame(width: 48, height: 48)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.gray200, lineWidth: 1)
                    }
            }
            .disabled(isResponding)
            .opacity(isResponding ? 0.5 : 1)
            .shadow(color: bubbleShadowColor, radius: 28, x: 0, y: 10)
            .overlay(alignment: .topTrailing) {
                Text("회고 종료하기")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.gray900)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.96))
                    .clipShape(Capsule())
                    .shadow(color: bubbleShadowColor, radius: 18, x: 0, y: 8)
                    .offset(x: 2, y: -48)
            }
        }
        .padding(.horizontal, AppLayout.screenHorizontalPadding)
        .padding(.top, 14)
        .padding(.bottom, 22)
        .background(Color.gray50)
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
            Color.gray50
                .ignoresSafeArea()

            VStack {
                Spacer()

                ChatComposerView(
                    text: $text,
                    isInputFocused: $isInputFocused,
                    isResponding: false,
                    bubbleShadowColor: Color.black.opacity(0.08),
                    onSend: { },
                    onFinish: { }
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
