//
//  FollowUpQuestionGenerator.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation

struct FollowUpQuestionGenerator {
    func generateQuestion(for dimension: ReflectionDimension, state: ReflectionState) -> String {
        switch dimension {
        case .liked:
            return choose([
                "오, 그 경험에서 좋았던 이유가 있어?",
                "그때 특히 좋았던 순간이 뭐였어?",
                "그 경험이 좋게 느껴진 포인트가 있었어?"
            ])
        case .learned:
            return choose([
                "그 경험에서 배운 것도 있었어?",
                "돌아보면 깨달은 점이 있었어?",
                "다음에 도움이 될 만한 배움이 있었어?"
            ])
        case .lacked:
            return choose([
                "아쉬웠던 부분도 있었어?",
                "조금 부족했다고 느낀 건 뭐였어?",
                "마음에 걸린 장면이 있었어?"
            ])
        case .longedFor:
            return choose([
                "다음엔 어떻게 해보고 싶어?",
                "비슷한 상황이 오면 뭐가 달라졌으면 해?",
                "앞으로 바라는 방향이 있어?"
            ])
        }
    }

    private func choose(_ options: [String]) -> String {
        guard let item = options.randomElement() else {
            return "조금 더 이야기해줄래?"
        }
        return item
    }
}
