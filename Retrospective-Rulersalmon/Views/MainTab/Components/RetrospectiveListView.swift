//
//  RetrospectiveListView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/10/26.
//

import SwiftUI

struct RetrospectiveListView: View {
    let items: [RetrospectiveItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("지난주 회고들")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.gray900)

                Spacer()

                NavigationLink {
                    RetrospectiveArchiveView(items: items)
                } label: {
                    Text("지난 회고 보기 >")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.gray300)
                }
                .buttonStyle(.plain)
                .accessibilityHint("지난 회고 전체 목록으로 이동")
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, MainPageLayout.headerHorizontalPadding)

            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    RetrospectiveRow(item: item)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RetrospectiveRow: View {
    let item: RetrospectiveItem

    var body: some View {
        NavigationLink {
            RetrospectiveDetailPlaceholderView(item: item)
        } label: {
            HStack(spacing: 18) {
                Text(item.date)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.blue500)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 30, height: 30)
                    .background {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.blue50)
                    }

                Text(item.title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.gray900)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)

                Spacer(minLength: 12)

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.gray900)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MainPageLayout.listRowHorizontalPadding)
            .padding(.vertical, MainPageLayout.listRowVerticalPadding)
            .background(Color.white)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("회고 상세 화면으로 이동")
    }
}

struct RetrospectiveArchiveView: View {
    let items: [RetrospectiveItem]

    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        RetrospectiveRow(item: item)
                    }
                }
                .padding(.horizontal, MainPageLayout.screenPadding)
                .padding(.top, 16)
            }
        }
        .navigationTitle("지난 회고")
    }
}

struct RetrospectiveDetailPlaceholderView: View {
    let item: RetrospectiveItem

    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            VStack(alignment: .leading, spacing: 12) {
                Text(item.date)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.blue500)

                Text(item.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.gray900)

                Text("회고 상세 화면 연결을 확인하기 위한 테스트용 화면입니다.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.gray600)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MainPageLayout.screenPadding)
        }
        .navigationTitle("회고 상세")
    }
}

struct RetrospectiveListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ZStack {
                Color.gray50
                    .ignoresSafeArea(.all)

                RetrospectiveListView(items: MainPageContent.mock.retrospectives)
                    .padding(.horizontal, MainPageLayout.screenPadding)
            }
        }
    }
}
