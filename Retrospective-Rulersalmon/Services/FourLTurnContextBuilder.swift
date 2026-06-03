//
//  FourLTurnContextBuilder.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct FourLTurnContextBuilder {
    func build(from results: [FourLClassificationResult]) -> TurnFourLAnalysis {
        let related = results.filter(\.isFourLRelated)
        let grouped = Dictionary(grouping: related.compactMap { result -> (ReflectionDimension, FourLClassificationResult)? in
            guard let dimension = mapLabelToDimension(result.label) else {
                return nil
            }
            return (dimension, result)
        }, by: \.0)

        let dimensionScores = ReflectionDimension.allCases.map { dimension in
            let items = grouped[dimension]?.map(\.1) ?? []
            let score = items.map(\.confidence).reduce(0, +)
            return (dimension, score, items)
        }

        let strongest = dimensionScores
            .filter { $0.1 > 0 }
            .max { $0.1 < $1.1 }?
            .0

        let weakest = dimensionScores
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0.rawValue < rhs.0.rawValue
                }
                return lhs.1 < rhs.1
            }
            .first?
            .0

        let evidence = Dictionary(uniqueKeysWithValues: dimensionScores.map { dimension, _, items in
            let texts = items
                .sorted { $0.confidence > $1.confidence }
                .prefix(2)
                .map(\.text)
            return (dimension, texts)
        })

        return TurnFourLAnalysis(
            results: related,
            strongestDimension: strongest,
            weakestDimension: weakest,
            dimensionEvidence: evidence
        )
    }

    private func mapLabelToDimension(_ label: String) -> ReflectionDimension? {
        switch label {
        case "Liked": return .liked
        case "Learned": return .learned
        case "Lacked": return .lacked
        case "Longed for": return .longedFor
        default: return nil
        }
    }
}
