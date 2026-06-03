//
//  ReflectionChunkAnalyzer.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation

struct ReflectionChunkAnalyzer {
    private let foundationModelService: FoundationModelService
    private static let analysisInstructions = """
    You are a concise Korean analysis engine for retrospective speech chunks.
    Return only a single valid JSON object and nothing else.
    """

    init(foundationModelService: FoundationModelService? = nil) {
        self.foundationModelService = foundationModelService ?? FoundationModelService(
            instructions: Self.analysisInstructions
        )
    }

    func makeChunk(from rawText: String, startedAt: Date = .now, endedAt: Date = .now) -> SpeechChunk {
        let cleanedText = clean(rawText)
        return SpeechChunk(
            rawText: rawText,
            cleanedText: cleanedText,
            startedAt: startedAt,
            endedAt: endedAt,
            type: chunkType(for: cleanedText)
        )
    }

    func analyze(_ chunk: SpeechChunk) async -> ChunkAnalysis {
        guard !chunk.cleanedText.isEmpty else {
            return fallbackAnalyze(chunk)
        }

        if let modelAnalysis = await analyzeWithFoundationModel(chunk) {
            return modelAnalysis
        }

        return fallbackAnalyze(chunk)
    }

    private func analyzeWithFoundationModel(_ chunk: SpeechChunk) async -> ChunkAnalysis? {
        do {
            let response = try await foundationModelService.respond(to: analysisPrompt(for: chunk))
            guard let payload = parseAnalysisResponse(from: response) else {
                return nil
            }

            return makeChunkAnalysis(from: chunk, payload: payload)
        } catch {
            return nil
        }
    }

