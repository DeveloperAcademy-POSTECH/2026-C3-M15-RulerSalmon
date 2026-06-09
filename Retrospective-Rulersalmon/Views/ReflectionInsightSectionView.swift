//
//  ReflectionInsightSectionView.swift
//  Retrospective-Rulersalmon
//
//  Created by chaem on 6/8/26.
//

import SwiftUI

struct ReflectionInsightSectionView: View {
    let result: ReflectionInsightResult
    @Binding var selectedDays: Int
    let recordCount: Int
    let isLoading: Bool
    let errorMessage: String?
    let onRefresh: () -> Void

    private let periodOptions = [7, 30, 90]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            periodPicker
            content
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("인사이트")
                    .font(.headline)
                Text("최근 회고에서 반복되는 반성 포인트와 강점을 찾아요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.borderless)
            .disabled(isLoading || recordCount == 0)
            .accessibilityLabel("인사이트 새로고침")
        }
    }

    private var periodPicker: some View {
        Picker("분석 기간", selection: $selectedDays) {
            ForEach(periodOptions, id: \.self) { days in
                Text("\(days)일").tag(days)
            }
        }
        .pickerStyle(.segmented)
        .disabled(isLoading)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            loadingView
        } else if let errorMessage {
            messageView(
                title: errorMessage,
                systemImage: "exclamationmark.circle"
            )
        } else if recordCount == 0 {
            messageView(
                title: "저장된 회고가 생기면 인사이트를 보여드릴게요.",
                systemImage: "tray"
            )
        } else if result.reflectionPoints.isEmpty && result.strengthPoints.isEmpty {
            messageView(
                title: "아직 인사이트를 보여줄 만큼 회고가 충분하지 않아요. 같은 흐름이 3회 이상 반복되면 보여드릴게요.",
                systemImage: "sparkles"
            )
        } else {
            insightLists
        }
    }

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("회고 패턴을 분석하는 중이에요.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private var insightLists: some View {
        VStack(alignment: .leading, spacing: 14) {
            InsightPointGroup(
                title: "반성 포인트",
                emptyText: "반복되는 어려움이 아직 뚜렷하지 않아요.",
                systemImage: "exclamationmark.bubble",
                tint: .orange,
                points: result.reflectionPoints
            )

            Divider()

            InsightPointGroup(
                title: "강점 포인트",
                emptyText: "반복되는 강점이 아직 뚜렷하지 않아요.",
                systemImage: "star.bubble",
                tint: .blue,
                points: result.strengthPoints
            )
        }
    }

    private func messageView(title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

private struct InsightPointGroup: View {
    let title: String
    let emptyText: String
    let systemImage: String
    let tint: Color
    let points: [ReflectionInsightPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)

            if points.isEmpty {
                Text(emptyText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(points) { point in
                    InsightPointRow(point: point, tint: tint)
                }
            }
        }
    }
}

private struct InsightPointRow: View {
    let point: ReflectionInsightPoint
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(point.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Spacer()

                Text("\(point.count)회")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(tint.opacity(0.12), in: Capsule())
            }

            Text(point.description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ReflectionInsightSectionView(
        result: ReflectionInsightResult(
            reflectionPoints: [
                ReflectionInsightPoint(
                    title: "시간 관리",
                    description: "시간 관리 관련 회고가 반복되고 있어요. 우선순위를 먼저 정리해보면 좋아요.",
                    count: 4
                )
            ],
            strengthPoints: [
                ReflectionInsightPoint(
                    title: "피드백 수용",
                    description: "팀 피드백을 빠르게 받아들이고 시도하는 모습이 자주 보여요.",
                    count: 4
                )
            ]
        ),
        selectedDays: .constant(30),
        recordCount: 8,
        isLoading: false,
        errorMessage: nil,
        onRefresh: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
