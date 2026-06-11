//
//  ChatBubbleView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    let bubbleShadowColor: Color

    var body: some View {
        Group {
            if message.role == .assistant {
                HStack {
                    bubble
                        .frame(maxWidth: 320, alignment: .leading)
                    Spacer(minLength: 0)
                }
            } else {
                HStack {
                    Spacer(minLength: 0)
                    bubble
                        .frame(maxWidth: 320, alignment: .trailing)
                }
            }
        }
    }

    private var bubble: some View {
        Text(message.text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(message.role == .assistant ? Color.blue500 : Color.gray900)
            .lineSpacing(2)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(message.role == .assistant ? Color(red: 0.86, green: 0.91, blue: 0.98) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: bubbleShadowColor, radius: 28, x: 0, y: 10)
            .frame(minWidth: 12, alignment: .leading)
    }
}

struct ChatBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ChatBubbleView(
                    message: ChatMessage(role: .assistant, text: "좋아, 오늘 회고를 같이 정리해보자. 먼저 어떤 장면이 가장 떠오르는지 말해줘."),
                    bubbleShadowColor: Color.black.opacity(0.08)
                )

                ChatBubbleView(
                    message: ChatMessage(role: .user, text: "오늘은 RAG 구조를 정리하면서 원하는 방향이 조금 더 선명해졌어."),
                    bubbleShadowColor: Color.black.opacity(0.08)
                )
            }
            .padding(24)
        }
        .previewDisplayName("Chat Bubble")
    }
}
