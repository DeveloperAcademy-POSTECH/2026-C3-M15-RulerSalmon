//
//  SummaryCard.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/11/26.
//

import SwiftUI

struct SummaryCard: View {
    let content: ReportSummaryCardContent
    let transcriptNavigationTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(content.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.blue500)
                    .lineLimit(1)

                Spacer(minLength: 12)

                NavigationLink {
                    RetrospectiveTranscriptView(
                        title: transcriptNavigationTitle,
                        transcript: content.transcript
                    )
                } label: {
                    HStack(spacing: 4) {
                        Text(content.transcriptLinkTitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.blue500)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(Color.blue500)
                    }
                }
                .buttonStyle(.plain)
            }

            Text(content.summary)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.blue500)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .background {
            RoundedRectangle(cornerRadius: ReportLayout.summaryCornerRadius)
                .fill(Color.blue50)
        }
    }
}

struct SummaryCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            SummaryCard(
                content: ReportSummaryCardContent(
                    title: "오늘 회고 요약",
                    summary: RetrospectiveReport.mock.summary,
                    transcript: RetrospectiveReport.mock.transcript,
                    transcriptLinkTitle: "전사문 보기"
                ),
                transcriptNavigationTitle: "전사문"
            )
            .padding(.horizontal, ReportLayout.screenPadding)
        }
    }
}
