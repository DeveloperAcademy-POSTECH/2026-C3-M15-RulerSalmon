//
//  ProcessingBubbleView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import SwiftUI

struct ProcessingBubbleView: View {
    let bubbleShadowColor: Color
    @State private var isBlinking = false

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.blue500)
                    .frame(width: 4, height: 4)
                    .opacity(isBlinking ? 0.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isBlinking)

                Text("질문을 생성하는 중")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.gray600)
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .shadow(color: bubbleShadowColor, radius: 16, x: 0, y: 10)

            Spacer(minLength: 0)
        }
        .onAppear {
            isBlinking = true
        }
    }
}
