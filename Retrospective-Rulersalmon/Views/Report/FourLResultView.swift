//
//  FourLResultView.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/3/26.
//

import SwiftUI

struct FourLResultView: View {
    @StateObject private var viewModel: FourLResultViewModel
    @State private var selectedMode = ResultMode.topTwo

    init(messages: [ChatMessage]) {
        _viewModel = StateObject(wrappedValue: FourLResultViewModel(messages: messages))
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("결과 보기", selection: $selectedMode) {
                ForEach(ResultMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            .padding(.horizontal)

            if viewModel.isRefining {
                ProgressView("문장을 정돈하는 중...")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if viewModel.isGeneratingSummary {
                ProgressView("요약과 Action Item을 만드는 중...")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView("4L 분류 실패", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
            } else {
                List {
                    switch selectedMode {
                    case .topTwo:
                        topTwoContent
                    case .all:
                        allContent
                    case .summary:
                        summaryContent
                    }
                }
            }
        }
        .navigationTitle("4L 분류 결과")
        .task {
            viewModel.generateResults()
        }
    }

    private var topTwoContent: some View {
        ForEach(FourLService.fourLLabels, id: \.self) { label in
            Section {
                let items = topResultsByFourL[label] ?? []

                if items.isEmpty {
                    Text("선택된 문장이 없습니다.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items) { result in
                        ResultRow(result: result, refinedText: viewModel.refinedTexts[result.id])
                    }
                }
            } header: {
                Text(label)
            }
        }
    }

    private var allContent: some View {
        ForEach(FourLService.fourLLabels + [FourLService.extraLabel], id: \.self) { label in
            Section {
                let items = viewModel.results.filter { $0.label == label }

                if items.isEmpty {
                    Text("분류된 문장이 없습니다.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items) { result in
                        ResultRow(result: result, refinedText: viewModel.refinedTexts[result.id])
                    }
                }
            } header: {
                Text(label)
            }
        }
    }

    private var summaryContent: some View {
        Group {
            Section {
                if let summaryResult = viewModel.summaryResult, !summaryResult.todaySummary.isEmpty {
                    Text(summaryResult.todaySummary)
                } else {
                    Text("요약 생성 대기 중")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("오늘의 요약")
            }

            Section {
                actionItemsView(viewModel.summaryResult?.actionItems ?? [])
            } header: {
                Text("내일 Action Item")
            }
        }
    }

    private func actionItemsView(_ items: [String]) -> some View {
        Group {
            if items.isEmpty {
                Text("생성된 Action Item이 없습니다.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .foregroundStyle(.secondary)
                        Text(item)
                    }
                }
            }
        }
    }

    private var topResultsByFourL: [String: [FourLClassificationResult]] {
        viewModel.topResultsByFourL()
    }
}

private enum ResultMode: String, CaseIterable, Identifiable {
    case topTwo
    case all
    case summary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .topTwo:
            return "Top 2"
        case .all:
            return "전체"
        case .summary:
            return "요약"
        }
    }
}

private struct ResultRow: View {
    let result: FourLClassificationResult
    let refinedText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("원본")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(result.text)
                    .font(.body)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("정제")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if let refinedText {
                    Text(refinedText)
                        .font(.body)
                } else if result.isFourLRelated {
                    Text("정제 대기 중")
                        .font(.body)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Extra 문장은 정제하지 않습니다.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                Text(result.label)
                    .font(.caption.weight(.semibold))
                Text(percentText(result.confidence))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("4L 합계 \(percentText(result.fourLConfidence))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let secondaryLabel = result.secondaryLabel,
               let secondaryConfidence = result.secondaryConfidence {
                Text("보조 후보: \(secondaryLabel) \(percentText(secondaryConfidence))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func percentText(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(1)))
    }
}

#Preview {
    NavigationStack {
        FourLResultView(messages: [
            ChatMessage(role: .user, text: "오늘 회의에서 사용자 피드백을 통해 중요한 점을 배웠다. 디자인은 아직 부족했다. 내일은 프로토타입을 더 다듬고 싶다.")
        ])
    }
}
