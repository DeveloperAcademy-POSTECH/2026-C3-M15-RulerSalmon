//
//  ActionItemCard.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/11/26.
//

import SwiftUI

struct ActionItemCard: View {
    let content: ReportActionItemCardContent

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(content.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.gray900)

            if content.rows.isEmpty {
                Text(content.emptyMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.gray600)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 12) {
                    ForEach(content.rows) { row in
                        ActionItemRow(number: row.number, text: row.text)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ReportLayout.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: ReportLayout.cardCornerRadius)
                .fill(Color.gray50)
        }
        .overlay {
            RoundedRectangle(cornerRadius: ReportLayout.cardCornerRadius)
                .stroke(Color.gray200, lineWidth: ReportLayout.borderWidth)
        }
    }
}

private struct ActionItemRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number)")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.blue500)
                .frame(width: 20, height: 20)
                .background {
                    Circle()
                        .fill(Color.blue50)
                }

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.gray600)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ActionItemCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ActionItemCard(
                content: ReportActionItemCardContent(
                    title: "내일의 Action Item",
                    rows: RetrospectiveReport.mock.actionItems.enumerated().map {
                        ReportActionItemRowContent(
                            id: $0.offset,
                            number: $0.offset + 1,
                            text: $0.element
                        )
                    },
                    emptyMessage: "추천할 Action Item이 없어요."
                )
            )
            .padding(.horizontal, ReportLayout.screenPadding)
        }
    }
}