    private func analysisPrompt(for chunk: SpeechChunk) -> String {
        """
        너는 한국어 회고 발화 청크를 구조화해서 분석하는 엔진이다.
        아래 입력을 보고 반드시 JSON 객체 1개만 출력하라. 설명 문장, 마크다운, 코드블록은 금지한다.
        이 작업은 "한 가지 예시에 맞춰 끼워 넣기"가 아니라, 여러 회고 패턴을 수렴해서 가장 타당한 구조를 뽑는 일이다.

        목표:
        - chunkType: event, emotion, insight, problem, desire, filler, unknown 중 하나
        - detectedDimensions: liked, learned, lacked, longedFor 중 0개 이상, 복수 선택 가능
        - primaryDimension: 위 4개 중 가장 중심이 되는 1개 또는 null
        - summary: 한국어 한 문장 요약
        - dimensionSummaries: 4L 각 차원별 요약을 담는 객체. 네 개 키(liked, learned, lacked, longedFor)를 모두 출력하라.
        - emotions: 감정 표현 배열
        - keywords: 핵심 키워드 배열
        - clauses: 발화를 짧은 절 단위로 나눈 배열
        - evidence: 핵심 근거 배열, 최대 2개
        - missingFollowUpHints: 아직 부족한 4L 차원 배열
        - hasSentenceBoundary: 문장 종결이 있으면 true
        - hasTopicShift: 화제 전환이 있으면 true
        - isMeaningful: 의미 있는 회고 내용이면 true
        - confidence: 0.0 이상 1.0 이하의 수치

        규칙:
        - rawText와 cleanedText를 함께 참고하되, cleanedText를 우선 활용하라.
        - 4L는 서로 배타적인 라벨이 아니지만, 가능한 한 최소한의 차원만 선택하라.
        - liked만 먼저 고르지 말고, learned / lacked / longedFor 신호가 "명시적으로" 보일 때만 함께 넣어라.
        - 단순한 고민, 생각, 검토, 정리, 방향 탐색만으로는 여러 차원을 동시에 확장하지 마라.
        - 학습 결과가 분명하게 드러나지 않으면 learned를 넣지 마라.
        - 부족함이나 막힘이 구체적으로 드러나지 않으면 lacked를 넣지 마라.
        - 다음 행동이나 바람이 분명하게 드러나지 않으면 longedFor를 넣지 마라.
        - summary는 chunk 전체를 한 문장으로 요약하되, 너무 일반적이면 안 된다.
        - dimensionSummaries는 각 차원의 관점에서 따로 써라. 같은 chunk라도 4L마다 표현이 명확히 달라야 한다.
        - dimensionSummaries의 네 값은 같은 문장을 반복하지 말고, 각 차원이 무엇을 말하는지 서로 다른 초점을 가져야 한다.
        - liked는 "무엇이 잘 됐는지", learned는 "무엇을 알게 되었는지", lacked는 "무엇이 부족하거나 막혔는지", longedFor는 "다음에 무엇을 바꾸고 싶은지"만 적어라.
        - 한 문장에 여러 차원이 같이 들어 있더라도, 각 dimensionSummary는 그 차원에 해당하는 부분만 다시 골라 써라.
        - dimensionSummary에 chunk 전체를 그대로 복붙하지 말고, 해당 차원을 한 번 더 풀어서 설명하라.
        - dimensionSummaries는 반드시 네 개 키를 모두 출력하라. 해당 차원이 전혀 없으면 빈 문자열 "" 로 두어라.
        - liked는 만족/성과/협업/안정감이 보일 때, learned는 배움/깨달음/이해가 보일 때,
          lacked는 아쉬움/부족/막힘/어려움이 보일 때, longedFor는 바람/개선/다음 행동이 보일 때 선택하라.
        - keywords는 원문에 실제로 드러난 표현만 넣어라.
        - evidence는 원문에서 바로 확인되는 짧은 문장으로만 작성하라.
        - evidence는 차원마다 최대한 다른 문장을 고르되, 같은 evidence를 4L 전체에 반복하지 마라.
        - evidence는 각 차원이 실제로 말한 부분만 담아라. 공통 문장이나 전체 요약을 evidence로 남기지 마라.
        - summary가 모든 차원에 공통으로 들어갈 것 같으면, summary와 evidence를 더 구체적인 차원별 문장으로 다시 좁혀라.
        - summary와 dimensionSummaries는 "string", "summary", "text", "null" 같은 자리표시자를 절대 쓰지 마라.
        - 배열은 해당 항목이 없으면 빈 배열 [] 로 출력하라.
        - 출력이 망설여지면 가장 타당한 값만 남기고, 애매한 것은 빈 배열 또는 빈 문자열로 비워라.
        - JSON 키 이름은 아래 스키마와 정확히 일치시켜라.

        스키마:
        {
          "chunkType": "event",
          "summary": "이번 발표는 전반적으로 안정적이었고, 역할 분담과 흐름 조율이 잘 맞았던 회고다.",
          "dimensionSummaries": {
            "liked": "좋았던 점은 역할 분담과 흐름 조율이 안정적이어서 진행이 흔들리지 않았다는 점이다.",
            "learned": "배운 점은 화면 전환 구조나 책임 분리를 직접 정리하며 구조화의 의미를 체감했다는 점이다.",
            "lacked": "부족했던 점은 회고를 즉시 정리하거나 질문 타이밍을 자연스럽게 맞추는 부분이 아직 어렵다는 점이다.",
            "longedFor": "바라는 점은 다음에는 질문 흐름과 회고 깊이를 더 자연스럽게 다듬고 싶다는 점이다."
          },
          "detectedDimensions": ["liked"],
          "primaryDimension": "liked",
          "emotions": ["뿌듯함"],
          "keywords": ["팀 협업"],
          "clauses": ["전체 발표 흐름은 잘 맞았고", "작업이 크게 흔들리지 않았어요"],
          "evidence": ["전체 발표 흐름은 생각보다 잘 맞았고", "작업이 크게 흔들리지 않았어요"],
          "missingFollowUpHints": ["liked"],
          "hasSentenceBoundary": true,
          "hasTopicShift": false,
          "isMeaningful": true,
          "confidence": 0.8
        }

        판정 가이드:
        - liked: 좋았던 점, 만족, 뿌듯함, 잘 됨, 성과, 긍정적인 경험
        - learned: 배운 점, 알게 된 점, 깨달음, 이해, 정리된 인사이트
        - lacked: 아쉬웠던 점, 부족함, 막힘, 어려움, 실패, 개선이 필요한 부분
        - longedFor: 다음에 하고 싶은 방식, 바라는 점, 기대, 개선 의지, future wish
        - 여러 차원이 동시에 보이면 모두 선택하라.

        예시 1 - liked 중심:
        입력:
        팀원들이 바로바로 맞춰줘서 일정이 안정적으로 흘러갔고, 발표도 예상보다 자연스럽게 끝났다.
        출력 예:
        {
          "chunkType": "emotion",
          "summary": "팀원과의 호흡이 좋아 일정과 발표가 안정적으로 진행된 회고다.",
          "dimensionSummaries": {
            "liked": "좋았던 점은 팀원들의 호흡이 맞아 일정과 발표가 안정적으로 흘러갔다는 점이다.",
            "learned": "",
            "lacked": "",
            "longedFor": ""
          },
          "detectedDimensions": ["liked"],
          "primaryDimension": "liked",
          "emotions": ["뿌듯함"],
          "keywords": ["안정적", "자연스럽게"],
          "clauses": ["팀원들이 바로바로 맞춰줘서 일정이 안정적으로 흘러갔고", "발표도 예상보다 자연스럽게 끝났다"],
          "evidence": ["팀원들이 바로바로 맞춰줘서 일정이 안정적으로 흘러갔고"],
          "missingFollowUpHints": ["learned", "lacked", "longedFor"],
          "hasSentenceBoundary": true,
          "hasTopicShift": false,
          "isMeaningful": true,
          "confidence": 0.83
        }

        예시 2 - learned + lacked:
        입력:
        이번에는 화면 구조를 직접 정리해보면서 책임 분리가 왜 필요한지 배웠다. 다만 중간에 정리 흐름이 꼬여서 회고를 바로 구조화하는 건 아직 어렵다.
        출력 예:
        {
          "chunkType": "insight",
          "summary": "화면 구조를 정리하며 책임 분리의 의미를 배웠지만, 회고 구조화는 아직 어렵다는 내용이다.",
          "dimensionSummaries": {
            "liked": "",
            "learned": "배운 점은 화면 구조를 직접 정리하면서 책임 분리가 왜 필요한지 이해하게 됐다는 점이다.",
            "lacked": "부족했던 점은 정리 흐름이 꼬여 회고를 바로 구조화하는 과정이 어렵다는 점이다.",
            "longedFor": ""
          },
          "detectedDimensions": ["learned", "lacked"],
          "primaryDimension": "learned",
          "emotions": ["깨달음", "아쉬움"],
          "keywords": ["책임 분리", "구조화"],
          "clauses": ["이번에는 화면 구조를 직접 정리해보면서 책임 분리가 왜 필요한지 배웠다", "다만 중간에 정리 흐름이 꼬여서 회고를 바로 구조화하는 건 아직 어렵다"],
          "evidence": ["이번에는 화면 구조를 직접 정리해보면서 책임 분리가 왜 필요한지 배웠다", "중간에 정리 흐름이 꼬여서 회고를 바로 구조화하는 건 아직 어렵다"],
          "missingFollowUpHints": ["liked", "longedFor"],
          "hasSentenceBoundary": true,
          "hasTopicShift": true,
          "isMeaningful": true,
          "confidence": 0.9
        }

        예시 3 - learned + lacked + longedFor:
        입력:
        지금은 질문 타이밍이 자연스럽지 않아서 흐름이 끊기는 느낌이 있다. 다음에는 사용자가 말하는 맥락을 더 잘 보면서 끊기지 않게 질문하고 싶다.
        출력 예:
        {
          "chunkType": "problem",
          "summary": "질문 타이밍이 자연스럽지 않아 흐름이 끊기고, 다음에는 더 자연스럽게 이어가고 싶다는 회고다.",
          "dimensionSummaries": {
            "liked": "",
            "learned": "",
            "lacked": "부족했던 점은 질문 타이밍이 자연스럽지 않아 대화 흐름이 끊긴다는 점이다.",
            "longedFor": "바라는 점은 다음에는 사용자의 말맥락을 더 잘 보며 끊기지 않게 질문하고 싶다는 점이다."
          },
          "detectedDimensions": ["lacked", "longedFor"],
          "primaryDimension": "lacked",
          "emotions": ["아쉬움", "부담감"],
          "keywords": ["질문 타이밍", "흐름"],
          "clauses": ["지금은 질문 타이밍이 자연스럽지 않아서 흐름이 끊기는 느낌이 있다", "다음에는 사용자가 말하는 맥락을 더 잘 보면서 끊기지 않게 질문하고 싶다"],
          "evidence": ["질문 타이밍이 자연스럽지 않아서 흐름이 끊기는 느낌이 있다", "다음에는 사용자가 말하는 맥락을 더 잘 보면서 끊기지 않게 질문하고 싶다"],
          "missingFollowUpHints": ["liked", "learned"],
          "hasSentenceBoundary": true,
          "hasTopicShift": true,
          "isMeaningful": true,
          "confidence": 0.91
        }

        예시 4 - four dimensions mixed:
        입력:
        이번 프로젝트는 전반적으로 괜찮았고, 팀이 잘 맞아 좋았다. 화면 전환 구조를 직접 잡아보며 많이 배웠다. 다만 중간 회고는 조금 부족했고, 다음에는 질문 타이밍과 회고 깊이를 더 자연스럽게 다듬고 싶다.
        출력 예:
        {
          "chunkType": "event",
          "summary": "이번 프로젝트는 잘 맞는 부분도 있었고, 배움과 아쉬움, 개선 의지도 함께 있었던 회고다.",
          "dimensionSummaries": {
            "liked": "좋았던 점은 팀이 잘 맞아 전반적인 진행이 괜찮았다는 점이다.",
            "learned": "배운 점은 화면 전환 구조를 직접 잡아보며 많이 배웠다는 점이다.",
            "lacked": "부족했던 점은 중간 회고를 정리하는 과정이 조금 부족했다는 점이다.",
            "longedFor": "바라는 점은 다음에는 질문 타이밍과 회고 깊이를 더 자연스럽게 다듬고 싶다는 점이다."
          },
          "detectedDimensions": ["liked", "learned", "lacked", "longedFor"],
          "primaryDimension": "learned",
          "emotions": ["뿌듯함", "아쉬움", "깨달음"],
          "keywords": ["배웠다", "부족", "다음에는"],
          "clauses": ["이번 프로젝트는 전반적으로 괜찮았고", "팀이 잘 맞아 좋았다", "화면 전환 구조를 직접 잡아보며 많이 배웠다", "다만 중간 회고는 조금 부족했고", "다음에는 질문 타이밍과 회고 깊이를 더 자연스럽게 다듬고 싶다"],
          "evidence": ["팀이 잘 맞아 좋았다", "화면 전환 구조를 직접 잡아보며 많이 배웠다"],
          "missingFollowUpHints": [],
          "hasSentenceBoundary": true,
          "hasTopicShift": true,
          "isMeaningful": true,
          "confidence": 0.95
        }

        예시 5 - ambiguous or filler:
        입력:
        음... 그냥 좀 애매했고, 아직 정리가 덜 됐다.
        출력 예:
        {
          "chunkType": "unknown",
          "summary": "아직 정리가 덜 되어 회고의 핵심이 분명하지 않은 상태다.",
          "dimensionSummaries": {
            "liked": "",
            "learned": "",
            "lacked": "부족했던 점은 아직 정리가 덜 되어 핵심이 분명하지 않다는 점이다.",
            "longedFor": ""
          },
          "detectedDimensions": ["lacked"],
          "primaryDimension": "lacked",
          "emotions": ["아쉬움"],
          "keywords": ["애매", "정리"],
          "clauses": ["그냥 좀 애매했고", "아직 정리가 덜 됐다"],
          "evidence": ["아직 정리가 덜 됐다"],
          "missingFollowUpHints": ["liked", "learned", "longedFor"],
          "hasSentenceBoundary": true,
          "hasTopicShift": false,
          "isMeaningful": true,
          "confidence": 0.62
        }

        예시 6 - 고민이 많지만 learned는 아직 불명확한 경우:
        입력:
        이번 작업을 하면서 로직에 대한 고민이 많았어. 어떻게 알고리즘을 짜고 최적화를 할지, UX를 개선할 수 있는지 좀 많이 고민했던 것 같아.
        출력 예:
        {
          "chunkType": "problem",
          "summary": "로직과 UX 개선 방향을 두고 고민이 많았지만, 아직 배움보다 고민과 방향 탐색이 더 두드러진 회고다.",
          "dimensionSummaries": {
            "liked": "",
            "learned": "",
            "lacked": "부족했던 점은 로직과 UX 개선 방향을 어떻게 풀지 아직 구체적으로 정리되지 않았다는 점이다.",
            "longedFor": "바라는 점은 알고리즘과 최적화, UX 개선을 다음에는 더 구체적으로 설계해보고 싶다는 점이다."
          },
          "detectedDimensions": ["lacked", "longedFor"],
          "primaryDimension": "lacked",
          "emotions": ["고민"],
          "keywords": ["로직", "알고리즘", "최적화", "UX 개선"],
          "clauses": ["이번 작업을 하면서 로직에 대한 고민이 많았어", "어떻게 알고리즘을 짜고 최적화를 할지", "UX를 개선할 수 있는지 좀 많이 고민했던 것 같아"],
          "evidence": ["로직에 대한 고민이 많았어", "어떻게 알고리즘을 짜고 최적화를 할지"],
          "missingFollowUpHints": ["liked", "learned"],
          "hasSentenceBoundary": true,
          "hasTopicShift": true,
          "isMeaningful": true,
          "confidence": 0.72
        }

        rawText:
        \(chunk.rawText)

        cleanedText:
        \(chunk.cleanedText)
        """
    }

