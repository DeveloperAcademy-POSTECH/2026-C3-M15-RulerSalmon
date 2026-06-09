import SwiftUI
import SwiftData

struct SentimentAnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SentimentRecord.createdAt, order: .reverse) private var records: [SentimentRecord]
    @Query(sort: \ReflectionInsightRecord.updatedAt, order: .reverse) private var storedInsights: [ReflectionInsightRecord]

    @State private var transcript = """
    이번 프로젝트는 일정이 촉박해서 힘들었지만 팀원들이 적극적으로 도와줘서 끝까지 마무리할 수 있었다.
    소통은 이전보다 좋아졌고 리뷰 과정에서 배운 점도 많았다.
    다만 요구사항이 중간에 바뀌어서 혼란스러운 순간이 있었고 테스트 시간이 부족했던 점은 아쉽다.
    결과물은 생각보다 안정적으로 나와서 전반적으로는 만족스럽다.
    """
    @State private var selectedDate = Date()
    @State private var result = RetrospectiveSentimentResult.empty
    @State private var debugMessage = "분석 대기 중"
    @State private var saveMessage: String?
    @State private var insightResult = ReflectionInsightResult.empty
    @State private var selectedInsightDays = 30
    @State private var isLoadingInsights = false
    @State private var insightErrorMessage: String?

    private let analyzer = RetrospectiveSentimentAnalyzer()
    private let insightService = ReflectionInsightService()
    private var statistics: SentimentSummary {
        SentimentStatistics.summarize(records)
    }
    private var savedReflectionRecords: [SentimentRecord] {
        records
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    debugSection
                    inputSection
                    scoreSection
                    saveSection
                    insightSection
                    recordsSection
                    statisticsSection
                    keywordSection
                    segmentSection
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("감정 분석")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        analyze()
                    } label: {
                        Label("분석", systemImage: "chart.bar.xaxis")
                    }
                    .disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .task {
            analyze()
            loadStoredInsights()
            await bootstrapStoredInsightsIfNeeded()
        }
        .onChange(of: records.count) {
            Task {
                loadStoredInsights()
                await bootstrapStoredInsightsIfNeeded()
            }
        }
        .onChange(of: selectedInsightDays) {
            refreshInsights()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("회고록의 긍정/부정 비율과 만족도 점수를 산출합니다.")
                .font(.title3.weight(.semibold))
            Text("현재 PoC는 HowRU KoELECTRA CoreML 회귀 모델로 문장별 감정 점수를 계산합니다.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var debugSection: some View {
        #if DEBUG
        Text(debugMessage)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
        #else
        EmptyView()
        #endif
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("회고 전사문")
                .font(.headline)

            DatePicker(
                "회고 날짜",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)

            TextEditor(text: $transcript)
                .frame(minHeight: 180)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 0.5)
                }

            Button {
                analyze()
            } label: {
                Label("감정 분석하기", systemImage: "chart.line.uptrend.xyaxis")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var saveSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("저장")
                .font(.headline)

            Button {
                saveRetrospective()
            } label: {
                Label("선택한 날짜로 회고 저장", systemImage: "tray.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if let saveMessage {
                Text(saveMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("저장된 회고")
                    .font(.headline)
                Spacer()
                Text("\(records.count)개")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if records.isEmpty {
                Text("아직 저장된 회고가 없습니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(records) { record in
                    SavedRecordRow(record: record) {
                        deleteRecord(record)
                    }
                }
            }
        }
    }

    private var insightSection: some View {
        ReflectionInsightSectionView(
            result: insightResult,
            selectedDays: $selectedInsightDays,
            recordCount: records.count,
            isLoading: isLoadingInsights,
            errorMessage: insightErrorMessage,
            onRefresh: refreshInsights
        )
    }
    
    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("분석 결과")
                .font(.headline)

            HStack(spacing: 12) {
                ScoreTile(
                    title: "긍정",
                    value: "\(formatPercent(result.positivePercentage))%",
                    tint: .green
                )
                ScoreTile(
                    title: "부정",
                    value: "\(formatPercent(result.negativePercentage))%",
                    tint: .red
                )
                ScoreTile(
                    title: "만족도",
                    value: "\(formatScore(result.satisfactionScore))/5",
                    tint: .blue
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                RatioBar(
                    positivePercentage: result.positivePercentage,
                    negativePercentage: result.negativePercentage
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("전체 기간 분석 통계")
                .font(.headline)
            
            HStack(spacing: 12) {
                
                ScoreTile(
                    title: "긍정",
                    value: "\(formatPercent(statistics.positivePercentage))%",
                    tint: .green
                )
                ScoreTile(
                    title: "부정",
                    value: "\(formatPercent(statistics.negativePercentage))%",
                    tint: .red
                )
                ScoreTile(
                    title: "만족도",
                    value: "\(formatScore(statistics.satisfactionScore))/5",
                    tint: .blue
                )
            }
            
            VStack(alignment: .leading, spacing: 10) {
                RatioBar(
                    positivePercentage: statistics.positivePercentage,
                    negativePercentage: statistics.negativePercentage
                )
            }
            
            Text("주간 분석 통계")
                .font(.headline)
            
            HStack(spacing: 12) {
                
                ScoreTile(
                    title: "긍정",
                    value: "\(formatPercent(filteredStatistics(in: .weekOfYear).positivePercentage))%",
                    tint: .green
                )
                ScoreTile(
                    title: "부정",
                    value: "\(formatPercent(filteredStatistics(in: .weekOfYear).negativePercentage))%",
                    tint: .red
                )
                ScoreTile(
                    title: "만족도",
                    value: "\(formatScore(filteredStatistics(in: .weekOfYear).satisfactionScore))/5",
                    tint: .blue
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                RatioBar(
                    positivePercentage: filteredStatistics(in: .weekOfYear).positivePercentage,
                    negativePercentage: filteredStatistics(in: .weekOfYear).negativePercentage
                )
            }
            
            Text("월간 분석 통계")
                .font(.headline)
            
            HStack(spacing: 12) {
                
                ScoreTile(
                    title: "긍정",
                    value: "\(formatPercent(filteredStatistics(in: .month).positivePercentage))%",
                    tint: .green
                )
                ScoreTile(
                    title: "부정",
                    value: "\(formatPercent(filteredStatistics(in: .month).negativePercentage))%",
                    tint: .red
                )
                ScoreTile(
                    title: "만족도",
                    value: "\(formatScore(filteredStatistics(in: .month).satisfactionScore))/5",
                    tint: .blue
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                RatioBar(
                    positivePercentage: filteredStatistics(in: .month).positivePercentage,
                    negativePercentage: filteredStatistics(in: .month).negativePercentage
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }


    private var keywordSection: some View {
        HStack(alignment: .top, spacing: 12) {
            KeywordList(title: "긍정 키워드", keywords: result.positiveKeywords, tint: .green)
            KeywordList(title: "부정 키워드", keywords: result.negativeKeywords, tint: .red)
        }
    }

    private var segmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("문장별 판정")
                .font(.headline)

            if result.segments.isEmpty {
                Text("분석할 회고록을 입력해 주세요.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(result.segments) { segment in
                    SegmentRow(segment: segment)
                }
            }
        }
    }

    private func analyze() {
        result = analyzer.analyze(transcript)
        let scoreSummary = result.segments
            .prefix(4)
            .map { String(format: "%.2f", $0.score) }
            .joined(separator: ", ")
        debugMessage = "\(analyzer.debugStatus), segments: \(result.segments.count), scores: [\(scoreSummary)]"
        print("[SentimentAnalysisView] \(debugMessage)")
    }

    private func saveRetrospective() {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else { return }

        let analyzedResult = analyzer.analyze(trimmedTranscript)
        result = analyzedResult

        let record = SentimentRecord(
            createdAt: selectedDate,
            transcript: trimmedTranscript,
            result: analyzedResult
        )
        modelContext.insert(record)

        do {
            try modelContext.save()
            saveMessage = "\(formatDate(selectedDate)) 회고를 저장했습니다."
            updateInsightsAfterSaving(record)
        } catch {
            saveMessage = "저장 실패: \(error.localizedDescription)"
        }
    }
    
    private func filteredRecords(for granularity: Calendar.Component) -> [SentimentRecord] {
        var calendar = Calendar(identifier: .gregorian)
        
        if granularity == .weekOfYear {
            calendar.firstWeekday = 2
        }
        return records.filter {
            calendar.isDate($0.createdAt, equalTo: Date(), toGranularity: granularity)
        }
    }
    
    private func filteredStatistics (in granularity: Calendar.Component) -> SentimentSummary {
        SentimentStatistics.summarize(filteredRecords(for: granularity))
    }

    private func deleteRecord(_ record: SentimentRecord) {
        removeRecordFromInsights(record)
        modelContext.delete(record)

        do {
            try modelContext.save()
            saveMessage = "저장된 회고를 삭제했습니다."
            loadStoredInsights()
        } catch {
            saveMessage = "삭제 실패: \(error.localizedDescription)"
        }
    }

    private func removeRecordFromInsights(_ record: SentimentRecord) {
        let now = Date()

        for insight in storedInsights where insight.containsSourceRecord(record) {
            insight.removeSourceRecord(record)
            insight.count = insight.sourceIDs.count
            insight.updatedAt = now
        }
    }

    private func refreshInsights() {
        Task {
            await generateMissingInsightsFromStoredRecords()
        }
    }

    @MainActor
    private func bootstrapStoredInsightsIfNeeded() async {
        removeInvalidStoredInsightsIfNeeded()
        let validInsights = storedInsights.filter { !isInvalidInsight($0) }

        #if DEBUG
        print("[SentimentAnalysisView] bootstrap check records: \(savedReflectionRecords.count), storedInsights: \(validInsights.count)")
        #endif

        guard validInsights.isEmpty,
              savedReflectionRecords.count >= 3 else {
            return
        }

        await generateMissingInsightsFromStoredRecords()
    }

    @MainActor
    private func generateMissingInsightsFromStoredRecords() async {
        guard savedReflectionRecords.count >= 3 else {
            loadStoredInsights()
            return
        }

        isLoadingInsights = true
        insightErrorMessage = nil
        defer { isLoadingInsights = false }

        do {
            let result = try await insightService.generateInsights(
                from: savedReflectionRecords,
                days: selectedInsightDays
            )
            guard !result.reflectionPoints.isEmpty || !result.strengthPoints.isEmpty else {
                #if DEBUG
                print("[SentimentAnalysisView] generated insight result is empty")
                #endif
                loadStoredInsights()
                return
            }

            insertMissingInsights(result)
            try modelContext.save()
            loadStoredInsights()
        } catch {
            insightErrorMessage = error.localizedDescription
            loadStoredInsights()
        }
    }

    @MainActor
    private func loadStoredInsights() {
        removeInvalidStoredInsightsIfNeeded()
        insightResult = makeInsightResult(
            from: storedInsights.filter { !isInvalidInsight($0) }
        )
        insightErrorMessage = nil
    }

    private func makeInsightResult(from insights: [ReflectionInsightRecord]) -> ReflectionInsightResult {
        let reflectionPoints = insights
            .filter { $0.kind == "reflection" && $0.count >= 3 && !isInvalidInsight($0) }
            .sorted { first, second in
                if first.count == second.count { return first.updatedAt > second.updatedAt }
                return first.count > second.count
            }
            .prefix(2)
            .map {
                ReflectionInsightPoint(
                    title: $0.title,
                    description: $0.insightDescription,
                    count: $0.count
                )
            }

        let strengthPoints = insights
            .filter { $0.kind == "strength" && $0.count >= 3 && !isInvalidInsight($0) }
            .sorted { first, second in
                if first.count == second.count { return first.updatedAt > second.updatedAt }
                return first.count > second.count
            }
            .prefix(2)
            .map {
                ReflectionInsightPoint(
                    title: $0.title,
                    description: $0.insightDescription,
                    count: $0.count
                )
            }

        return ReflectionInsightResult(
            reflectionPoints: Array(reflectionPoints),
            strengthPoints: Array(strengthPoints)
        )
    }

    private func removeInvalidStoredInsightsIfNeeded() {
        let invalidInsights = storedInsights.filter { isInvalidInsight($0) }
        guard !invalidInsights.isEmpty else { return }

        invalidInsights.forEach(modelContext.delete)
        try? modelContext.save()
    }

    private func isInvalidInsight(_ insight: ReflectionInsightRecord) -> Bool {
        let normalizedTitle = normalizedInsightKey(insight.title)
        let normalizedDescription = normalizedInsightKey(insight.insightDescription)
        let exactPlaceholders = [
            "제목",
            "설명",
            "새반성포인트제목",
            "새강점포인트제목",
            "반복되는공통점설명",
            "구체적사건이아니라반복되는공통점설명"
        ]
        let englishPlaceholders = [
            "title",
            "description"
        ]

        if exactPlaceholders.contains(normalizedTitle) ||
            exactPlaceholders.contains(normalizedDescription) {
            return true
        }

        return englishPlaceholders.contains { fragment in
            normalizedTitle.contains(fragment) || normalizedDescription.contains(fragment)
        }
    }

    private func updateInsightsAfterSaving(_ record: SentimentRecord) {
        Task {
            await updateStoredInsights(afterAdding: record)
        }
    }

    @MainActor
    private func updateStoredInsights(afterAdding record: SentimentRecord) async {
        isLoadingInsights = true
        insightErrorMessage = nil
        defer { isLoadingInsights = false }

        do {
            let allRecords = ([record] + savedReflectionRecords)
                .reduce(into: [UUID: SentimentRecord]()) { recordsByID, record in
                    recordsByID[record.id] = record
                }
                .values
                .sorted { $0.createdAt < $1.createdAt }

            let update = try await insightService.updateInsights(
                afterAdding: record,
                allRecords: allRecords,
                existingInsights: storedInsights.filter { !isInvalidInsight($0) }
            )
            applyInsightUpdate(update, newRecord: record)
            try modelContext.save()
            loadStoredInsights()
        } catch {
            insightErrorMessage = error.localizedDescription
            loadStoredInsights()
        }
    }

    private func applyInsightUpdate(
        _ update: ReflectionInsightUpdate,
        newRecord: SentimentRecord
    ) {
        let now = Date()

        for insightID in update.matchedInsightIDs {
            guard let insight = storedInsights.first(where: { $0.id == insightID }),
                  !insight.containsSourceRecord(newRecord) else {
                continue
            }

            insight.count += 1
            insight.addSourceRecord(newRecord)
            insight.updatedAt = now
        }

        for point in update.newReflectionPoints {
            insertInsight(
                point,
                kind: "reflection",
                sourceRecords: [newRecord],
                now: now
            )
        }

        for point in update.newStrengthPoints {
            insertInsight(
                point,
                kind: "strength",
                sourceRecords: [newRecord],
                now: now
            )
        }
    }

    private func insertMissingInsights(_ result: ReflectionInsightResult) {
        let now = Date()

        for point in result.reflectionPoints {
            insertInsight(
                point,
                kind: "reflection",
                sourceRecords: sourceRecords(for: point),
                now: now
            )
        }

        for point in result.strengthPoints {
            insertInsight(
                point,
                kind: "strength",
                sourceRecords: sourceRecords(for: point),
                now: now
            )
        }
    }

    private func sourceRecords(for point: ReflectionInsightPoint) -> [SentimentRecord] {
        Array(savedReflectionRecords.prefix(max(point.count, 3)))
    }

    private func insertInsight(
        _ point: ReflectionInsightPoint,
        kind: String,
        sourceRecords: [SentimentRecord],
        now: Date
    ) {
        let existing = storedInsights.contains { insight in
            insight.kind == kind &&
            normalizedInsightKey(insight.title) == normalizedInsightKey(point.title)
        }

        guard !existing else { return }

        let insight = ReflectionInsightRecord(
            kind: kind,
            title: point.title,
            insightDescription: point.description,
            count: point.count,
            sourceRecordIDs: sourceRecords.map(\.id),
            createdAt: now,
            updatedAt: now
        )
        modelContext.insert(insight)
    }

    private func normalizedInsightKey(_ text: String) -> String {
        text
            .lowercased()
            .filter { !$0.isWhitespace && !$0.isPunctuation }
    }

    private func formatPercent(_ value: Double) -> String {
        String(format: "%.0f", value)
    }

    private func formatScore(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().day())
    }
}

private struct ScoreTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.bold))
                .minimumScaleFactor(0.72)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(tint)
                .frame(width: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct RatioBar: View {
    let positivePercentage: Double
    let negativePercentage: Double

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let positiveWidth = totalWidth * max(0, min(positivePercentage, 100)) / 100
            let negativeWidth = totalWidth * max(0, min(negativePercentage, 100)) / 100

            HStack(spacing: 0) {
                Rectangle()
                    .fill(.green)
                    .frame(width: positiveWidth)
                Rectangle()
                    .fill(.red)
                    .frame(width: negativeWidth)
                Rectangle()
                    .fill(Color(.systemGray5))
            }
        }
        .frame(height: 12)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel("긍정 \(Int(positivePercentage)) 퍼센트, 부정 \(Int(negativePercentage)) 퍼센트")
    }
}

private struct KeywordList: View {
    let title: String
    let keywords: [SentimentKeyword]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            if keywords.isEmpty {
                Text("감지된 키워드 없음")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(keywords) { keyword in
                    HStack {
                        Text(keyword.text)
                            .font(.callout.weight(.medium))
                        Spacer()
                        Text("\(keyword.count)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(tint)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SavedRecordRow: View {
    let record: SentimentRecord
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(record.createdAt.formatted(.dateTime.year().month().day()))
                    .font(.callout.weight(.semibold))
                Spacer()
                Text("\(String(format: "%.1f", record.satisfactionScore))/5")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.blue)
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("회고 삭제")
            }

            HStack(spacing: 12) {
                Label("\(String(format: "%.0f", record.positivePercentage))%", systemImage: "plus.circle.fill")
                    .foregroundStyle(.green)
                Label("\(String(format: "%.0f", record.negativePercentage))%", systemImage: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .font(.caption.weight(.semibold))

            Text(record.transcript)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SegmentRow: View {
    let segment: SentimentSegment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(segment.label.title)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tint.opacity(0.14), in: Capsule())
                    .foregroundStyle(tint)
                Spacer()
                Text(String(format: "%.2f", segment.score))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text(segment.text)
                .font(.callout)

            if !segment.positiveKeywords.isEmpty || !segment.negativeKeywords.isEmpty {
                Text(keywordSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var keywordSummary: String {
        var parts: [String] = []
        if !segment.positiveKeywords.isEmpty {
            parts.append("긍정: \(segment.positiveKeywords.joined(separator: ", "))")
        }
        if !segment.negativeKeywords.isEmpty {
            parts.append("부정: \(segment.negativeKeywords.joined(separator: ", "))")
        }
        return parts.joined(separator: " · ")
    }

    private var tint: Color {
        switch segment.label {
        case .positive:
            .green
        case .neutral:
            .secondary
        case .negative:
            .red
        }
    }
}

#Preview {
    SentimentAnalysisView()
        .modelContainer(
            for: [SentimentRecord.self, ReflectionInsightRecord.self],
            inMemory: true
        )
}
