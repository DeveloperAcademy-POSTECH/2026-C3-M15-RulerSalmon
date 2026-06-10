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

    init(
        id: UUID = UUID(),
        date: String,
        title: String
    ) {
        self.id = id
        self.date = date
        self.title = title
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
            RetrospectiveItem(date: "6/10", title: "자신감 키우기"),
            RetrospectiveItem(date: "6/9", title: "피드백 문화"),
            RetrospectiveItem(date: "6/8", title: "목표 설정"),
            RetrospectiveItem(date: "6/7", title: "발표 준비"),
            RetrospectiveItem(date: "6/6", title: "협업 회고"),
            RetrospectiveItem(date: "6/5", title: "집중 루틴"),
            RetrospectiveItem(date: "6/4", title: "작게 회복한 하루"),
            RetrospectiveItem(date: "6/3", title: "다음 액션 정리")
        ]
    )
}
