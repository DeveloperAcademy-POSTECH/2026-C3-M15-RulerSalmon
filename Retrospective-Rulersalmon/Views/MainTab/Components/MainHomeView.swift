//
//  MainHomeView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/10/26.
//

import SwiftUI

struct MainHomeView: View {
    let content: MainPageContent
    let onStartReflection: () -> Void
    let onEditUserInfo: () -> Void
    let onEditMentor: () -> Void
    let onShowRetrospectiveArchive: () -> Void
    let onSelectRetrospective: (RetrospectiveItem) -> Void

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 28) {
                    MainHeaderView(
                        userName: content.userName,
                        encouragementMessage: content.encouragementMessage,
                        onEdit: onEditUserInfo
                    )
                    TodayMentorCard(
                        content: content,
                        onStartReflection: onStartReflection,
                        onEditMentor: onEditMentor
                    )
                    RetrospectiveListView(
                        items: content.retrospectives,
                        onShowArchive: onShowRetrospectiveArchive,
                        onSelectItem: onSelectRetrospective
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, MainPageLayout.screenPadding)
                .padding(.top, 32)
                .padding(.bottom, 32)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct MainHomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainHomeView(
                content: .mock,
                onStartReflection: {},
                onEditUserInfo: {},
                onEditMentor: {},
                onShowRetrospectiveArchive: {},
                onSelectRetrospective: { _ in }
            )
        }
    }
}
