//
//  TurnFourLAnalysis.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct TurnFourLAnalysis: Equatable {
    let results: [FourLClassificationResult]
    let strongestDimension: ReflectionDimension?
    let weakestDimension: ReflectionDimension?
    let dimensionEvidence: [ReflectionDimension: [String]]

    var isEmpty: Bool {
        results.isEmpty
    }

    func evidence(for dimension: ReflectionDimension) -> [String] {
        dimensionEvidence[dimension] ?? []
    }

    func koreanPromptBlock() -> String {
        guard !results.isEmpty else { return "없음" }

        let strongest = strongestDimension?.description ?? "없음"
        let weakest = weakestDimension?.description ?? "없음"
        let lines = results.map { result in
            let secondary = result.secondaryLabel.map { " / 2순위: \($0) (\(String(format: "%.2f", result.secondaryConfidence ?? 0)))" } ?? ""
            return "- \(result.text) -> \(result.label) (\(String(format: "%.2f", result.confidence)))\(secondary)"
        }
        .joined(separator: "\n")

        return """
        1차 4L 분류 결과:
        - 가장 강한 축: \(strongest)
        - 상대적으로 약한 축: \(weakest)
        \(lines)
        """
    }
}
