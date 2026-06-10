//
//  RetrospectiveAnalysisViewModel.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/9/26.
//

import SwiftUI
import Combine

@MainActor
final class RetrospectiveAnalysisViewModel: ObservableObject {
    @Published private(set) var results: [FourLClassificationResult] = []
    @Published private(set) var refinedTexts: [UUID: String] = [:]
    @Published private(set) var summaryResult: ReflectionSummaryResult?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isRefining = false
    @Published private(set) var isGeneratingSummary = false
    @Published var completedReport: RetrospectiveReport?
    @Published var isShowingReport = false

    private var messages: [ChatMessage]
    private let fourLService: FourLService
    private let refinementService: FourLRefinementService
    private let summaryService: ReflectionSummaryService

    init(
        messages: [ChatMessage],
        fourLService: FourLService? = nil,
        refinementService: FourLRefinementService? = nil,
        summaryService: ReflectionSummaryService? = nil
    ) {
        self.messages = messages
        self.refinementService = refinementService ?? FourLRefinementService()
        self.summaryService = summaryService ?? ReflectionSummaryService()

        do {
            if let fourLService {
                self.fourLService = fourLService
            } else {
                self.fourLService = try FourLService()
            }
        } catch {
            self.fourLService = FourLService.emptyFallback
            self.errorMessage = error.localizedDescription
        }
    }

    var progress: Double {
        if isGeneratingSummary {
            return 0.88
        }

        if isRefining {
            return 0.64
        }

        if !results.isEmpty {
            return 0.42
        }

        return 0.18
    }

    func generateResults() {
        guard results.isEmpty, errorMessage == nil else { return }
        runAnalysis()
    }

    private func runAnalysis() {
        Task {
            results = await fourLService.classify(messages: messages)
            summaryResult = nil
            await refineResults()
            prepareReportIfNeeded()
        }
    }

    private func refineResults() async {
        isRefining = true

        let refinedTexts = await refinementService.refine(results: results)

        self.refinedTexts = refinedTexts
        self.isRefining = false

        await generateSummary(refinedTexts: refinedTexts)
    }

    private func generateSummary(refinedTexts: [UUID: String]) async {
        isGeneratingSummary = true

        summaryResult = await summaryService.summarize(
            messages: messages,
            results: results,
            refinedTexts: refinedTexts
        )

        isGeneratingSummary = false
    }

    private func prepareReportIfNeeded() {
        guard let report else { return }
        completedReport = report
        isShowingReport = true
    }

    private var report: RetrospectiveReport? {
        guard let summaryResult,
              !isRefining,
              !isGeneratingSummary else {
            return nil
        }

        return RetrospectiveReport(
            summary: summaryResult.todaySummary,
            transcript: summaryResult.refinedReflection,
            fourLEntries: fourLEntries,
            keywords: summaryResult.coreKeywords,
            emotionKeywords: summaryResult.emotionKeywords,
            actionItems: summaryResult.actionItems
        )
    }

    private var fourLEntries: [FourLEntry] {
        let order = ["Liked", "Longed for", "Lacked", "Learned"]
        let groupedResults = topResultsByFourL()

        return order.map { label in
            let result = groupedResults[label]?.first
            let content = result.flatMap { refinedTexts[$0.id] } ?? result?.text ?? emptyMessage(for: label)

            return FourLEntry(
                title: label,
                icon: icon(for: label),
                tintColor: tintColor(for: label),
                content: content
            )
        }
    }

    private func topResultsByFourL(limit: Int = 2) -> [String: [FourLClassificationResult]] {
        fourLService.topResultsByFourL(from: results, limit: limit)
    }

    private func emptyMessage(for label: String) -> String {
        switch label {
        case "Liked":
            return "오늘은 좋았던 점이 뚜렷하게 기록되지 않았어요."
        case "Longed for":
            return "오늘은 더 바랐던 점이 뚜렷하게 기록되지 않았어요."
        case "Lacked":
            return "오늘은 아쉬웠던 점이 뚜렷하게 기록되지 않았어요."
        case "Learned":
            return "오늘은 새롭게 배운 점이 뚜렷하게 기록되지 않았어요."
        default:
            return "해당 회고 문장이 기록되지 않았어요."
        }
    }

    private func icon(for label: String) -> String {
        switch label {
        case "Liked":
            return "😀"
        case "Longed for":
            return "☘️"
        case "Lacked":
            return "📉"
        case "Learned":
            return "📘"
        default:
            return "•"
        }
    }

    private func tintColor(for label: String) -> Color {
        switch label {
        case "Liked":
            return Color.yellow.opacity(0.18)
        case "Longed for":
            return Color.green.opacity(0.12)
        case "Lacked":
            return Color.blue50
        case "Learned":
            return Color.purple.opacity(0.12)
        default:
            return Color.gray50
        }
    }
}
