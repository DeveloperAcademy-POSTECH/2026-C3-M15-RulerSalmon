//
//  FourLResultViewModel.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/3/26.
//

import Foundation
import Combine

@MainActor
final class FourLResultViewModel: ObservableObject {
    @Published var results: [FourLClassificationResult] = []
    @Published var refinedTexts: [UUID: String] = [:]
    @Published var summaryResult: ReflectionSummaryResult?
    @Published var errorMessage: String?
    @Published var isRefining = false
    @Published var isGeneratingSummary = false

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

    func generateResults() {
        guard results.isEmpty, errorMessage == nil else { return }
        runAnalysis()
    }

    func generateResults(with messages: [ChatMessage]) {
        self.messages = messages
        results = []
        refinedTexts = [:]
        summaryResult = nil
        runAnalysis()
    }

    private func runAnalysis() {
        guard errorMessage == nil else { return }

        Task {
            results = await fourLService.classify(messages: messages)
            summaryResult = nil
            await refineResults()
        }
    }

    func topResultsByFourL(limit: Int = 2) -> [String: [FourLClassificationResult]] {
        fourLService.topResultsByFourL(from: results, limit: limit)
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
}
