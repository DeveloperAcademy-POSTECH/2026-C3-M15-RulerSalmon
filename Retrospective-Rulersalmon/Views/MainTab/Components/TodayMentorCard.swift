//
//  TodayMentorCard.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/10/26.
//

import SwiftUI

struct TodayMentorCard: View {
    let content: MainPageContent
    let onStartReflection: () -> Void
    let onEditMentor: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                MentorAvatarTile(imageName: content.mentorImageName)

                VStack(alignment: .leading, spacing: 4) {
                    Text(content.mentorBadgeTitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.blue500)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            Capsule()
                                .fill(Color.blue50)
                        }

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(content.mentorName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color.blue500)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Button(action: onEditMentor) {
                            Image("Edit-Blue")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            }
            .frame(maxWidth: .infinity)

            Text(content.mentorGreeting)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.gray600)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: .infinity)

            MainPrimaryNavigationButton(
                title: "회고 시작",
                systemImageName: "phone.fill",
                action: onStartReflection
            )
        }
        .frame(maxWidth: .infinity)
        .padding(MainPageLayout.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: MainPageLayout.cardCornerRadius)
                .fill(Color.white)
        }
        .shadow(color: Color.gray600.opacity(0.15), radius: 28, x: 0, y: 8)
    }
}

struct MentorAvatarTile: View {
    let imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 96, height: 96)
            .frame(width: 120, height: 120)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.blue50.opacity(0.9)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.gray300.opacity(0.18), radius: 20, x: 0, y: 10)
            }
            .accessibilityHidden(true)
    }
}

struct MainPrimaryNavigationButton: View {
    let title: String
    let systemImageName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImageName)
                    .font(.system(size: 17, weight: .bold))

                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: MainPageLayout.primaryButtonHeight)
            .background {
                Capsule()
                    .fill(Color.blue600)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint("회고 작성 화면으로 이동")
    }
}

struct TodayMentorCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            TodayMentorCard(
                content: .mock,
                onStartReflection: {},
                onEditMentor: {}
            )
            .padding(.horizontal, MainPageLayout.screenPadding)
        }
    }
}
