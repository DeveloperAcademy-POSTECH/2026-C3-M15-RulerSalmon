//
//  ChatComposerView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import SwiftUI

struct ChatComposerView: View {
    @Binding var text: String
    let isResponding: Bool
    let bubbleShadowColor: Color
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            TextField("회고를 입력해주세요.", text: $text)
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
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 22)
        .background(Color.gray50)
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
