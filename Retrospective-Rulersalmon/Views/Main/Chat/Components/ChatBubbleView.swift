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
