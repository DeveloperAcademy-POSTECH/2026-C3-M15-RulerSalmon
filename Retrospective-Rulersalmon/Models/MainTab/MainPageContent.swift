//
//  MainPageContent.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct MainPageContent {
    let userName: String
    let encouragementMessage: String
    let mentorBadgeTitle: String
    let mentorName: String
    let mentorImageName: String
    let mentorGreeting: String
    let retrospectives: [RetrospectiveItem]
}

struct RetrospectiveItem: Identifiable, Hashable {
    let id: UUID
    let date: String
    let title: String
    let subtitle: String?

    init(
        id: UUID = UUID(),
        date: String,
        title: String,
        subtitle: String? = nil
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.subtitle = subtitle
    }
}

extension MainPageContent {
    static let mock = MainPageContent(
        userName: "김여운",
        encouragementMessage: "최근 회고에서 조금 지쳐 보였어요.\n오늘은 짧고 간단하게 해 봐요.",
        mentorBadgeTitle: "오늘 함께할 멘토",
        mentorName: "Howard",
        mentorImageName: "Howard",
        mentorGreeting: "안녕하십니까! 하워드입니다!\n저와 함께 하루를 정리해 보시죠!",
        retrospectives: [
            RetrospectiveItem(date: "6/10", title: "자신감 키우기", subtitle: "자아 존중감, 도전, 성공 경험"),
            RetrospectiveItem(date: "6/9", title: "피드백 문화", subtitle: "개선, 발전, 협력"),
            RetrospectiveItem(date: "6/8", title: "목표 설정", subtitle: "구체성, 측정 가능성, 가능성"),
            RetrospectiveItem(date: "6/7", title: "발표 준비", subtitle: "대화, 이해, 조정"),
            RetrospectiveItem(date: "6/6", title: "협업 회고", subtitle: "학습, 성장, 지속성"),
            RetrospectiveItem(date: "6/5", title: "집중 루틴", subtitle: "우선순위, 계획, 효율성"),
            RetrospectiveItem(date: "6/4", title: "작게 회복한 하루", subtitle: "명확성, 경청, 피드백"),
            RetrospectiveItem(date: "6/3", title: "다음 액션 정리", subtitle: "영향력, 비전, 동기 부여")
        ]
    )
}
