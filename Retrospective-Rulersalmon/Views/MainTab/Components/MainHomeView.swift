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

    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 36) {
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
                    RetrospectiveListView(items: content.retrospectives)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, MainPageLayout.screenPadding)
                .padding(.top, 48)
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
                onEditMentor: {}
            )
        }
    }
}
