//
//  RetrospectiveArchiveCard.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/11/26.
//

import SwiftUI

struct RetrospectiveArchiveCard: View {
    let item: RetrospectiveItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(item.date)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.blue500)
                    .lineLimit(1)
                    .frame(width: 48, height: 48)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue50)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.gray900)
                        .lineLimit(1)

                    if let subtitle = item.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color.gray500)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.gray900)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12)
            .padding(.trailing, 20)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.gray200, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("회고 상세 화면으로 이동")
    }
}

struct RetrospectiveArchiveCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            RetrospectiveArchiveCard(
                item: RetrospectiveItem(
                    date: "6/10",
                    title: "자신감 키우기",
                    subtitle: "자아 존중감, 도전, 성공 경험"
                ),
                onTap: {}
            )
            .padding(.horizontal, MainPageLayout.screenPadding)
        }
    }
}