    private func parseAnalysisResponse(from response: String) -> ModelChunkAnalysis? {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let jsonString: String
        if let startIndex = trimmed.firstIndex(of: "{"),
           let endIndex = trimmed.lastIndex(of: "}") {
            jsonString = String(trimmed[startIndex...endIndex])
        } else {
            jsonString = trimmed
        }

        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ModelChunkAnalysis.self, from: data)
    }

    private func makeChunkAnalysis(from chunk: SpeechChunk, payload: ModelChunkAnalysis) -> ChunkAnalysis {
        let fallback = fallbackAnalysisParts(for: chunk)

        let chunkType = payload.chunkType == .unknown ? fallback.chunkType : payload.chunkType
        let detectedDimensions = mergedDimensions(payload.detectedDimensions, fallback.detectedDimensions)
        let primaryDimension = resolvedPrimaryDimension(payload.primaryDimension, fallback: fallback.primaryDimension, detectedDimensions: detectedDimensions)
        let dimensionSummaries = mergedDimensionSummaries(
            payload.dimensionSummaries,
            fallback.dimensionSummaries,
            overallSummary: payload.summary
        )
        let emotions = mergeTextArray(payload.emotions, fallback.emotions)
        let keywords = mergeTextArray(payload.keywords, fallback.keywords)
        let clauses = mergeTextArray(payload.clauses, fallback.clauses)
        let evidence = mergeTextArray(payload.evidence, fallback.evidence)
        let missingFollowUpHints = resolveMissingHints(payload.missingFollowUpHints, detectedDimensions: detectedDimensions)
        let hasSentenceBoundary = payload.hasSentenceBoundary || fallback.hasSentenceBoundary
        let hasTopicShift = payload.hasTopicShift || fallback.hasTopicShift
        let isMeaningful = payload.isMeaningful || fallback.isMeaningful
        let summary = resolvedSummary(payload.summary, fallback: fallback.summary)
        let confidence = payload.confidence.isFinite ? min(max(payload.confidence, 0), 1) : fallback.confidence

        return ChunkAnalysis(
            originalText: chunk.rawText,
            cleanedText: chunk.cleanedText,
            chunkType: chunkType,
            summary: summary,
            dimensionSummaries: dimensionSummaries,
            detectedDimensions: detectedDimensions,
            primaryDimension: primaryDimension,
            emotions: emotions,
            keywords: keywords,
            clauses: clauses,
            evidence: evidence,
            missingFollowUpHints: missingFollowUpHints,
            hasSentenceBoundary: hasSentenceBoundary,
            hasTopicShift: hasTopicShift,
            isMeaningful: isMeaningful,
            confidence: confidence
        )
    }

    private func fallbackAnalyze(_ chunk: SpeechChunk) -> ChunkAnalysis {
        let parts = fallbackAnalysisParts(for: chunk)
        return ChunkAnalysis(
            originalText: chunk.rawText,
            cleanedText: chunk.cleanedText,
            chunkType: parts.chunkType,
            summary: parts.summary,
            dimensionSummaries: parts.dimensionSummaries,
            detectedDimensions: parts.detectedDimensions,
            primaryDimension: parts.primaryDimension,
            emotions: parts.emotions,
            keywords: parts.keywords,
            clauses: parts.clauses,
            evidence: parts.evidence,
            missingFollowUpHints: parts.missingFollowUpHints,
            hasSentenceBoundary: parts.hasSentenceBoundary,
            hasTopicShift: parts.hasTopicShift,
            isMeaningful: parts.isMeaningful,
            confidence: parts.confidence
        )
    }

    private func fallbackAnalysisParts(for chunk: SpeechChunk) -> AnalysisParts {
        let keywords = matchedKeywords(in: chunk.cleanedText)
        let clauses = splitClauses(in: chunk.rawText)
        let dimensions = detectedDimensions(in: chunk.cleanedText)
        let primaryDimension = primaryDimension(for: chunk.type, dimensions: dimensions, keywords: keywords)
        let emotions = detectedEmotions(in: chunk.cleanedText, dimensions: dimensions)
        let evidence = makeEvidence(from: clauses, cleanedText: chunk.cleanedText, keywords: keywords)
        let hasSentenceBoundary = containsSentenceBoundary(in: chunk.rawText)
        let hasTopicShift = containsTopicShiftMarker(in: chunk.rawText)
        let meaningful = isMeaningful(chunk.cleanedText)
        let summary = makeSummary(from: chunk, dimensions: dimensions, primaryDimension: primaryDimension, keywords: keywords)
        let dimensionSummaries = makeDimensionSummaries(
            from: chunk,
            dimensions: dimensions,
            primaryDimension: primaryDimension,
            keywords: keywords,
            evidence: evidence,
            fallbackSummary: summary
        )
        let missingFollowUpHints = ReflectionDimension.allCases.filter { !dimensions.contains($0) }
        let confidence = makeConfidence(
            text: chunk.cleanedText,
            dimensions: dimensions,
            keywords: keywords,
            hasSentenceBoundary: hasSentenceBoundary,
            hasTopicShift: hasTopicShift,
            evidenceCount: evidence.count
        )

        return AnalysisParts(
            chunkType: chunk.type,
            summary: summary,
            dimensionSummaries: dimensionSummaries,
            detectedDimensions: dimensions,
            primaryDimension: primaryDimension,
            emotions: emotions,
            keywords: keywords,
            clauses: clauses,
            evidence: evidence,
            missingFollowUpHints: missingFollowUpHints,
            hasSentenceBoundary: hasSentenceBoundary,
            hasTopicShift: hasTopicShift,
            isMeaningful: meaningful,
            confidence: confidence
        )
    }

    private func resolvedSummary(_ candidate: String, fallback: String) -> String {
        let normalized = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return fallback }
        guard !isPlaceholderSummary(normalized) else { return fallback }
            return normalized
    }

    private func makeDimensionSummaries(
        from chunk: SpeechChunk,
        dimensions: [ReflectionDimension],
        primaryDimension: ReflectionDimension?,
        keywords: [String],
        evidence: [String],
        fallbackSummary: String
    ) -> [String: String] {
        guard !dimensions.isEmpty else { return [:] }

        var summaries: [String: String] = [:]
        for dimension in dimensions {
            summaries[dimension.rawValue] = makeDimensionSummary(
                for: dimension,
                chunk: chunk,
                primaryDimension: primaryDimension,
                keywords: keywords,
                evidence: evidence,
                fallbackSummary: fallbackSummary
            )
        }
        return summaries
    }

    private func makeDimensionSummary(
        for dimension: ReflectionDimension,
        chunk: SpeechChunk,
        primaryDimension: ReflectionDimension?,
        keywords: [String],
        evidence: [String],
        fallbackSummary: String
    ) -> String {
        let focus = focusPrefix(for: dimension)
        let evidenceText = dimensionEvidenceSnippet(for: dimension, chunk: chunk, evidence: evidence)
        let keywordText = keywords.prefix(2).joined(separator: ", ")

        var core = evidenceText.isEmpty ? fallbackSummary : evidenceText
        if core.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            core = fallbackSummary
        }

        if let primaryDimension, primaryDimension == dimension {
            return "\(focus) 핵심으로 보이며, \(core)"
        }

        if !keywordText.isEmpty {
            return "\(focus) 중심으로 \(keywordText) 신호가 보이며, \(core)"
        }

        return "\(focus) 관련 회고로 보이며, \(core)"
    }

    private func dimensionEvidenceSnippet(
        for dimension: ReflectionDimension,
        chunk: SpeechChunk,
        evidence: [String]
    ) -> String {
        let cues = dimensionCueKeywords(for: dimension)

        if let matchedEvidence = evidence.first(where: { item in
            let lowered = item.lowercased()
            return cues.contains(where: { lowered.contains($0.lowercased()) })
        }) {
            return matchedEvidence
        }

        if let matchedClause = splitClauses(in: chunk.rawText).first(where: { clause in
            let lowered = clause.lowercased()
            return cues.contains(where: { lowered.contains($0.lowercased()) })
        }) {
            return matchedClause
        }

        return evidence.first ?? chunk.cleanedText
    }

    private func focusPrefix(for dimension: ReflectionDimension) -> String {
        switch dimension {
        case .liked:
            return "좋았던 점"
        case .learned:
            return "배운 점"
        case .lacked:
            return "부족했던 점"
        case .longedFor:
            return "바라는 점"
        }
    }

    private func dimensionCueKeywords(for dimension: ReflectionDimension) -> [String] {
        switch dimension {
        case .liked:
            return ["좋았", "뿌듯", "만족", "잘 됐", "안정", "호흡", "괜찮"]
        case .learned:
            return ["배웠", "알게", "깨달", "이해", "정리", "감이", "배운 점"]
        case .lacked:
            return ["아쉬", "부족", "어려웠", "막혔", "꼬였", "헷갈", "회고를 바로"]
        case .longedFor:
            return ["다음", "하고 싶", "해보고 싶", "원하", "바라", "개선", "다듬", "바꾸"]
        }
    }

    private func resolvedPrimaryDimension(
        _ candidate: ReflectionDimension?,
        fallback: ReflectionDimension?,
        detectedDimensions: [ReflectionDimension]
    ) -> ReflectionDimension? {
        if let candidate, detectedDimensions.contains(candidate) {
            return candidate
        }

        if let fallback, detectedDimensions.contains(fallback) {
            return fallback
        }

        return detectedDimensions.first ?? fallback
    }

    private func mergedDimensions(
        _ modelDimensions: [ReflectionDimension],
        _ fallbackDimensions: [ReflectionDimension]
    ) -> [ReflectionDimension] {
        var merged = modelDimensions

        for dimension in fallbackDimensions where !merged.contains(dimension) {
            merged.append(dimension)
        }

        return merged
    }

    private func mergeTextArray(_ modelValues: [String], _ fallbackValues: [String]) -> [String] {
        let sanitizedModel = sanitizeTextArray(modelValues)
        if sanitizedModel.isEmpty {
            return fallbackValues
        }

        var merged = sanitizedModel
        for item in fallbackValues where !merged.contains(item) {
            merged.append(item)
        }
        return merged
    }

    private func mergedDimensionSummaries(
        _ modelSummaries: [String: String],
        _ fallbackSummaries: [String: String],
        overallSummary: String
    ) -> [String: String] {
        var merged: [String: String] = [:]

        for dimension in ReflectionDimension.allCases {
            let key = dimension.rawValue
            let modelValue = sanitizeDimensionSummary(modelSummaries[key], for: dimension, overallSummary: overallSummary)
            let fallbackValue = sanitizeDimensionSummary(fallbackSummaries[key])

            if let modelValue {
                merged[key] = modelValue
            } else if let fallbackValue {
                merged[key] = fallbackValue
            }
        }

        return merged
    }

    private func sanitizeDimensionSummary(_ value: String?) -> String? {
        guard let value else { return nil }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        guard !isPlaceholderSummary(normalized) else { return nil }
        return normalized
    }

    private func sanitizeDimensionSummary(
        _ value: String?,
        for dimension: ReflectionDimension,
        overallSummary: String
    ) -> String? {
        guard let normalized = sanitizeDimensionSummary(value) else { return nil }
        guard isDimensionSpecific(normalized, for: dimension, overallSummary: overallSummary) else { return nil }
        return normalized
    }

    private func resolveMissingHints(
        _ modelValues: [ReflectionDimension],
        detectedDimensions: [ReflectionDimension]
    ) -> [ReflectionDimension] {
        let validValues = modelValues.filter { ReflectionDimension.allCases.contains($0) }
        if !validValues.isEmpty {
            return validValues
        }

        return ReflectionDimension.allCases.filter { !detectedDimensions.contains($0) }
    }

    private func sanitizeTextArray(_ values: [String]) -> [String] {
        values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { !isPlaceholderSummary($0) }
            .uniqued()
    }

    private func isPlaceholderSummary(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let placeholders = [
            "string", "summary", "text", "null", "none",
            "값없음", "없음", "내용", "placeholder"
        ]
        return placeholders.contains(where: { lowered == $0 })
    }

    private func isDimensionSpecific(
        _ summary: String,
        for dimension: ReflectionDimension,
        overallSummary: String
    ) -> Bool {
        let lowered = summary.lowercased()
        let overallLowered = overallSummary.lowercased()

        if !overallLowered.isEmpty, lowered == overallLowered {
            return false
        }

        let targetCues = dimensionCueKeywords(for: dimension)
        let otherCues = ReflectionDimension.allCases
            .filter { $0 != dimension }
            .flatMap { dimensionCueKeywords(for: $0) }

        let targetMatch = targetCues.contains { lowered.contains($0.lowercased()) }
        let otherMatch = otherCues.contains { lowered.contains($0.lowercased()) }

        if targetMatch && !otherMatch {
            return true
        }

        if summary.contains(dimension.description) && !otherMatch {
            return true
        }

        return false
    }

    private func clean(_ text: String) -> String {
        let fillers = ["음", "어", "그", "근데", "그리고", "아", "뭐랄까", "그러니까", "맞아요", "맞아"]
        let tokens = text
            .replacingOccurrences(of: "  ", with: " ")
            .split(separator: " ")
            .map(String.init)
            .filter { !fillers.contains($0.trimmingCharacters(in: .punctuationCharacters)) }

        return tokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func chunkType(for text: String) -> ChunkType {
        if text.isEmpty { return .filler }
        if containsAny(text, ["좋았", "뿌듯", "기뻤", "만족", "즐거"]) { return .emotion }
        if containsAny(text, ["배웠", "배운", "배운 점", "알게", "깨달", "느꼈"]) { return .insight }
        if containsAny(text, ["아쉬", "부족", "못했", "힘들", "어려웠", "꼬였"]) { return .problem }
        if containsAny(text, ["다음", "하고 싶", "해보고 싶", "원해", "원하", "원했"]) { return .desire }
        if containsAny(text, ["회의", "미팅", "프로젝트", "발표", "팀", "일"]) { return .event }
        return .unknown
    }

    private func matchedKeywords(in text: String) -> [String] {
        var keywords: [String] = []

        for (_, values) in dimensionKeywordMap {
            for keyword in values where text.contains(keyword) {
                keywords.append(keyword)
            }
        }

        for keyword in emotionKeywords where text.contains(keyword) {
            keywords.append(keyword)
        }

        for keyword in transitionKeywords where text.contains(keyword) {
            keywords.append(keyword)
        }

        return keywords.uniqued()
    }

    private func detectedDimensions(in text: String) -> [ReflectionDimension] {
        var dimensions: [ReflectionDimension] = []

        for (dimension, keywords) in dimensionKeywordMap {
            if containsAny(text, keywords) {
                dimensions.append(dimension)
            }
        }

        return dimensions.uniqued()
    }

    private func primaryDimension(
        for chunkType: ChunkType,
        dimensions: [ReflectionDimension],
        keywords: [String]
    ) -> ReflectionDimension? {
        if dimensions.count == 1 {
            return dimensions.first
        }

        if let strongest = dimensions.max(by: { score(for: $0, in: keywords) < score(for: $1, in: keywords) }),
           score(for: strongest, in: keywords) > 0 {
            return strongest
        }

        switch chunkType {
        case .emotion:
            return .liked
        case .insight:
            return .learned
        case .problem:
            return .lacked
        case .desire:
            return .longedFor
        case .event, .filler, .unknown:
            return dimensions.first
        }
    }

    private func detectedEmotions(in text: String, dimensions: [ReflectionDimension]) -> [String] {
        var emotions: [String] = []

        if containsAny(text, emotionKeywords) {
            emotions.append("뿌듯함")
        }

        if containsAny(text, ["아쉬", "부족", "못했", "어려웠"]) {
            emotions.append("아쉬움")
        }

        if containsAny(text, ["힘들", "지쳤", "부담"]) {
            emotions.append("부담감")
        }

        if dimensions.contains(.learned) {
            emotions.append("깨달음")
        }

        return emotions.uniqued()
    }

    private func makeEvidence(from clauses: [String], cleanedText: String, keywords: [String]) -> [String] {
        guard !cleanedText.isEmpty else {
            return []
        }

        let normalizedClauses = clauses.map(cleanEvidenceClause).filter { !$0.isEmpty }
        let keywordClauses = normalizedClauses.filter { clause in
            keywords.contains { clause.contains($0) }
        }

        if !keywordClauses.isEmpty {
            return Array(keywordClauses.prefix(2))
        }

        if !normalizedClauses.isEmpty {
            return Array(normalizedClauses.prefix(2))
        }

        return [cleanedText]
    }

    private func makeSummary(
        from chunk: SpeechChunk,
        dimensions: [ReflectionDimension],
        primaryDimension: ReflectionDimension?,
        keywords: [String]
    ) -> String {
        guard !chunk.cleanedText.isEmpty else {
            return "의미 있는 회고 내용이 아직 충분하지 않음."
        }

        let labels = dimensions.map(\.description)
        guard !labels.isEmpty else {
            if let primaryDimension {
                return "\(primaryDimension.description) 중심의 회고가 감지됨."
            }

            if chunk.type != .unknown && chunk.type != .filler {
                return "\(chunk.type.title) 흐름의 회고가 감지됨."
            }

            return "사용자가 회고를 말했지만 아직 4L 중 어디에 속하는지 확실하지 않음."
        }

        let keywordSummary = keywords.prefix(2).joined(separator: ", ")
        if keywordSummary.isEmpty {
            return labels.joined(separator: ", ") + "에 해당하는 회고가 감지됨."
        }

        return labels.joined(separator: ", ") + "에 해당하는 회고가 감지됨. 핵심 신호: \(keywordSummary)"
    }

    private func makeConfidence(
        text: String,
        dimensions: [ReflectionDimension],
        keywords: [String],
        hasSentenceBoundary: Bool,
        hasTopicShift: Bool,
        evidenceCount: Int
    ) -> Double {
        let lengthScore = min(Double(text.count) / 90.0, 0.35)
        let dimensionScore = min(Double(dimensions.count) * 0.18, 0.36)
        let keywordScore = min(Double(keywords.count) * 0.05, 0.2)
        let structureScore = (hasSentenceBoundary ? 0.08 : 0) + (hasTopicShift ? 0.05 : 0)
        let evidenceScore = min(Double(evidenceCount) * 0.04, 0.1)
        return min(lengthScore + dimensionScore + keywordScore + structureScore + evidenceScore + 0.05, 1.0)
    }

    private func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }

    private func splitClauses(in text: String) -> [String] {
        guard !text.isEmpty else { return [] }

        var separated = text
        for marker in transitionKeywords {
            separated = separated.replacingOccurrences(of: marker, with: "|")
        }

        for delimiter in ["。", ".", "?", "!", "…", "~", "？", "！", ",", "·", ";", "；"] {
            separated = separated.replacingOccurrences(of: delimiter, with: "|")
        }

        return separated
            .split(separator: "|")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func cleanEvidenceClause(_ clause: String) -> String {
        let fillers = ["음", "어", "그", "근데", "그리고", "아", "뭐랄까", "그러니까", "맞아요", "맞아"]
        return clause
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .filter { !fillers.contains($0.trimmingCharacters(in: .punctuationCharacters)) }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func score(for dimension: ReflectionDimension, in keywords: [String]) -> Int {
        guard let keywordList = dimensionKeywordMap.first(where: { $0.0 == dimension })?.1 else {
            return 0
        }

        return keywordList.reduce(0) { partialResult, keyword in
            partialResult + (keywords.contains(keyword) ? 1 : 0)
        }
    }

    private var dimensionKeywordMap: [(ReflectionDimension, [String])] {
        [
            (.liked, ["좋았", "뿌듯", "만족", "기뻤", "잘 됐", "괜찮았", "즐거", "재밌", "뿌듯함"]),
            (.learned, ["배웠", "배운", "배운 점", "알게", "깨달", "느꼈", "공부", "이해", "정리"]),
            (.lacked, ["아쉬", "부족", "못했", "힘들", "어려웠", "막혔", "꼬였", "헷갈", "불편"]),
            (.longedFor, ["다음", "하고 싶", "해보고 싶", "원해", "원하", "더 잘", "개선", "바라", "되면 좋"])
        ]
    }

    private var emotionKeywords: [String] {
        ["뿌듯", "기뻤", "좋았", "만족", "아쉬", "부족", "못했", "어려웠", "힘들", "지쳤", "부담"]
    }

    private var transitionKeywords: [String] {
        ["근데", "그리고", "다만", "하지만", "그래서", "또", "한편", "다음에", "이후에", "원래", "결국", "마지막으로", "전환", "바뀌", "넘어가", "다시", "새로"]
    }

    private func containsSentenceBoundary(in text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let sentenceEndings = [
            "다", "요", "죠", "습니다", "입니다", "예요", "이에요",
            "했어요", "했어", "였어요", "였어", "네요", "구요", "듯해요", "같아요"
        ]

        let lastToken = trimmed.split(whereSeparator: { $0.isWhitespace }).last.map(String.init) ?? trimmed
        return sentenceEndings.contains { lastToken.hasSuffix($0) }
    }

    private func containsTopicShiftMarker(in text: String) -> Bool {
        transitionKeywords.contains { text.contains($0) }
    }

    private func isMeaningful(_ text: String) -> Bool {
        let compact = text.replacingOccurrences(of: " ", with: "")
        return compact.count >= 8
    }
}

private struct ModelChunkAnalysis: Codable {
    let chunkType: ChunkType
    let summary: String
    let dimensionSummaries: [String: String]
    let detectedDimensions: [ReflectionDimension]
    let primaryDimension: ReflectionDimension?
    let emotions: [String]
    let keywords: [String]
    let clauses: [String]
    let evidence: [String]
    let missingFollowUpHints: [ReflectionDimension]
    let hasSentenceBoundary: Bool
    let hasTopicShift: Bool
    let isMeaningful: Bool
    let confidence: Double
}

private struct AnalysisParts {
    let chunkType: ChunkType
    let summary: String
    let dimensionSummaries: [String: String]
    let detectedDimensions: [ReflectionDimension]
    let primaryDimension: ReflectionDimension?
    let emotions: [String]
    let keywords: [String]
    let clauses: [String]
    let evidence: [String]
    let missingFollowUpHints: [ReflectionDimension]
    let hasSentenceBoundary: Bool
    let hasTopicShift: Bool
    let isMeaningful: Bool
    let confidence: Double
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
