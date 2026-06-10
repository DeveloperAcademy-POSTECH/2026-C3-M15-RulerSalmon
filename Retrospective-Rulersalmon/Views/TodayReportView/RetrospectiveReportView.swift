//
//  RetrospectiveReportView.swift
//  Retrospective-Rulersalmon
//
//  Created by Steve on 6/8/26.
//

import SwiftUI

struct RetrospectiveReportView: View {
    @StateObject private var viewModel: RetrospectiveReportViewModel
    private let onClose: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    init(
        report: RetrospectiveReport = .mock,
        displayStyle: RetrospectiveReportDisplayStyle = .today,
        onClose: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: RetrospectiveReportViewModel(
                report: report,
                displayStyle: displayStyle
            )
        )
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            VStack(spacing: 0) {
                ReportNavigationBar(title: viewModel.navigationTitle) {
                    if let onClose {
                        onClose()
                    } else {
                        dismiss()
                    }
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        SummaryCard(
                            title: viewModel.summaryTitle,
                            summary: viewModel.summary,
                            transcript: viewModel.transcript,
                            transcriptLinkTitle: viewModel.transcriptLinkTitle
                        )
                        FourLCard(title: viewModel.fourLTitle, entries: viewModel.fourLEntries)
                        KeywordSection(title: viewModel.keywordTitle, keywords: viewModel.keywords)
                        ActionItemCard(
                            title: viewModel.actionItemTitle,
                            items: viewModel.actionItems,
                            emptyMessage: viewModel.emptyActionItemMessage
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, ReportLayout.screenPadding)
                    .padding(.top, 18)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private enum ReportLayout {
    static let screenPadding: CGFloat = AppLayout.screenHorizontalPadding
    static let cardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 20
    static let summaryCornerRadius: CGFloat = 24
    static let borderWidth: CGFloat = 1
}

private struct ReportNavigationBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.gray900)
                    .frame(width: 40, height: 40)
                    .background {
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.gray300.opacity(0.35), radius: 12, x: 0, y: 6)
                    }
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, ReportLayout.screenPadding)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

private struct SummaryCard: View {
    let title: String
    let summary: String
    let transcript: String
    let transcriptLinkTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(Color.blue500)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 12)

                NavigationLink {
                    TranscriptPlaceholderView(transcript: transcript)
                } label: {
                    Text(transcriptLinkTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.blue500)
                }
                .buttonStyle(.plain)
            }

            Text(summary)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.blue500)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background {
            RoundedRectangle(cornerRadius: ReportLayout.summaryCornerRadius)
                .fill(Color.blue50)
        }
    }
}

private struct FourLCard: View {
    let title: String
    let entries: [FourLEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)

            Divider()
                .background(Color.gray200)

            VStack(spacing: 16) {
                ForEach(entries) { entry in
                    FourLEntryRow(entry: entry)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ReportLayout.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: ReportLayout.cardCornerRadius)
                .fill(Color.white)
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
        HStack(alignment: .top, spacing: 12) {
            Text(entry.icon)
                .font(.system(size: 18))
                .frame(width: 38, height: 38)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(entry.tintColor)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.gray600)

                Text(entry.content)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.gray600)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct KeywordSection: View {
    let title: String
    let keywords: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)

            FlowLayout(spacing: 10, rowSpacing: 10) {
                ForEach(keywords, id: \.self) { keyword in
                    Text("#\(keyword)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.blue500)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background {
                            Capsule()
                                .fill(Color.blue50)
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ReportLayout.cardPadding)
    }
}

private struct ActionItemCard: View {
    let title: String
    let items: [String]
    let emptyMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)

            if items.isEmpty {
                Text(emptyMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.gray600)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        ActionItemRow(number: index + 1, text: item)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ReportLayout.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: ReportLayout.cardCornerRadius)
                .fill(Color.white)
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
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.blue500)
                .frame(width: 22, height: 22)
                .background {
                    Circle()
                        .fill(Color.blue50)
                }

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.gray600)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TranscriptPlaceholderView: View {
    let transcript: String

    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            ScrollView {
                Text(transcript)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.gray900)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(ReportLayout.screenPadding)
            }
        }
        .navigationTitle("전사문")
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
        let rows = rows(proposal: proposal, subviews: subviews)
        return CGSize(
            width: proposal.width ?? rows.map(\.width).max() ?? 0,
            height: rows.reduce(0) { $0 + $1.height } + CGFloat(max(rows.count - 1, 0)) * rowSpacing
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var y = bounds.minY

        for row in rows(proposal: ProposedViewSize(width: bounds.width, height: proposal.height), subviews: subviews) {
            var x = bounds.minX

            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }

            y += row.height + rowSpacing
        }
    }

    private func rows(proposal: ProposedViewSize, subviews: Subviews) -> [FlowRow] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [FlowRow] = []
        var currentItems: [FlowItem] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let nextWidth = currentItems.isEmpty ? size.width : currentWidth + spacing + size.width

            if nextWidth > maxWidth, !currentItems.isEmpty {
                rows.append(FlowRow(items: currentItems, width: currentWidth, height: currentHeight))
                currentItems = [FlowItem(subview: subview, size: size)]
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentItems.append(FlowItem(subview: subview, size: size))
                currentWidth = nextWidth
                currentHeight = max(currentHeight, size.height)
            }
        }

        if !currentItems.isEmpty {
            rows.append(FlowRow(items: currentItems, width: currentWidth, height: currentHeight))
        }

        return rows
    }
}

private struct FlowRow {
    let items: [FlowItem]
    let width: CGFloat
    let height: CGFloat
}

private struct FlowItem {
    let subview: LayoutSubviews.Element
    let size: CGSize
}

struct RetrospectiveReportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RetrospectiveReportView()
        }
    }
}
