//
//  PermmisionView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/2/26.
//

import SwiftUI

struct PermmisionView: View {
    let onNext: () -> Void

    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            VStack {
                OnboardingTitle(
                    headline: "회고를 이어가기 위한 준비를 마칠게",
                    subtitle: "텍스트 기반 회고를 더 자연스럽게 이어갈 수 있도록\n기본 설정만 확인하고 시작하자."
                )
                .padding(.bottom, 24)

                PermissionRow(
                    permissionTitle: "알림",
                    permissionDescription: "회고를 다시 이어가야 할 때 잊지 않게 도와줘.",
                    systemImageName: "bell.fill"
                )

                PermissionRow(
                    permissionTitle: "캘린더",
                    permissionDescription: "되돌아보고 싶은 일정이나 작업 맥락을 함께 확인할 수 있어.",
                    systemImageName: "calendar"
                )

                Spacer()

                AcceptButton(labelText: "시작하기", action: onNext)
            }
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PermmisionView_Previews: PreviewProvider {
    static var previews: some View {
        PermmisionView(onNext: {})
    }
}
