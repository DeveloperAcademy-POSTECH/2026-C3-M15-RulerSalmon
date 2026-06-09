//
//  PermmisionView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/2/26.
//

import SwiftUI

struct PermissionView: View {
    let onNext: () -> Void

    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            VStack {
                OnboardingTitle(
                    headline: "권한을 허용해 주세요",
                    subtitle: "회의 일정과 음성 기록을\n더 빠르게 정리하기 위해 사용해요."
                )
                .padding(.bottom, 24)

                PermissionRow(
                    permissionTitle: "Apple Intelligence",
                    permissionDescription: "회고를 다시 이어가야 할 때 잊지 않게 도와줘.",
                    systemImageName: "apple.intelligence"
                )

                Spacer()

                AcceptButton(labelText: "권한 허용하기"){
                    onNext()
//                    if let url = URL(string: UIApplication.openSettingsURLString) {
//                            UIApplication.shared.open(url)
//                        }
                }
            }
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PermissionView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionView(onNext: {})
    }
}
