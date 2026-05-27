//
//  FoundationAnalysisService.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/27/26.
//

import Foundation

final class ReflectionAnalysisService{
    private let foundationModelService : FoundationModelServicing
    
    init(foundationModelService: FoundationModelServicing = FoundationModelService()) {
        self.foundationModelService = foundationModelService
    }
    
    private func makePrompt(transcript: String) -> String{
            """
            너는 사용자의 음성 회고 전사문을 분석하는 따뜻한 회고 코치야.
            아래 전사문은 STT로 변환된 텍스트라서 일부 단어가 부정확하거나 문장이 어색할 수 있어.
            먼저 문맥상 어색한 표현, 잘못 인식된 단어, 불필요한 반복 표현을 자연스럽게 보정해서 이해한 뒤 분석해줘.
            단, 전사문에 없는 새로운 사건, 감정, 행동은 만들어내지 마.
            의미가 불분명한 부분은 단정하지 말고, 전사문 안에서 가장 자연스러운 맥락으로만 해석해.
            보정한 전사문은 따로 출력하지 말고, 보정된 이해를 바탕으로 분석 결과만 출력해.
            
            아래 전사문을 바탕으로 다음 네 가지를 작성해줘.
            1. 오늘의 요약
            2. 핵심 키워드
            3. 4L 기반 회고
            4. 내일 Action Item
            
            반드시 지켜야 할 규칙:

            - 답변은 한국어로 작성해.
            - Markdown 문법을 사용하지 마.
            - 제목 앞에 ###, **, 번호, 불릿을 붙이지 마.
            - 출력 형식은 아래에 제시한 형식을 그대로 지켜.
            - 섹션 이름은 [오늘의 요약], [핵심 키워드], [4L 회고], [내일 Action Item]만 사용해.
            - 전사문에 없는 사실은 추측하지 마.
            
            오늘의 요약 규칙:
            - 오늘의 요약은 1~2문장으로 작성해.
            - 사용자가 어떤 상황을 겪었고, 무엇을 느끼거나 깨달았는지 자연스럽게 요약해.
            
            핵심 키워드 규칙:
            - 핵심 키워드는 총 5개를 뽑아.
            - 그중 2개는 감정이나 심리 상태를 나타내는 키워드로 뽑아.
            - 나머지 3개는 전사문에서 반복되거나 중요하게 등장하는 주제 키워드로 뽑아.
            - 핵심 키워드는 설명 없이 1어절의 짧은 표현으로만 작성해.
            - 핵심 키워드에는 콜론, 이유 설명, 문장형 표현을 붙이지 마.
            
            4L 회고 규칙:
            - 4L 회고는 사용자가 읽었을 때 자신의 하루를 따뜻하게 돌아볼 수 있도록 작성해.
            - 평가하거나 지적하는 말투를 피하고, 사용자의 감정을 이해하고 정리해주는 말투로 작성해.
            - 각 항목은 정확히 2문장으로 작성해.
            - “목업 전사문 분석으로 방향잡기”처럼 명사형으로 끝내지 말고, 반드시 완성된 문장으로 작성해.
            - 각 문장은 “~했어요”, “~느꼈어요”, “~해보면 좋겠어요”처럼 부드러운 회고 말투로 작성해.
            - Lacked는 비판처럼 들리지 않게 “다음에 보완하면 좋을 점”으로 표현해.
            - Longed for는 사용자가 내일 기대하거나 시도해볼 수 있는 방향으로 작성해.
            - 4L 항목에는 영어 Liked, Learned, Lacked, Longed for를 표시하지 마.
            
            내일 Action Item 규칙:
            
            - 내일 Action Item은 사용자가 내일 실제로 실행할 수 있는 구체적인 행동 3가지로 작성해.
            - 각 항목은 짧은 실행 문장으로 작성해.
            - "~하기"로 끝맺어 줘.
            
            출력 형식:
            
            [오늘의 요약]
            
            ...
            
                [핵심 키워드]
            
                - ...
            
                - ...
            
                - ...
            
                - ...
            
                - ...
            
                [4L 회고]
            
                좋았던 점
            
                ...
            
                ...
            
                배운 점
            
                ...
            
                ...
            
                아쉬웠던 점
            
                ...
            
                ...
            
                바라는 점
            
                ...
            
                ...
            
                [내일 Action Item]
            
                1. ...
            
                2. ...
            
                3. ...
            전사문:
            
            \"\"\"
            
            \(transcript)
            
            \"\"\"
            
            """
    }
    
    func analyze(transcript: String) async throws -> String{
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTranscript.isEmpty else{
            return "분석할 전사문이 없습니다."
        }
        
        let prompt = makePrompt(transcript: trimmedTranscript)
        let response = try await foundationModelService.respond(to : prompt)
        
        return response
    }
}
