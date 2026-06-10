//
//  RetrospectiveListView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/10/26.
//

import SwiftUI

struct RetrospectiveListView: View {
    let items: [RetrospectiveItem]
    let onShowArchive: () -> Void
    let onSelectItem: (RetrospectiveItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                Text("지난주 회고들")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.gray900)

                Spacer()

                Button(action: onShowArchive) {
                    HStack {
                        Text("지난 회고 보기")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.gray300)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color.gray300)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityHint("지난 회고 전체 목록으로 이동")
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, MainPageLayout.headerHorizontalPadding)

            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    RetrospectiveRow(item: item, onTap: { onSelectItem(item) })
                }
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.gray200)
                    .frame(height: 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RetrospectiveRow: View {
    let item: RetrospectiveItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text(item.date)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Color.blue500)
                    .lineLimit(1)
                    .frame(width: 32, height: 32)
                    .background {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue50)
                    }

                Text(item.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.gray900)
                    .lineLimit(1)

                Spacer(minLength: 12)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.gray900)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MainPageLayout.listRowHorizontalPadding)
            .padding(.vertical, MainPageLayout.listRowVerticalPadding)
            .background(Color.white)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.gray200)
                    .frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("회고 상세 화면으로 이동")
    }
}

struct RetrospectiveListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea(.all)

                RetrospectiveListView(
                    items: MainPageContent.mock.retrospectives,
                    onShowArchive: {},
                    onSelectItem: { _ in }
                )
                    .padding(.horizontal, MainPageLayout.screenPadding)
            }
        }
    }
}

struct RetrospectiveDetailView: View {
    @StateObject private var viewModel: RetrospectiveDetailViewModel

    @MainActor
    init(item: RetrospectiveItem, viewModel: RetrospectiveDetailViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? RetrospectiveDetailViewModel(item: item))
    }

    var body: some View {
        Group {
            if let report = viewModel.report {
                RetrospectiveReportView(
                    report: report,
                    displayStyle: .archived(
                        navigationTitle: viewModel.navigationTitle
                    )
                )
            } else {
                ZStack {
                    Color.gray50
                        .ignoresSafeArea(.all)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.item.date)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.blue500)

                        Text(viewModel.item.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.gray900)

                        Text("저장된 회고 상세를 불러올 수 없어요.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.gray600)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(MainPageLayout.screenPadding)
                }
                .navigationTitle("회고 상세")
            }
        }
    }
}

struct RetrospectiveDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RetrospectiveDetailView(
                item: MainPageContent.mock.retrospectives[0],
                viewModel: RetrospectiveDetailViewModel(
                    item: MainPageContent.mock.retrospectives[0]
                )
            )
        }
    }
}

private extension RetrospectiveDetailViewModel {
    var navigationTitle: String {
        item.date.koreanRetrospectiveNavigationTitle
    }
}

private extension String {
    var koreanRetrospectiveNavigationTitle: String {
        let parts = split(separator: "/")
        guard
            parts.count == 2,
            let month = Int(parts[0]),
            let day = Int(parts[1])
        else {
            return "\(self) 회고"
        }

        return "\(month)월 \(day)일 회고"
    }
}
