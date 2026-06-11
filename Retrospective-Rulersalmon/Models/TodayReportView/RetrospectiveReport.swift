//
//  RetrospectiveReport.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/9/26.
//

import SwiftUI

struct RetrospectiveReport {
    let summary: String
    let transcript: String
    let transcriptMessages: [ChatMessage]
    let fourLEntries: [FourLEntry]
    let keywords: [String]
    let emotionKeywords: [String]
    let actionItems: [String]

    init(
        summary: String,
        transcript: String,
        transcriptMessages: [ChatMessage] = [],
        fourLEntries: [FourLEntry],
        keywords: [String],
        emotionKeywords: [String],
        actionItems: [String]
    ) {
        self.summary = summary
        self.transcript = transcript
        self.transcriptMessages = transcriptMessages
        self.fourLEntries = fourLEntries
        self.keywords = keywords
        self.emotionKeywords = emotionKeywords
        self.actionItems = actionItems
    }
}

struct FourLEntry: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let tintColor: Color
    let content: String
}

extension RetrospectiveReport {
    static let mock = RetrospectiveReport(
        summary: "긴장했던 회의를 안정적으로 끝냈고, 그 과정에서 준비와 호흡이 도움이 됐다는 점을 확인했어요.",
        transcript: """
        오늘 회의는 처음에는 긴장됐지만, 준비했던 내용을 차근차근 말하면서 안정적으로 마무리할 수 있었어요. 피드백을 받는 과정에서 내가 더 보완해야 할 부분도 보였고, 다음에는 작은 시도부터 해보고 싶어요.
        """,
        transcriptMessages: [
            ChatMessage(role: .assistant, text: "좋아, 오늘 회고를 같이 정리해보자. 먼저 떠오르는 장면부터 편하게 말해줘."),
            ChatMessage(role: .user, text: "오늘 회의는 처음에는 긴장됐지만, 준비했던 내용을 차근차근 말하면서 안정적으로 마무리할 수 있었어요."),
            ChatMessage(role: .assistant, text: "그 과정에서 특히 도움이 됐던 준비나 행동이 있었어?"),
            ChatMessage(role: .user, text: "피드백을 받는 과정에서 내가 더 보완해야 할 부분도 보였고, 다음에는 작은 시도부터 해보고 싶어요.")
        ],
        fourLEntries: [
            FourLEntry(
                title: "Liked",
                icon: "😀",
                tintColor: Color.blue50,
                content: "길을 지나가는데 떡꼬치 냄새가 너무 좋아서 행복했어요. 이렇게 글을 두 줄 이상 쓰면 어떻게 되는지 한번 볼까요?"
            ),
            FourLEntry(
                title: "Learned",
                icon: "📘",
                tintColor: Color.purple.opacity(0.12),
                content: "떡꼬치를 먹으려면 1500원이 아니라 2000원이 필요하다는 사실을 배웠어요."
            ),
            FourLEntry(
                title: "Lacked",
                icon: "📉",
                tintColor: Color.yellow.opacity(0.18),
                content: "떡꼬치를 사먹고 싶었는데 500원이 부족했어요."
            ),
            FourLEntry(
                title: "Longed for",
                icon: "☘️",
                tintColor: Color.green.opacity(0.12),
                content: "떡꼬치가 너무 먹고 싶었어요..."
            )
        ],
        keywords: ["집중", "회복", "산책", "작은시도"],
        emotionKeywords: ["뿌듯함", "긴장", "안도"],
        actionItems: [
            "오전 첫 30분은 알림을 끄고 가장 작은 일 하나만 시작하기",
            "점심 이후 10분 산책을 캘린더에 먼저 넣어두기"
        ]
    )
}
