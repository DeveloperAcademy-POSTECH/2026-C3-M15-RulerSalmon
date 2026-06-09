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
            HStack {
                mockMenu
                Spacer()
            }
            .padding(.horizontal)

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

    private var mockMenu: some View {
        Menu {
            ForEach(MockReflection.allCases) { mock in
                Button(mock.title) {
                    selectedMode = .topTwo
                    viewModel.generateResults(with: mock.messages)
                }
            }
        } label: {
            Text("Mock 분석")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.blue600)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.blue50)
                .clipShape(Capsule())
        }
        .disabled(viewModel.isRefining || viewModel.isGeneratingSummary)
        .opacity((viewModel.isRefining || viewModel.isGeneratingSummary) ? 0.5 : 1.0)
    }

    private var topTwoContent: some View {
        ForEach(FourLService.fourLLabels, id: \.self) { label in
            Section {
                let items = topResultsByFourL[label] ?? []

                if items.isEmpty {
                    Text(emptyMessage(for: label))
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
        ForEach(FourLService.fourLLabels + [FourLService.unclearLabel], id: \.self) { label in
            Section {
                let items = viewModel.results.filter { $0.label == label }

                if items.isEmpty {
                    Text(emptyMessage(for: label))
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
                if let refinedReflection = viewModel.summaryResult?.refinedReflection,
                   !refinedReflection.isEmpty {
                    Text(refinedReflection)
                } else {
                    Text("회고 결과문 생성 대기 중")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("회고 결과문")
            }

            Section {
                if let summary = viewModel.summaryResult?.todaySummary,
                   !summary.isEmpty {
                    Text(summary)
                } else {
                    Text("요약 생성 대기 중")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("오늘의 요약")
            }

            Section {
                keywordChips(viewModel.summaryResult?.coreKeywords ?? [])
            } header: {
                Text("핵심키워드")
            }

            Section {
                keywordChips(viewModel.summaryResult?.emotionKeywords ?? [])
            } header: {
                Text("감정키워드")
            }

            Section {
                actionItemsView(viewModel.summaryResult?.actionItems ?? [])
            } header: {
                Text("내일 Action Item")
            }
        }
    }
    
    private func keywordChips(_ keywords: [String]) -> some View {
        Group {
            if keywords.isEmpty {
                Text("추출된 키워드가 없습니다.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(keywords, id: \.self) { keyword in
                        Text("#\(keyword)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.blue600)
                    }
                }
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
                    Text("Unclear 문장은 정제하지 않습니다.")
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

private func emptyMessage(for label: String) -> String {
    switch label {
    case "Liked":
        return "오늘은 좋았던 점이 없었어요."
    case "Learned":
        return "오늘은 새롭게 배운 점이 없었어요."
    case "Lacked":
        return "오늘은 아쉬웠던 점이 없었어요."
    case "Longed for":
        return "오늘은 더 바랐던 점이 없었어요."
    default:
        return "분류된 문장이 없어요."
    }
}

#Preview("긍정 회고") {
    NavigationStack {
        FourLResultView(messages: MockReflection.positive.messages)
    }
}

#Preview("부정 회고") {
    NavigationStack {
        FourLResultView(messages: MockReflection.negative.messages)
    }
}

#Preview("애매한 회고") {
    NavigationStack {
        FourLResultView(messages: MockReflection.unclear.messages)
    }
}


private enum MockReflection: CaseIterable, Identifiable {
    case positive
    case negative
    case unclear

    var id: Self { self }

    var title: String {
        switch self {
        case .positive:
            return "긍정 회고"
        case .negative:
            return "부정 회고"
        case .unclear:
            return "애매한 회고"
        }
    }

    var messages: [ChatMessage] {
        [ChatMessage(role: .user, text: text)]
    }

    private var text: String {
        switch self {
        case .positive:
            return """
            오늘은 팀원들과 빠르게 의견을 맞추면서 기능 방향이 조금 더 명확해져서 좋았어요.
            처음에는 회고 결과 화면에 어떤 정보를 보여줘야 할지 애매했는데, 요약, 핵심키워드, 감정키워드, Action Item으로 나누어 생각하니 구조가 정리됐어요.
            Foundation Model 프롬프트를 다시 살펴보면서 instruction과 prompt의 역할을 분리해야 한다는 점도 더 잘 이해했어요.
            특히 Prompt에는 매번 바뀌는 사용자 입력만 간결하게 넣고, 출력 규칙은 Generable과 Guide에서 잡아주는 방식이 더 안정적이라는 걸 배웠어요.
            팀원들과 이야기하면서 내가 맡은 분석 흐름이 앱 전체 경험에서 중요한 부분이라는 생각이 들어서 조금 자신감이 생겼어요.
            내일은 오늘 만든 분석 결과를 리포트 화면에 연결해보고, 실제 사용자가 읽었을 때 자연스럽게 느껴지는지도 확인해보고 싶어요.
            """
        case .negative:
            return """
            오늘은 시뮬레이터에서 모델 예측이 계속 실패해서 많이 답답했어요.
            처음에는 코드 문제라고 생각했는데, 로그를 자세히 보니 Foundation Model 리소스나 Apple Intelligence 설정 문제일 수도 있다는 생각이 들었어요.
            원인을 바로 찾지 못해서 같은 부분을 여러 번 확인했고, 그 과정에서 시간이 오래 걸린 점이 아쉬웠어요.
            특히 에러 메시지가 길고 복잡해서 어디를 먼저 봐야 할지 몰라서 더 혼란스러웠어요.
            그래도 오류 내용을 하나씩 뜯어보면서 availability 체크와 실기기 테스트가 필요하다는 점은 알게 됐어요.
            내일은 실패 로그를 먼저 정리하고, 짧은 테스트 입력으로 모델이 정상 동작하는지 확인한 뒤에 실제 회고 데이터를 넣어보고 싶어요.
            """
        case .unclear:
            return """
            오늘은 이것저것 확인하긴 했는데, 정확히 무엇을 가장 많이 진행했는지는 잘 모르겠어요.
            Foundation Model 코드도 봤고, 회고 분석 결과 화면도 생각해봤고, mock 데이터도 조금 수정했어요.
            그런데 작업을 하면서 계속 다른 문제가 보여서 하나에 집중하기가 어려웠어요.
            어떤 부분은 이해한 것 같기도 하고, 막상 코드에 적용하려고 하면 다시 헷갈리는 부분도 있었어요.
            그래도 지금 필요한 건 완벽하게 모든 기능을 끝내는 것보다, 분석 흐름이 실제로 잘 이어지는지 확인하는 거라는 생각이 들었어요.
            내일은 해야 할 일을 너무 넓게 잡지 말고, mock 데이터 입력부터 결과 화면 확인까지 하나의 흐름만 먼저 점검해보고 싶어요.
            """
        }
    }
}
