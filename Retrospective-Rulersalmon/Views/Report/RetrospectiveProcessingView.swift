//
//  RetrospectiveProcessingView.swift
//  Retrospective-Rulersalmon
//
//  Created by Steve on 6/8/26.
//

import SwiftUI

struct RetrospectiveProcessingView: View {
    @Binding private var progress: Double
    @State private var displayedProgress: Double = 0

    let mentorName: String

    init(progress: Binding<Double> = .constant(0.96), mentorName: String = "하워드") {
        _progress = progress
        self.mentorName = mentorName
    }

    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            VStack(spacing: 32) {
                Spacer()

                ProcessingProgressRing(progress: displayedProgress)

                VStack(spacing: 14) {
                    Text("회고를 정리하고\n있어요")
                        .font(.system(size: 27, weight: .bold))
                        .foregroundStyle(Color.gray900)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("\(mentorName)가 회고 카드와\n인사이트를 정리하고 있어요.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.gray600)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, ProcessingLayout.screenPadding)
        }
        .onAppear {
            updateDisplayedProgress(animated: true)
        }
        .onChange(of: progress) {
            updateDisplayedProgress(animated: true)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func updateDisplayedProgress(animated: Bool) {
        let targetProgress = clamped(progress)
        guard displayedProgress != targetProgress else { return }

        if animated {
            withAnimation(.easeOut(duration: 0.75)) {
                displayedProgress = targetProgress
            }
        } else {
            displayedProgress = targetProgress
        }
    }

    private func clamped(_ progress: Double) -> Double {
        min(max(progress, 0), 1)
    }
}

private enum ProcessingLayout {
    static let screenPadding: CGFloat = 16
    static let ringSize: CGFloat = 136
    static let ringLineWidth: CGFloat = 18
}

private struct ProcessingProgressRing: View {
    let progress: Double

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: ProcessingLayout.ringLineWidth)
                .shadow(color: Color.blue500.opacity(0.12), radius: 24, x: 0, y: 16)

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    Color.blue50,
                    style: StrokeStyle(
                        lineWidth: ProcessingLayout.ringLineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            AnimatedPercentageText(progress: clampedProgress)
        }
        .frame(width: ProcessingLayout.ringSize, height: ProcessingLayout.ringSize)
    }
}

private struct AnimatedPercentageText: View, Animatable {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private var percentage: Int {
        Int(round(min(max(progress, 0), 1) * 100))
    }

    var body: some View {
        Text("\(percentage)%")
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(Color.blue500)
    }
}

struct RetrospectiveProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RetrospectiveProcessingView()
        }
    }
}
