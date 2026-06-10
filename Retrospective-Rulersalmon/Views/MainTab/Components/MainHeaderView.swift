//
//  MainHeaderView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/10/26.
//

import SwiftUI

struct MainHeaderView: View {
    let userName: String
    let encouragementMessage: String
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("안녕하세요, \(userName) 님")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.gray900)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Button(action: onEdit) {
                    Image("Edit-Gray")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(encouragementMessage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.gray600)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, MainPageLayout.headerHorizontalPadding)
    }
}

struct MainHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            MainHeaderView(
                userName: "김여운",
                encouragementMessage: "오늘은 어떤 일이 있으셨는지 편하게 얘기해주세요.",
                onEdit: {}
            )
            .padding(.horizontal, MainPageLayout.screenPadding)
        }
    }
}
