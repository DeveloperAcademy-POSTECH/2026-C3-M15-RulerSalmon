//
//  FourLCard.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/11/26.
//

import SwiftUI

struct FourLCard: View {
    let content: ReportFourLCardContent

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(content.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.gray900)

            Divider()
                .background(Color.gray200)

            VStack(spacing: 20) {
                ForEach(content.entries) { entry in
                    FourLEntryRow(entry: entry)
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

private struct FourLEntryRow: View {
    let entry: FourLEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(entry.icon)
                .font(.system(size: 16))
                .frame(width: 40, height: 40)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(entry.tintColor)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.gray600)

                Text(entry.content)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.gray600)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FourLCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            FourLCard(
                content: ReportFourLCardContent(
                    title: "오늘의 4L 회고",
                    entries: RetrospectiveReport.mock.fourLEntries
                )
            )
            .padding(.horizontal, ReportLayout.screenPadding)
        }
    }
}
