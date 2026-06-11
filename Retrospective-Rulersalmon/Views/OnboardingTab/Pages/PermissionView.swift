//
//  PermmisionView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/2/26.
//

import SwiftUI

struct PermissionView: View {
    let isPermissionGranted: () -> Bool
    let onNext: () -> Void

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)

            VStack {
                OnboardingTitle(
                    headline: "권한을 허용해 주세요",
                    subtitle: "Apple Intelligence를 통해\n질문을 생성하기 위해 사용해요."
                )
                .padding(.bottom, 20)

                PermissionRow(
                    permissionTitle: "Apple Intelligence",
                    permissionDescription: "회고를 위한 질문을 생성해요.",
                    systemImageName: "apple.intelligence"
                )

                Spacer()

                AcceptButton(labelText: "권한 허용하기"){
                    handlePermissionAction()
                }
            }
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            _ = isPermissionGranted()
        }
    }

    private func handlePermissionAction() {
        if isPermissionGranted() {
            onNext()
            return
        }

        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(url)
    }
}

struct PermissionView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionView(isPermissionGranted: { false }, onNext: {})
    }
}
