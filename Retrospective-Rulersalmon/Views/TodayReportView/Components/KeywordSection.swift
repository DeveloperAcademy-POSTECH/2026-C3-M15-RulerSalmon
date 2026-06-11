//
//  KeywordSection.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/11/26.
//

import SwiftUI

struct KeywordSection: View {
    let content: ReportKeywordSectionContent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(content.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.gray900)

            if content.keywords.isEmpty {
                Text(content.emptyMessage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.gray500)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                FlowLayout(spacing: 8, rowSpacing: 8) {
                    ForEach(content.keywords, id: \.self) { keyword in
                        Text("#\(keyword)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.blue500)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(Color.blue50)
                            }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(.horizontal, ReportLayout.cardPadding)
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat
    let rowSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let layout = layoutInfo(
            maxWidth: proposal.width ?? .infinity,
            subviews: subviews
        )

        return CGSize(
            width: proposal.width ?? layout.contentWidth,
            height: layout.totalHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let layout = layoutInfo(
            maxWidth: bounds.width,
            subviews: subviews
        )

        for item in layout.items {
            item.subview.place(
                at: CGPoint(x: bounds.minX + item.origin.x, y: bounds.minY + item.origin.y),
                anchor: .topLeading,
                proposal: ProposedViewSize(item.size)
            )
        }
    }

    private func layoutInfo(
        maxWidth: CGFloat,
        subviews: Subviews
    ) -> (items: [(subview: LayoutSubviews.Element, origin: CGPoint, size: CGSize)], contentWidth: CGFloat, totalHeight: CGFloat) {
        var items: [(subview: LayoutSubviews.Element, origin: CGPoint, size: CGSize)] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var contentWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let proposedWidth = currentX == 0 ? size.width : currentX + spacing + size.width

            if proposedWidth > maxWidth, currentX > 0 {
                contentWidth = max(contentWidth, currentX)
                currentX = 0
                currentY += currentRowHeight + rowSpacing
                currentRowHeight = 0
            }

            let originX = currentX == 0 ? 0 : currentX + spacing
            items.append((subview: subview, origin: CGPoint(x: originX, y: currentY), size: size))
            currentX = originX + size.width
            currentRowHeight = max(currentRowHeight, size.height)
        }

        contentWidth = max(contentWidth, currentX)
        let totalHeight = items.isEmpty ? 0 : currentY + currentRowHeight

        return (items: items, contentWidth: contentWidth, totalHeight: totalHeight)
    }
}

struct KeywordSection_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            KeywordSection(
                content: ReportKeywordSectionContent(
                    title: "핵심 키워드",
                    keywords: RetrospectiveReport.mock.keywords,
                    emptyMessage: "핵심키워드가 도출되지 않았어요."
                )
            )
            .padding(.horizontal, ReportLayout.screenPadding)
        }
    }
}
