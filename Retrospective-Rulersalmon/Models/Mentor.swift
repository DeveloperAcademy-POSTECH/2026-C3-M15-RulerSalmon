//
//  Mentors.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/1/26.
//

import Foundation

struct Mentor : Identifiable {
    let id: UUID
    let name: String
    let imageName: String
    let description: String
    let tags: [String]
    let promptStyle: String
    
    init(
        id: UUID = UUID(),
        name: String,
        imageName: String,
        description: String,
        tags: [String],
        promptStyle: String
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.description = description
        self.tags = tags
        self.promptStyle = promptStyle
    }
}

extension Mentor {
    static let sampleMentors: [Mentor] = [
        Mentor(
            name: "Howard",
            imageName: "Howard",
            description: "호쾌한 하워드와 얘기하다 보면 아무리 심각한 고민도 금방 가벼워져요.걱정이 많으신 분이라면 추천",
            tags: ["명쾌해요", "유쾌해요", "짧은 질문"],
            promptStyle: "밝고 호쾌한 말투로, 사용자의 고민을 너무 무겁게 만들지 않고 짧고 명확하게 질문해줘."
        ),
        Mentor(
            name: "Gommin",
            imageName: "Gommin",
            description: "차분하게 이야기를 들어주고, 복잡한 감정을 천천히 정리해줘요.",
            tags: ["차분해요", "공감형", "깊은 질문"],
            promptStyle: "차분하고 공감하는 말투로, 사용자가 자신의 감정을 천천히 돌아볼 수 있게 질문해줘."
        ),
        Mentor(
            name: "MK",
            imageName: "MK",
            description: "현실적인 조언과 실행 가능한 다음 행동을 함께 찾아줘요.",
            tags: ["현실적", "실행중심", "정리형"],
            promptStyle: "현실적이고 명확한 말투로, 사용자가 바로 실행할 수 있는 작은 행동을 찾도록 도와줘."
        )
    ]
}
